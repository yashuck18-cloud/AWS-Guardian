from rest_framework import generics, permissions
from .models import AuditLog
from .serializers import AuditLogSerializer

class AuditLogListView(generics.ListAPIView):
    serializer_class = AuditLogSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        # Strict tenant isolation
        queryset = AuditLog.objects.filter(user=self.request.user)
        action = self.request.query_params.get('action')
        if action:
            queryset = queryset.filter(action=action)
        return queryset
