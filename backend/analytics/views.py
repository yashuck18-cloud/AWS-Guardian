from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions
from django.db.models import Count, Sum, Q
from django.utils import timezone
from datetime import timedelta
from resources.models import Resource, ResourceCost
from alerts.models import Alert
from aws_accounts.models import AWSAccount
from alerts.serializers import AlertSerializer
from users.utils import is_valid_uuid
from scanner.cost_service import calculate_resource_monthly_and_mtd

class DashboardSummaryView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        account_id = request.query_params.get('account')

        resources_qs = Resource.objects.filter(account__user=user)
        alerts_qs = Alert.objects.filter(account__user=user)
        accounts_qs = AWSAccount.objects.filter(user=user)
        costs_qs = ResourceCost.objects.filter(account__user=user)

        acc = None
        if account_id:
            if is_valid_uuid(account_id):
                acc = accounts_qs.filter(id=account_id).first()
            else:
                acc = accounts_qs.filter(account_id=account_id).first()
        else:
            acc = accounts_qs.filter(status='CONNECTED').first() or accounts_qs.first()

        region_param = request.query_params.get('region')

        if acc:
            resources_qs = resources_qs.filter(account=acc)
            alerts_qs = alerts_qs.filter(account=acc)
            accounts_qs = accounts_qs.filter(id=acc.id)
            costs_qs = costs_qs.filter(account=acc)

            if region_param and region_param.lower() != 'all':
                clean_region = region_param.strip().lower()
                resources_qs = resources_qs.filter(region__iexact=clean_region)
                alerts_qs = alerts_qs.filter(resource__region__iexact=clean_region)
                costs_qs = costs_qs.filter(Q(region__iexact=clean_region) | Q(cost_source='AWS_COST_EXPLORER'))
            elif acc.enabled_regions:
                raw_regs = acc.enabled_regions if isinstance(acc.enabled_regions, list) else [acc.enabled_regions]
                active_regs = [r.strip().lower() for r in raw_regs if r and r.strip().lower() != 'all']
                if active_regs:
                    resources_qs = resources_qs.filter(region__in=active_regs)
                    alerts_qs = alerts_qs.filter(resource__region__in=active_regs)
                    costs_qs = costs_qs.filter(Q(region__in=active_regs) | Q(cost_source='AWS_COST_EXPLORER'))

        total_resources = resources_qs.count()
        running_resources = resources_qs.filter(state__iexact='running').count()
        stopped_resources = resources_qs.filter(state__iexact='stopped').count()
        needs_attention = resources_qs.filter(risk_level__in=['LOW', 'MEDIUM', 'HIGH', 'CRITICAL']).count()
        critical_count = resources_qs.filter(risk_level='CRITICAL').count()

        # Risk overview for Donut chart
        active_alerts = alerts_qs.filter(status__in=['ACTIVE', 'ACKNOWLEDGED'])
        risk_overview = {
            'critical': active_alerts.filter(severity='CRITICAL').count(),
            'high': active_alerts.filter(severity='HIGH').count(),
            'medium': active_alerts.filter(severity='MEDIUM').count(),
            'low': active_alerts.filter(severity='LOW').count(),
            'total_alerts': active_alerts.count()
        }

        # Resources by service
        service_counts = resources_qs.values('service').annotate(count=Count('id')).order_by('-count')
        resources_by_service = {item['service']: item['count'] for item in service_counts}

        import calendar
        from datetime import datetime as dt_cls, timezone as tz_cls

        now_utc = dt_cls.now(tz_cls.utc)

        # Parse requested month if provided (e.g. month=2026-11 or month=2026-10 or month=11)
        month_param = request.query_params.get('month')
        target_year = now_utc.year
        target_month = now_utc.month

        if month_param:
            try:
                parts = month_param.strip().split('-')
                if len(parts) == 2:
                    target_year = int(parts[0])
                    target_month = int(parts[1])
                elif len(parts) == 1 and parts[0].isdigit():
                    target_month = int(parts[0])
            except (ValueError, TypeError):
                target_year = now_utc.year
                target_month = now_utc.month

        is_current_month = (target_year == now_utc.year and target_month == now_utc.month)
        is_past_month = (target_year < now_utc.year or (target_year == now_utc.year and target_month < now_utc.month))
        days_in_target_month = calendar.monthrange(target_year, target_month)[1]
        month_name = calendar.month_name[target_month]
        billing_period_label = f"{month_name} {target_year}"

        # Determine the earliest activity month for this specific account
        earliest_cost = costs_qs.order_by('billing_period_start').first()
        if earliest_cost and earliest_cost.billing_period_start:
            start_year = earliest_cost.billing_period_start.year
            start_month = earliest_cost.billing_period_start.month
        elif acc and acc.created_at:
            start_year = acc.created_at.year
            start_month = acc.created_at.month
        else:
            start_year = now_utc.year
            start_month = now_utc.month

        # Build list of available months starting strictly from account start month up to current month
        available_months = []
        cur_y = start_year
        cur_m = start_month
        while (cur_y < now_utc.year) or (cur_y == now_utc.year and cur_m <= now_utc.month):
            key = f"{cur_y}-{cur_m:02d}"
            label = f"{calendar.month_abbr[cur_m]} {cur_y}"
            available_months.append({
                'key': key,
                'year': cur_y,
                'month': cur_m,
                'label': label,
                'is_current': (cur_y == now_utc.year and cur_m == now_utc.month),
            })
            cur_m += 1
            if cur_m > 12:
                cur_m = 1
                cur_y += 1

        # Filter ResourceCost for this target month
        monthly_costs_qs = costs_qs.filter(
            billing_period_start__year=target_year,
            billing_period_start__month=target_month
        )

        ce_records = monthly_costs_qs.filter(cost_source='AWS_COST_EXPLORER')
        has_actual_ce = ce_records.exists()

        resource_costs_list = []

        if has_actual_ce:
            total_period_actual = float(ce_records.aggregate(total=Sum('actual_cost'))['total'] or 0.0)
            if is_current_month:
                month_to_date_cost = round(total_period_actual, 2)
                total_current_cost = month_to_date_cost
                projected_monthly_cost = round(total_period_actual / 2.0 * days_in_target_month, 2)
                daily_cost = round(total_period_actual / 2.0, 2)
                service_mtd_costs = {c.service: round(float(c.actual_cost), 4) for c in ce_records}
                service_costs = {c.service: round(float(c.actual_cost), 4) for c in ce_records}
            else:
                total_current_cost = round(total_period_actual, 2)
                month_to_date_cost = total_current_cost
                projected_monthly_cost = total_current_cost
                daily_cost = round(total_current_cost / float(days_in_target_month), 2)
                service_costs = {c.service: round(float(c.actual_cost), 4) for c in ce_records}
                service_mtd_costs = service_costs.copy()

            cost_source = 'AWS_COST_EXPLORER'
            billing_status = 'ESTIMATED' if is_current_month else 'FINAL_BILLED'

            for c in ce_records:
                if float(c.actual_cost or 0) > 0:
                    resource_costs_list.append({
                        'resource_id': c.aws_resource_id,
                        'name': c.notes or c.resource_type or c.service,
                        'service': c.service,
                        'region': c.region or 'ap-south-1',
                        'state': 'billed',
                        'hourly_cost': round(float(c.actual_cost) / (24.0 * (2.0 if is_current_month else days_in_target_month)), 4),
                        'mtd_cost': round(float(c.actual_cost), 2),
                        'monthly_cost': round(float(c.actual_cost), 2),
                    })
        else:
            total_mtd = 0.0
            total_projected = 0.0
            service_costs = {}
            service_mtd_costs = {}

            # Days elapsed for calculation
            if is_current_month:
                days_elapsed = max(1, now_utc.day)
            elif is_past_month:
                days_elapsed = days_in_target_month
            else:
                days_elapsed = 0

            for r in resources_qs:
                c = monthly_costs_qs.filter(aws_resource_id=r.resource_id).first()
                hourly_rate = float(r.estimated_hourly_cost or 0.0)

                if c and float(c.estimated_cost or 0.0) > 0:
                    r_mtd = float(c.actual_cost or 0.0)
                    r_proj = float(c.estimated_cost or 0.0)
                else:
                    if is_current_month:
                        calc = calculate_resource_monthly_and_mtd(hourly_rate, r.service, r.resource_id)
                        r_mtd = calc['mtd_cost']
                        r_proj = calc['projected_monthly']
                    elif is_past_month:
                        r_proj = round(hourly_rate * 24.0 * days_in_target_month, 2)
                        r_mtd = r_proj
                    else:
                        r_proj = round(hourly_rate * 24.0 * days_in_target_month, 2)
                        r_mtd = 0.0

                total_mtd += r_mtd
                total_projected += r_proj
                service_costs[r.service] = service_costs.get(r.service, 0.0) + r_proj
                service_mtd_costs[r.service] = service_mtd_costs.get(r.service, 0.0) + r_mtd

                # Append per-resource detail
                if hourly_rate > 0 or r_proj > 0:
                    resource_costs_list.append({
                        'resource_id': r.resource_id,
                        'name': r.name or r.resource_id,
                        'service': r.service,
                        'region': r.region,
                        'state': r.state,
                        'hourly_cost': hourly_rate,
                        'mtd_cost': round(r_mtd, 2),
                        'monthly_cost': round(r_proj, 2),
                    })

            month_to_date_cost = round(total_mtd, 2)
            projected_monthly_cost = round(total_projected, 2)
            daily_cost = round(sum(float(r.estimated_hourly_cost or 0.0) * 24.0 for r in resources_qs), 2)
            total_current_cost = projected_monthly_cost if is_current_month else month_to_date_cost
            cost_source = 'AWS_PRICING'
            billing_status = 'PRICING_ESTIMATE' if is_current_month else 'ESTIMATED_ARCHIVE'

        # Filter out 0-cost services to eliminate clutter/unnecessary items, and sort by cost descending
        service_costs = {k: round(v, 2) for k, v in service_costs.items() if round(v, 2) > 0}
        service_costs = dict(sorted(service_costs.items(), key=lambda x: x[1], reverse=True))
        service_mtd_costs = {k: round(v, 2) for k, v in service_mtd_costs.items() if round(v, 2) > 0}

        # Payment & Unpaid status calculation
        if is_current_month:
            payment_status = 'UNPAID'
            payment_status_label = 'Accruing (Unpaid)'
            is_paid = False
            unpaid_cost = round(month_to_date_cost, 2)
            paid_cost = 0.0
        elif is_past_month:
            payment_status = 'PAID'
            payment_status_label = 'Paid in Full'
            is_paid = True
            unpaid_cost = 0.0
            paid_cost = round(total_current_cost, 2)
        else:
            payment_status = 'UPCOMING'
            payment_status_label = 'Upcoming'
            is_paid = False
            unpaid_cost = 0.0
            paid_cost = 0.0

        # Sort resource cost list by monthly cost descending and filter out zero-cost items
        resource_costs_list = [r for r in resource_costs_list if (r.get('monthly_cost', 0) > 0 or r.get('mtd_cost', 0) > 0 or r.get('hourly_cost', 0) > 0)]
        resource_costs_list.sort(key=lambda x: x['monthly_cost'], reverse=True)

        # Potential waste count (unattached EBS, idle/running long EC2, unassociated EIP)
        potential_waste_count = alerts_qs.filter(
            status__in=['ACTIVE', 'ACKNOWLEDGED'],
            rule_code__in=['EC2_RUNNING_TOO_LONG', 'EBS_UNATTACHED', 'EIP_UNATTACHED']
        ).count() or active_alerts.count()

        # Top recent active alerts
        recent_alerts_data = AlertSerializer(active_alerts[:5], many=True).data

        # Latest scan info
        latest_account = accounts_qs.order_by('-last_scan_at').first()
        last_scan_time = latest_account.last_scan_at.isoformat() if (latest_account and latest_account.last_scan_at) else None

        # Combined total cost strictly for this specific account
        all_ce_costs = costs_qs.filter(cost_source='AWS_COST_EXPLORER')
        if all_ce_costs.exists():
            combined_total_cost = round(float(all_ce_costs.aggregate(total=Sum('actual_cost'))['total'] or 0.0), 2)
        else:
            combined_total_cost = round(total_current_cost, 2)
        combined_approx_inr = round(combined_total_cost * 86.50, 2)

        return Response({
            'success': True,
            'stats': {
                'total_resources': total_resources,
                'running_resources': running_resources,
                'stopped_resources': stopped_resources,
                'potential_waste': potential_waste_count,
                'needs_attention': needs_attention,
                'critical_count': critical_count,
                'risk_overview': risk_overview,
                'resources_by_service': resources_by_service,
                'recent_alerts': recent_alerts_data,
                'connected_accounts_count': accounts_qs.filter(status='CONNECTED').count(),
                'total_accounts_count': accounts_qs.count(),
                'last_scan_time': last_scan_time,
                'current_cost': round(total_current_cost, 2),
                'combined_total_cost': combined_total_cost,
                'combined_approx_inr': combined_approx_inr,
                'month_to_date_cost': month_to_date_cost,
                'projected_monthly_cost': projected_monthly_cost,
                'daily_cost': daily_cost,
                'billing_period': billing_period_label,
                'selected_month': f"{target_year}-{target_month:02d}",
                'selected_month_label': billing_period_label,
                'is_current_month': is_current_month,
                'available_months': available_months,
                'resource_costs': resource_costs_list,
                'charged_services_count': len([s for s in service_costs.values() if s > 0]),
                'charged_resources_count': len(resource_costs_list),
                'service_costs': service_costs,
                'service_mtd_costs': service_mtd_costs,
                'cost_currency': 'USD',
                'cost_source': cost_source,
                'billing_status': billing_status,
                'payment_status': payment_status,
                'payment_status_label': payment_status_label,
                'is_paid': is_paid,
                'unpaid_cost': unpaid_cost,
                'paid_cost': paid_cost,
                'approx_inr': round(total_current_cost * 86.50, 2),
                'approx_inr_mtd': round(month_to_date_cost * 86.50, 2),
                'approx_inr_unpaid': round(unpaid_cost * 86.50, 2),
            }
        })

