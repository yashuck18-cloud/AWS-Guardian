from django.contrib import admin
from .models import Scan

@admin.register(Scan)
class ScanAdmin(admin.ModelAdmin):
    list_display = (
        'id', 'account', 'status', 'trigger_source',
        'resources_found', 'alerts_created',
        'notification_sent', 'notification_status',
        'started_at', 'completed_at'
    )
    list_filter = ('status', 'trigger_source', 'notification_sent', 'notification_status', 'started_at')
    search_fields = ('account__name', 'account__account_id', 'notification_title', 'error_message')
    readonly_fields = ('id', 'started_at', 'completed_at', 'notification_sent', 'notification_status', 'notification_title', 'notification_message')
