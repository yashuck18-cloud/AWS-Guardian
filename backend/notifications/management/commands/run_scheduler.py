import time
import os
import logging
from datetime import datetime
from zoneinfo import ZoneInfo
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.conf import settings
from notifications.dispatcher import scan_and_evaluate_account
from notifications.models import NotificationSettings
from aws_accounts.models import AWSAccount

logger = logging.getLogger(__name__)
User = get_user_model()

class Command(BaseCommand):
    help = 'Runs continuous background scheduler daemon for twice-daily AWS scans (09:00 AM & 06:00 PM) and attention-driven FCM alerts'

    def add_arguments(self, parser):
        parser.add_argument(
            '--check-interval',
            type=int,
            default=30,
            help='Scheduler polling interval in seconds (default: 30)'
        )

    def handle(self, *args, **options):
        interval = options.get('check_interval', 30)

        morning_cfg = os.getenv('MORNING_SCAN_TIME', getattr(settings, 'MORNING_SCAN_TIME', '09:00'))
        evening_cfg = os.getenv('EVENING_SCAN_TIME', getattr(settings, 'EVENING_SCAN_TIME', '18:00'))
        tz_name = os.getenv('SCAN_TIMEZONE', getattr(settings, 'SCAN_TIMEZONE', 'Asia/Kolkata'))

        try:
            tz = ZoneInfo(tz_name)
        except Exception:
            tz = ZoneInfo('UTC')
            tz_name = 'UTC'

        import sys
        self.stdout.write(self.style.SUCCESS("=" * 70))
        self.stdout.write(self.style.SUCCESS("  AWS GUARDIAN AUTOMATED SCAN & NOTIFICATION SCHEDULER"))
        self.stdout.write(self.style.SUCCESS("=" * 70))
        self.stdout.write(f"- Timezone: {tz_name}")
        self.stdout.write(f"- Morning Scan: {morning_cfg}")
        self.stdout.write(f"- Evening Scan: {evening_cfg}")
        self.stdout.write(f"- Poll Interval: {interval}s")
        self.stdout.write(self.style.NOTICE("Status: Running... (Press Ctrl+C to terminate)\n"))
        sys.stdout.flush()

        # Deduplication tracker: (account_id, date_str, window_type) -> timestamp
        dispatched_windows = {}

        while True:
            try:
                now = datetime.now(tz)
                today_str = now.strftime("%Y-%m-%d")
                current_hm = now.strftime("%H:%M")

                users = User.objects.filter(is_active=True).prefetch_related('aws_accounts')

                for user in users:
                    user_settings, _ = NotificationSettings.objects.get_or_create(user=user)
                    connected_accounts = user.aws_accounts.filter(status='CONNECTED')

                    if not connected_accounts.exists():
                        continue

                    # 1. MORNING SCHEDULE (Default 09:00 AM)
                    target_morning = getattr(user_settings, 'morning_summary_time', None) or morning_cfg
                    if user_settings.morning_summary_enabled and current_hm == target_morning:
                        for acct in connected_accounts:
                            window_key = (str(acct.id), today_str, 'Morning')
                            if window_key not in dispatched_windows:
                                self.stdout.write(self.style.NOTICE(
                                    f"[{now.strftime('%H:%M:%S')}] Triggering MORNING scan & evaluation for {acct.name} ({acct.account_id})..."
                                ))
                                try:
                                    res = scan_and_evaluate_account(
                                        account=acct,
                                        trigger_source='SCHEDULED_MORNING',
                                        summary_type='Morning'
                                    )
                                    dispatched_windows[window_key] = time.time()
                                    if res.get('notification_sent'):
                                        self.stdout.write(self.style.SUCCESS(
                                            f"  [ALERT SENT]: {res.get('attention_count')} resources require attention."
                                        ))
                                    else:
                                        self.stdout.write(self.style.SUCCESS(
                                            f"  [SCAN COMPLETED]: No attention needed (Notification suppressed)."
                                        ))
                                except Exception as err:
                                    logger.exception(f"Error during morning scan for {acct.account_id}: {err}")
                                    self.stdout.write(self.style.ERROR(f"  [ERROR] Morning scan error: {err}"))

                    # 2. EVENING SCHEDULE (Default 06:00 PM / 18:00)
                    target_evening = getattr(user_settings, 'evening_summary_time', None) or evening_cfg
                    if user_settings.evening_summary_enabled and current_hm == target_evening:
                        for acct in connected_accounts:
                            window_key = (str(acct.id), today_str, 'Evening')
                            if window_key not in dispatched_windows:
                                self.stdout.write(self.style.NOTICE(
                                    f"[{now.strftime('%H:%M:%S')}] Triggering EVENING scan & evaluation for {acct.name} ({acct.account_id})..."
                                ))
                                try:
                                    res = scan_and_evaluate_account(
                                        account=acct,
                                        trigger_source='SCHEDULED_EVENING',
                                        summary_type='Evening'
                                    )
                                    dispatched_windows[window_key] = time.time()
                                    if res.get('notification_sent'):
                                        self.stdout.write(self.style.SUCCESS(
                                            f"  [ALERT SENT]: {res.get('attention_count')} resources require attention."
                                        ))
                                    else:
                                        self.stdout.write(self.style.SUCCESS(
                                            f"  [SCAN COMPLETED]: No attention needed (Notification suppressed)."
                                        ))
                                except Exception as err:
                                    logger.exception(f"Error during evening scan for {acct.account_id}: {err}")
                                    self.stdout.write(self.style.ERROR(f"  [ERROR] Evening scan error: {err}"))

                # Prune old dispatched windows older than today
                stale_keys = [k for k in dispatched_windows if k[1] != today_str]
                for k in stale_keys:
                    del dispatched_windows[k]

            except Exception as loop_err:
                logger.exception(f"Scheduler daemon error: {loop_err}")
                self.stdout.write(self.style.ERROR(f"Scheduler exception: {loop_err}"))

            time.sleep(interval)