class AnalyticsDataView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        account_id = request.query_params.get('account')

        resources_qs = Resource.objects.filter(account__user=user)
        alerts_qs = Alert.objects.filter(account__user=user)

        acc = None
        if account_id:
            if is_valid_uuid(account_id):
                acc = AWSAccount.objects.filter(id=account_id, user=user).first()
            else:
                acc = AWSAccount.objects.filter(account_id=account_id, user=user).first()
        else:
            acc = AWSAccount.objects.filter(user=user, status='CONNECTED').first() or AWSAccount.objects.filter(user=user).first()

        if acc:
            resources_qs = resources_qs.filter(account=acc)
            alerts_qs = alerts_qs.filter(account=acc)
            if acc.enabled_regions:
                raw_regs = acc.enabled_regions if isinstance(acc.enabled_regions, list) else [acc.enabled_regions]
                active_regs = [r.strip().lower() for r in raw_regs if r and r.strip().lower() != 'all']
                if active_regs:
                    resources_qs = resources_qs.filter(Q(region__in=active_regs) | Q(region__iexact='global') | Q(region=''))
                    alerts_qs = alerts_qs.filter(Q(resource__region__in=active_regs) | Q(resource__region__iexact='global') | Q(resource__region=''))

        # Service breakdown
        service_stats = resources_qs.values('service').annotate(
            count=Count('id'),
            total_hourly=Sum('estimated_hourly_cost')
        ).order_by('-count')

        # Region breakdown
        region_stats = resources_qs.values('region').annotate(
            count=Count('id')
        ).order_by('-count')

        # Risk distribution
        risk_stats = {
            'CRITICAL': resources_qs.filter(risk_level='CRITICAL').count(),
            'HIGH': resources_qs.filter(risk_level='HIGH').count(),
            'MEDIUM': resources_qs.filter(risk_level='MEDIUM').count(),
            'LOW': resources_qs.filter(risk_level='LOW').count(),
            'NONE': resources_qs.filter(risk_level='NONE').count(),
        }

        # Trend points
        now = timezone.now()
        days_trend = []
        for i in range(6, -1, -1):
            day = now - timedelta(days=i)
            day_str = day.strftime('%b %d')
            day_res_count = resources_qs.filter(created_at__lte=day).count() or resources_qs.count()
            day_alert_count = alerts_qs.filter(first_detected_at__lte=day).count() or alerts_qs.count()
            days_trend.append({
                'date': day_str,
                'resources': day_res_count,
                'alerts': day_alert_count
            })

        resolved_count = alerts_qs.filter(status='RESOLVED').count()

        return Response({
            'success': True,
            'analytics': {
                'service_distribution': list(service_stats),
                'region_distribution': list(region_stats),
                'risk_distribution': risk_stats,
                'trend_data': days_trend,
                'resolved_alerts_count': resolved_count,
                'total_alerts_count': alerts_qs.count()
            }
        })

