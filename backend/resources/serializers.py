from rest_framework import serializers
from .models import Resource, ResourceCost

class ResourceCostSerializer(serializers.ModelSerializer):
    resource_id = serializers.CharField(source='aws_resource_id', read_only=True)
    cost_source_display = serializers.CharField(source='get_cost_source_display', read_only=True)
    billing_status_display = serializers.CharField(source='get_billing_status_display', read_only=True)
    approx_inr = serializers.SerializerMethodField()
    month_to_date_cost = serializers.SerializerMethodField()
    projected_monthly_cost = serializers.SerializerMethodField()
    daily_cost = serializers.SerializerMethodField()

    class Meta:
        model = ResourceCost
        fields = (
            'id', 'resource_id', 'service', 'region', 'resource_type',
            'actual_cost', 'estimated_cost', 'currency',
            'pricing_rate', 'pricing_unit',
            'usage_quantity', 'usage_unit',
            'cost_source', 'cost_source_display',
            'billing_status', 'billing_status_display',
            'billing_period_start', 'billing_period_end',
            'month_to_date_cost', 'projected_monthly_cost', 'daily_cost',
            'approx_inr', 'notes', 'last_updated'
        )
        read_only_fields = fields

    def get_month_to_date_cost(self, obj):
        return round(float(obj.actual_cost or 0.0), 2)

    def get_projected_monthly_cost(self, obj):
        return round(float(obj.estimated_cost or 0.0), 2)

    def get_daily_cost(self, obj):
        rate = float(obj.pricing_rate or 0.0)
        return round(rate * 24.0, 2)

    def get_approx_inr(self, obj):
        # Current standard exchange rate reference ~86.50 INR per USD
        cost_val = float(obj.actual_cost or obj.estimated_cost or 0.0)
        return round(cost_val * 86.50, 2)


class ResourceSerializer(serializers.ModelSerializer):
    account_name = serializers.CharField(source='account.name', read_only=True)
    account_number = serializers.CharField(source='account.account_id', read_only=True)
    service_display = serializers.CharField(source='get_service_display', read_only=True)
    risk_display = serializers.CharField(source='get_risk_level_display', read_only=True)
    cost_info = serializers.SerializerMethodField()

    class Meta:
        model = Resource
        fields = (
            'id', 'account', 'account_name', 'account_number', 'service', 'service_display',
            'resource_id', 'name', 'region', 'state', 'resource_type',
            'risk_level', 'risk_display', 'risk_reason',
            'estimated_hourly_cost', 'cost_info', 'metadata',
            'last_seen_at', 'created_at', 'updated_at'
        )
        read_only_fields = fields

    def get_cost_info(self, obj):
        latest_cost = obj.cost_records.order_by('-last_updated').first()
        if latest_cost:
            return ResourceCostSerializer(latest_cost).data
        # Fallback default cost structure based on resource rates
        hourly = float(obj.estimated_hourly_cost or 0.0)
        from scanner.cost_service import calculate_resource_monthly_and_mtd
        calc = calculate_resource_monthly_and_mtd(hourly, obj.service, obj.resource_id)
        return {
            'resource_id': obj.resource_id,
            'service': obj.service,
            'region': obj.region,
            'resource_type': obj.resource_type,
            'actual_cost': f"{calc['mtd_cost']:.4f}",
            'estimated_cost': f"{calc['projected_monthly']:.4f}",
            'month_to_date_cost': calc['mtd_cost'],
            'projected_monthly_cost': calc['projected_monthly'],
            'daily_cost': calc['daily_rate'],
            'currency': 'USD',
            'pricing_rate': f"{hourly:.6f}",
            'pricing_unit': 'Hrs',
            'cost_source': 'AWS_PRICING',
            'cost_source_display': 'AWS Pricing API',
            'billing_status': 'PRICING_ESTIMATE',
            'billing_status_display': 'Pricing-Based Estimate',
            'approx_inr': round(calc['mtd_cost'] * 86.50, 2),
            'notes': f"Rate: ${hourly:.4f}/hr (~${calc['daily_rate']:.2f}/day). October MTD: ${calc['mtd_cost']:.2f}. Full Month Est: ${calc['projected_monthly']:.2f}.",
            'last_updated': obj.updated_at.isoformat() if obj.updated_at else None
        }

class StopResourceSerializer(serializers.Serializer):
    confirm = serializers.BooleanField(required=True)

class DeleteResourceSerializer(serializers.Serializer):
    confirm_resource_id = serializers.CharField(required=True)

