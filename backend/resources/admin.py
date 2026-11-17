from django.contrib import admin
from .models import Resource

@admin.register(Resource)
class ResourceAdmin(admin.ModelAdmin):
    list_display = ('resource_id', 'service', 'name', 'account', 'region', 'state', 'risk_level', 'estimated_hourly_cost', 'updated_at')
    list_filter = ('service', 'risk_level', 'region', 'state')
    search_fields = ('resource_id', 'name', 'account__name', 'account__account_id')
    readonly_fields = ('id', 'created_at', 'updated_at', 'last_seen_at')
