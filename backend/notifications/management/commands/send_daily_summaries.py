from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from notifications.dispatcher import dispatch_summary_notification
from notifications.models import NotificationSettings
import logging

logger = logging.getLogger(__name__)
User = get_user_model()

class Command(BaseCommand):
    help = 'Dispatches scheduled Morning or Evening AWS Guardian summaries via FCM and Telegram'

    def add_arguments(self, parser):
        parser.add_argument(
            '--type',
            type=str,
            default='Morning',
            choices=['Morning', 'Evening', 'Daily'],
            help='Summary type (Morning or Evening)'
        )
        parser.add_argument(
            '--user-id',
            type=str,
            default=None,
            help='Dispatch summary to a specific user ID only'
        )

    def handle(self, *args, **options):
        summary_type = options['type']
        user_id = options['user_id']

        if user_id:
            users = User.objects.filter(id=user_id, is_active=True)
        else:
            users = User.objects.filter(is_active=True)

        self.stdout.write(self.style.NOTICE(f"Dispatching {summary_type} summaries to {users.count()} user(s)..."))

        success_count = 0
        for user in users:
            settings, _ = NotificationSettings.objects.get_or_create(user=user)
            
            # Check if this summary type is enabled in user settings
            if summary_type == 'Morning' and not settings.morning_summary_enabled:
                self.stdout.write(f"Skipping {user.email}: Morning summaries disabled.")
                continue
            if summary_type == 'Evening' and not settings.evening_summary_enabled:
                self.stdout.write(f"Skipping {user.email}: Evening summaries disabled.")
                continue

            try:
                success, msg = dispatch_summary_notification(user, summary_type=summary_type)
                if success:
                    success_count += 1
                    self.stdout.write(self.style.SUCCESS(f"Successfully sent {summary_type} summary to {user.email}"))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f"Failed to send summary to {user.email}: {e}"))

        self.stdout.write(self.style.SUCCESS(f"Finished. Successfully sent {success_count}/{users.count()} summaries."))
