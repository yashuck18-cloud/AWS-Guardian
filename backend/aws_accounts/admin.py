from django.contrib import admin
from .models import AWSAccount

@admin.register(AWSAccount)
class AWSAccountAdmin(admin.ModelAdmin):
    list_display = ('name', 'account_id', 'user', 'status', 'last_scan_at', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('name', 'account_id', 'user__email', 'role_arn')
    readonly_fields = ('id', 'external_id', 'created_at', 'updated_at')
