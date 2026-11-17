from django.contrib import admin
from .models import NotificationSettings, NotificationHistory

@admin.register(NotificationSettings)
class NotificationSettingsAdmin(admin.ModelAdmin):
    list_display = ('user', 'morning_summary_enabled', 'evening_summary_enabled', 'urgent_alerts_enabled', 'telegram_enabled', 'timezone')
    search_fields = ('user__email', 'telegram_chat_id')

@admin.register(NotificationHistory)
class NotificationHistoryAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'channel', 'status', 'created_at')
    list_filter = ('channel', 'status', 'created_at')
    search_fields = ('title', 'message', 'user__email')
    readonly_fields = ('id', 'created_at')