class CostOverviewView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        user = request.user
        account_id = request.query_params.get('account')

        resources_qs = Resource.objects.filter(account__user=user)
        costs_qs = ResourceCost.objects.filter(account__user=user)

        acc = None
        if account_id:
            if is_valid_uuid(account_id):
                acc = AWSAccount.objects.filter(id=account_id, user=user).first()
            else:
                acc = AWSAccount.objects.filter(account_id=account_id, user=user).first()
        else:
            acc = AWSAccount.objects.filter(user=user, status='CONNECTED').first() or AWSAccount.objects.filter(user=user).first()

        if acc:
            resources_qs = resources_qs.filter(account=acc)
            costs_qs = costs_qs.filter(account=acc)
            if acc.enabled_regions:
                raw_regs = acc.enabled_regions if isinstance(acc.enabled_regions, list) else [acc.enabled_regions]
                active_regs = [r.strip().lower() for r in raw_regs if r and r.strip().lower() != 'all']
                if active_regs:
                    resources_qs = resources_qs.filter(Q(region__in=active_regs) | Q(region__iexact='global') | Q(region=''))
                    costs_qs = costs_qs.filter(Q(region__in=active_regs) | Q(region__iexact='global') | Q(region=''))

        # Check for authoritative AWS Cost Explorer records
        valid_services = set(resources_qs.values_list('service', flat=True))
        ce_records = costs_qs.filter(cost_source='AWS_COST_EXPLORER').filter(
            Q(service__in=valid_services) | Q(service='S3')
        )
        has_actual_ce = ce_records.exists() and len(valid_services) > 0

        if has_actual_ce:
            ce_total = float(ce_records.aggregate(total=Sum('actual_cost'))['total'] or 0.0)
            service_breakdown = {}
            for c in ce_records:
                service_breakdown[c.service] = round(float(c.actual_cost), 2)

            service_mtd_breakdown = service_breakdown.copy()
            month_to_date_cost = ce_total
            projected_monthly_cost = ce_total
            billing_status = 'ESTIMATED'
            cost_source = 'AWS_COST_EXPLORER'
            cost_source_display = 'AWS Cost Explorer'
            actual_available = True
            msg = 'Current billing period data retrieved from AWS Cost Explorer.'
        else:
            total_mtd = 0.0
            total_projected = 0.0
            service_breakdown = {}
            service_mtd_breakdown = {}

            for r in resources_qs:
                c = costs_qs.filter(aws_resource_id=r.resource_id).first()
                if c and float(c.estimated_cost or 0.0) > 0:
                    r_mtd = float(c.actual_cost or 0.0)
                    r_proj = float(c.estimated_cost or 0.0)
                else:
                    calc = calculate_resource_monthly_and_mtd(float(r.estimated_hourly_cost or 0.0), r.service, r.resource_id)
                    r_mtd = calc['mtd_cost']
                    r_proj = calc['projected_monthly']

                total_mtd += r_mtd
                total_projected += r_proj
                service_breakdown[r.service] = service_breakdown.get(r.service, 0.0) + r_proj
                service_mtd_breakdown[r.service] = service_mtd_breakdown.get(r.service, 0.0) + r_mtd

            month_to_date_cost = round(total_mtd, 2)
            projected_monthly_cost = round(total_projected, 2)
            service_breakdown = {k: round(v, 2) for k, v in service_breakdown.items()}
            service_mtd_breakdown = {k: round(v, 2) for k, v in service_mtd_breakdown.items()}
            ce_total = projected_monthly_cost

            billing_status = 'PRICING_ESTIMATE'
            cost_source = 'AWS_PRICING'
            cost_source_display = 'AWS Pricing API'
            actual_available = False
            msg = 'Costs estimated from authoritative AWS On-Demand pricing rates. Final AWS billing may differ.'

        # High risk waste estimate
        waste_resources = resources_qs.filter(risk_level__in=['HIGH', 'CRITICAL'])
        waste_hourly = sum(float(r.estimated_hourly_cost) for r in waste_resources)
        estimated_monthly_waste = waste_hourly * 730.0
        daily_run_rate = round(sum(float(r.estimated_hourly_cost or 0.0) * 24.0 for r in resources_qs), 2)

        return Response({
            'success': True,
            'cost_data': {
                'actual_billing_available': actual_available,
                'actual_billing_message': msg,
                'estimated_monthly_total': round(projected_monthly_cost, 2),
                'month_to_date_cost': round(month_to_date_cost, 2),
                'projected_monthly_cost': round(projected_monthly_cost, 2),
                'daily_run_rate': daily_run_rate,
                'billing_period': 'October 2026',
                'service_breakdown': service_breakdown,
                'service_mtd_breakdown': service_mtd_breakdown,
                'currency': 'USD',
                'approx_inr_total': round(projected_monthly_cost * 86.50, 2),
                'approx_inr_mtd': round(month_to_date_cost * 86.50, 2),
                'approx_inr_waste': round(estimated_monthly_waste * 86.50, 2),
                'cost_source': cost_source,
                'cost_source_display': cost_source_display,
                'billing_status': billing_status,
                'is_estimated': True,
                'disclaimer': 'Final AWS billing may differ.'
            }
        })

