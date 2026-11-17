import logging
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from aws_accounts.models import AWSAccount
from notifications.dispatcher import scan_and_evaluate_account
from notifications.models import FCMDevice

logger = logging.getLogger(__name__)
User = get_user_model()

class Command(BaseCommand):
    help = 'Executes an automated AWS scan and evaluates attention-requiring resources for FCM notification'

    def add_arguments(self, parser):
        parser.add_argument(
            '--type',
            type=str,
            default='morning',
            choices=['morning', 'evening', 'manual'],
            help='Scan execution type (morning, evening, manual)'
        )
        parser.add_argument(
            '--account-id',
            type=str,
            default=None,
            help='Specific AWS Account ID or internal UUID to scan'
        )
        parser.add_argument(
            '--user-email',
            type=str,
            default=None,
            help='Filter accounts by user email'
        )
        parser.add_argument(
            '--force-notification',
            action='store_true',
            help='Force sending FCM notification even if attention count is 0 or duplicate'
        )
        parser.add_argument(
            '--simulate-clear',
            action='store_true',
            help='Simulate normal all-clear state (asserts zero notifications are sent)'
        )
        parser.add_argument(
            '--mock-fcm',
            action='store_true',
            help='Simulate FCM push delivery without calling Google servers (for local testing without service account key)'
        )
        parser.add_argument(
            '--allow-duplicate',
            action='store_true',
            default=True,
            help='Allow sending notification even if already sent within duplicate window (default: True for CLI testing)'
        )

    def handle(self, *args, **options):
        scan_type = options['type'].capitalize()
        account_param = options['account_id']
        user_email = options['user_email']
        force_notification = options['force_notification']
        simulate_clear = options['simulate_clear']
        mock_fcm = options['mock_fcm']
        allow_duplicate = options['allow_duplicate']

        trigger_source = f"SCHEDULED_{scan_type.upper()}" if scan_type in ['Morning', 'Evening'] else 'MANUAL'

        self.stdout.write(self.style.SUCCESS("=" * 70))
        self.stdout.write(self.style.SUCCESS(f"  AWS GUARDIAN — TRIGGER {scan_type.upper()} SCAN & EVALUATION"))
        self.stdout.write(self.style.SUCCESS("=" * 70))

        accounts = AWSAccount.objects.filter(status='CONNECTED').select_related('user')

        if account_param:
            from users.utils import is_valid_uuid
            if is_valid_uuid(account_param):
                accounts = accounts.filter(id=account_param)
            else:
                accounts = accounts.filter(account_id=account_param)

        if user_email:
            accounts = accounts.filter(user__email=user_email)

        if not accounts.exists():
            self.stdout.write(self.style.WARNING("No connected AWS accounts matched criteria."))
            return

        self.stdout.write(f"Found {accounts.count()} connected AWS account(s) to inspect.\n")

        for acc in accounts:
            user = acc.user
            fcm_devices_count = FCMDevice.objects.filter(user=user, is_active=True).count()

            self.stdout.write(self.style.NOTICE(
                f"> Scanning Account: {acc.name} ({acc.account_id}) | User: {user.email} | Active Devices: {fcm_devices_count}"
            ))

            result = scan_and_evaluate_account(
                account=acc,
                trigger_source=trigger_source,
                summary_type=scan_type,
                force_notification=force_notification,
                simulate_clear=simulate_clear,
                mock_fcm=mock_fcm,
                allow_duplicate=allow_duplicate
            )

            if not result.get('success'):
                self.stdout.write(self.style.ERROR(f"  [ERROR] Scan Failed: {result.get('message')}\n"))
                continue

            attention_count = result.get('attention_count', 0)
            notification_sent = result.get('notification_sent', False)
            notification_status = result.get('notification_status', 'UNKNOWN')

            if notification_sent:
                self.stdout.write(self.style.SUCCESS(
                    f"  [ATTENTION REQUIRED]: {attention_count} resource(s) flagged."
                ))
                self.stdout.write(self.style.SUCCESS(
                    f"  [FCM NOTIFICATION SENT] to {result.get('devices_notified', 0)} device(s)."
                ))
                self.stdout.write(f"    Title: {result.get('title')}")
                self.stdout.write(f"    Body:  {result.get('message')}\n")
            elif notification_status == 'SKIPPED_NO_RESOURCES':
                self.stdout.write(self.style.SUCCESS(
                    f"  [NORMAL STATE]: 0 attention resources flagged."
                ))
                self.stdout.write(self.style.NOTICE(
                    "  [NOTIFICATION SUPPRESSED]: Operating within normal baseline. No FCM sent.\n"
                ))
            elif notification_status == 'SKIPPED_DUPLICATE':
                self.stdout.write(self.style.WARNING(
                    f"  [DUPLICATE SUPPRESSED]: {attention_count} resource(s) need attention, but alert was already sent within window.\n"
                ))
            else:
                self.stdout.write(self.style.WARNING(
                    f"  [STATUS]: {notification_status} (FCM delivered: {notification_sent})\n"
                ))

        self.stdout.write(self.style.SUCCESS("Scan and evaluation pipeline finished."))
