from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse

admin.site.site_header = "AWS Guardian Administration"
admin.site.site_title = "AWS Guardian Admin Portal"
admin.site.index_title = "AWS Guardian Management Dashboard"

def health_check(request):
    return JsonResponse({
        'status': 'healthy',
        'service': 'AWS Guardian Backend API',
        'version': '1.0.0'
    })

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/health/', health_check, name='health_check'),
    path('api/auth/', include('users.urls')),
    path('api/aws-accounts/', include('aws_accounts.urls')),
    path('api/resources/', include('resources.urls')),
    path('api/scanner/', include('scanner.urls')),
    path('api/alerts/', include('alerts.urls')),
    path('api/notifications/', include('notifications.urls')),
    path('api/analytics/', include('analytics.urls')),
    path('api/dashboard/', include('analytics.urls')),
    path('api/audit/', include('audit.urls')),
    path('api/admin/', include('admin_panel.urls')),
]
