from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from django.contrib.auth import authenticate, get_user_model
from .serializers import (
    UserRegistrationSerializer,
    UserLoginSerializer,
    UserProfileSerializer,
    ChangePasswordSerializer
)
from .utils import generate_jwt_token
from audit.logger import log_audit_event

User = get_user_model()

class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = UserRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            token = generate_jwt_token(user)
            user_data = UserProfileSerializer(user).data
            log_audit_event(
                user=user,
                action="USER_REGISTERED",
                details={"email": user.email, "name": user.name}
            )
            return Response({
                'success': True,
                'message': 'Account created successfully.',
                'token': token,
                'user': user_data
            }, status=status.HTTP_201_CREATED)

        # Extract first validation error message for clean UX
        error_msg = 'Validation failed.'
        if serializer.errors:
            first_field = next(iter(serializer.errors))
            first_err = serializer.errors[first_field]
            if isinstance(first_err, list) and len(first_err) > 0:
                error_msg = str(first_err[0])
            elif isinstance(first_err, str):
                error_msg = first_err

        return Response({
            'success': False,
            'message': error_msg,
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)

class LoginView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        serializer = UserLoginSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({
                'success': False,
                'message': 'Please provide email and password.',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)

        email = serializer.validated_data['email'].strip().lower()
        password = serializer.validated_data['password']

        try:
            user = User.objects.filter(email__iexact=email).first()
            if not user or not user.check_password(password):
                return Response({
                    'success': False,
                    'message': 'Invalid email or password.'
                }, status=status.HTTP_401_UNAUTHORIZED)
        except Exception:
            return Response({
                'success': False,
                'message': 'Invalid email or password.'
            }, status=status.HTTP_401_UNAUTHORIZED)

        if not user.is_active:
            return Response({
                'success': False,
                'message': 'Account is inactive. Please contact support.'
            }, status=status.HTTP_403_FORBIDDEN)

        token = generate_jwt_token(user)
        user_data = UserProfileSerializer(user).data

        return Response({
            'success': True,
            'message': 'Signed in successfully.',
            'token': token,
            'user': user_data
        }, status=status.HTTP_200_OK)

class ProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        serializer = UserProfileSerializer(request.user)
        return Response({
            'success': True,
            'user': serializer.data
        })

    def patch(self, request):
        serializer = UserProfileSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response({
                'success': True,
                'message': 'Profile updated successfully.',
                'user': serializer.data
            })
        return Response({
            'success': False,
            'message': 'Failed to update profile.',
            'errors': serializer.errors
        }, status=status.HTTP_400_BAD_REQUEST)

class ChangePasswordView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({
                'success': False,
                'message': 'Validation failed.',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)

        user = request.user
        if not user.check_password(serializer.validated_data['old_password']):
            return Response({
                'success': False,
                'message': 'Current password is incorrect.'
            }, status=status.HTTP_400_BAD_REQUEST)

        user.set_password(serializer.validated_data['new_password'])
        user.save()

        # Generate a new token
        new_token = generate_jwt_token(user)
        return Response({
            'success': True,
            'message': 'Password changed successfully.',
            'token': new_token
        })

class ForgotPasswordView(APIView):
    permission_classes = [permissions.AllowAny]

    def post(self, request):
        email = request.data.get('email')
        if not email:
            return Response({
                'success': False,
                'message': 'Email is required.'
            }, status=status.HTTP_400_BAD_REQUEST)

        # In production this would send a real reset email
        # To avoid enumeration attacks, always respond with success
        return Response({
            'success': True,
            'message': f'Password reset link has been dispatched to {email}.'
        })

class DeleteAccountView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request):
        user = request.user
        log_audit_event(user, 'USER_ACCOUNT_DELETED', {'email': user.email})
        user.delete()
        return Response({
            'success': True,
            'message': 'Account deleted successfully.'
        })
