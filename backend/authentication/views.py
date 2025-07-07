import logging
import os
from datetime import timedelta, datetime

from django.db import connection
from django.contrib.auth.hashers import make_password, check_password

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView

from rest_framework_simplejwt.tokens import RefreshToken

from .models import User
from .serializers import (
    UserLoginSerializer, UserRegisterSerializer,
)

logger = logging.getLogger(__name__)

def get_jwt_tokens_for_user(user):
    refresh = RefreshToken.for_user(user)
    return {
        'access_token': str(refresh.access_token),
        'refresh_token': str(refresh),
    }

@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    try:
        serializer = UserRegisterSerializer(data=request.data)
        if not serializer.is_valid():
            logger.warning(f"Intento de registro con datos inválidos: {serializer.errors}")
            return Response({
                'success': False,
                'message': 'Datos inválidos',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        username = data['username']
        email = data['email']
        password = data['password']

        if not email.endswith('@agronix.com'):
            logger.warning(f"Intento de registro con email de dominio inválido: {email}")
            return Response({
                'success': False,
                'message': 'Solo se permiten emails con dominio @agronix.com'
            }, status=status.HTTP_400_BAD_REQUEST)

        if User.objects.filter(username=username).exists():
            logger.warning(f"Intento de registro de usuario existente: {username}")
            return Response({
                'success': False,
                'message': 'El nombre de usuario ya está en uso'
            }, status=status.HTTP_400_BAD_REQUEST)

        if User.objects.filter(email=email).exists():
            logger.warning(f"Intento de registro con email ya registrado: {email}")
            return Response({
                'success': False,
                'message': 'El email ya está registrado'
            }, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
        )

        logger.info(f"Usuario registrado exitosamente: {username} (ID: {user.id})")

        tokens = get_jwt_tokens_for_user(user)

        return Response({
            'success': True,
            'message': 'Usuario registrado exitosamente',
            'user': user.to_dict(),
            'access_token': tokens['access_token'],
            'refresh_token': tokens['refresh_token']
        }, status=status.HTTP_201_CREATED)

    except Exception as e:
        logger.error(f"Error interno en registro de usuario: {str(e)}", exc_info=True)
        return Response({
            'success': False,
            'message': 'Error interno del servidor al registrar usuario'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        try:
            serializer = UserLoginSerializer(data=request.data)
            if not serializer.is_valid():
                logger.warning(f"Intento de login con datos inválidos: {serializer.errors}")
                return Response({
                    'success': False,
                    'message': 'Datos inválidos',
                    'errors': serializer.errors
                }, status=status.HTTP_400_BAD_REQUEST)

            data = serializer.validated_data
            username = data['username']
            password = data['password']

            try:
                user = User.objects.get(username=username, is_active=True)
            except User.DoesNotExist:
                logger.warning(f"Intento de login de usuario inexistente o inactivo: {username}")
                return Response({
                    'success': False,
                    'message': 'Usuario o contraseña incorrectos.'
                }, status=status.HTTP_400_BAD_REQUEST)

            if not user.check_password(password):
                logger.warning(f"Contraseña incorrecta para usuario: {user.username}")
                return Response({
                    'success': False,
                    'message': 'Usuario o contraseña incorrectos.'
                }, status=status.HTTP_400_BAD_REQUEST)

            logger.info(f"Autenticación exitosa para usuario: {user.username}")

            tokens = get_jwt_tokens_for_user(user)

            return Response({
                'success': True,
                'message': 'Login exitoso',
                'data': {
                    'access_token': tokens['access_token'],
                    'refresh_token': tokens['refresh_token'],
                    'token_type': 'bearer',
                    'user': user.to_dict()
                }
            }, status=status.HTTP_200_OK)

        except Exception as e:
            logger.error(f"Error interno en login de usuario: {str(e)}", exc_info=True)
            return Response({
                'success': False,
                'message': 'Error interno del servidor durante el login'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([AllowAny])
def verify_connection(request):
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        
        return Response({
            'status': 'success',
            'message': 'Conexión a la base de datos exitosa'
        }, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error en verificación de conexión a DB: {str(e)}", exc_info=True)
        return Response({
            'status': 'error',
            'message': f'Error de conexión: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([AllowAny])
def list_users(request):
    try:
        users = User.objects.all()
        users_data = [user.to_dict() for user in users]
        
        return Response({
            'users': users_data,
            'total': len(users_data)
        }, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error al listar usuarios: {str(e)}", exc_info=True)
        return Response({
            'error': f'Error: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([AllowAny])
def get_user_info(request, username):
    try:
        try:
            user = User.objects.get(username=username, is_active=True)
            return Response({
                'status': 'found',
                'user': user.to_dict()
            }, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            logger.warning(f"Usuario '{username}' no encontrado o inactivo.")
            return Response({
                'status': 'not_found',
                'message': f'Usuario \'{username}\' no encontrado'
            }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"Error al buscar usuario '{username}': {str(e)}", exc_info=True)
        return Response({
            'error': f'Error: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def profile(request):
    try:
        user = request.user
        return Response({
            'success': True,
            'user': user.to_dict()
        }, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error al obtener perfil de usuario: {str(e)}", exc_info=True)
        return Response({
            'success': False,
            'message': 'Error interno del servidor'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout(request):
    try:
        refresh_token = request.data.get('refresh_token')
        if not refresh_token:
            return Response({
                'success': False,
                'message': 'Refresh token es requerido'
            }, status=status.HTTP_400_BAD_REQUEST)

        token = RefreshToken(refresh_token)
        token.blacklist()

        logger.info(f"Logout exitoso para usuario: {request.user.username}")
        return Response({
            'success': True,
            'message': 'Logout exitoso'
        }, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error en logout: {str(e)}", exc_info=True)
        return Response({
            'success': False,
            'message': 'Error interno del servidor'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)