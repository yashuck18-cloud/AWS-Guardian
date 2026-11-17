from django.contrib import admin
from .models import Alert

@admin.register(Alert)
class AlertAdmin(admin.ModelAdmin):
    list_display = ('title', 'account', 'severity', 'status', 'rule_code', 'estimated_cost_impact', 'last_detected_at')
    list_filter = ('severity', 'status', 'rule_code')
    search_fields = ('title', 'description', 'rule_code', 'account__name')
    readonly_fields = ('id', 'first_detected_at', 'last_detected_at')
