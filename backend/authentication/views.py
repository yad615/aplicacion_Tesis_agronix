from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.db import connection
from datetime import timedelta
from django.conf import settings
import logging

from .models import User
from .serializers import (
    UserLoginSerializer, UserRegisterSerializer, 
    LoginResponseSerializer, RegisterResponseSerializer
)
from .auth_utils import verify_password, get_password_hash, create_access_token

logger = logging.getLogger(__name__)

@api_view(['POST'])
@permission_classes([AllowAny])
def register(request):
    """Endpoint para registrar nuevos usuarios"""
    try:
        serializer = UserRegisterSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({
                'success': False,
                'message': 'Datos inválidos',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
        
        data = serializer.validated_data
        username = data['username']
        email = data['email']
        password = data['password']
        
        logger.info(f"Intento de registro para usuario: {username}")
        
        # Verificar si el usuario ya existe
        if User.objects.filter(username=username).exists() or User.objects.filter(email=email).exists():
            logger.warning(f"Usuario o email ya existe: {username}")
            return Response({
                'success': False,
                'message': 'Usuario o email ya existe'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Crear usuario
        password_hash = get_password_hash(password)
        user = User.objects.create(
            username=username,
            email=email,
            password_hash=password_hash,
            is_active=True
        )
        
        logger.info(f"Usuario registrado exitosamente: {username}")
        
        return Response({
            'success': True,
            'message': 'Usuario registrado exitosamente',
            'user': user.to_dict()
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        logger.error(f"Error interno en registro: {str(e)}")
        return Response({
            'success': False,
            'message': f'Error interno del servidor: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    """Endpoint para autenticar usuarios"""
    try:
        serializer = UserLoginSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({
                'success': False,
                'message': 'Datos inválidos',
                'errors': serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)
        
        data = serializer.validated_data
        username = data['username']
        email = data['email']
        password = data['password']
        
        logger.info(f"Intento de login para usuario: {username}")
        
        # Buscar usuario por username
        try:
            user = User.objects.get(username=username, is_active=True)
        except User.DoesNotExist:
            logger.warning(f"Usuario no encontrado: {username}")
            return Response({
                'success': False,
                'message': 'Usuario no encontrado'
            }, status=status.HTTP_404_NOT_FOUND)
        
        logger.info(f"Usuario encontrado: {user.username}")
        
        # Verificar contraseña
        if not verify_password(password, user.password_hash):
            logger.warning(f"Contraseña incorrecta para usuario: {username}")
            return Response({
                'success': False,
                'message': 'Contraseña incorrecta'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        # Verificar email
        if user.email != email:
            logger.warning(f"Email no coincide para usuario: {username}")
            return Response({
                'success': False,
                'message': 'Email no coincide con el usuario'
            }, status=status.HTTP_401_UNAUTHORIZED)
        
        logger.info(f"Autenticación exitosa para usuario: {username}")
        
        # Crear token de acceso
        access_token_expires = timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"sub": user.username, "email": user.email},
            expires_delta=access_token_expires
        )
        
        return Response({
            'success': True,
            'message': 'Login exitoso',
            'data': {
                'access_token': access_token,
                'token_type': 'bearer',
                'user': user.to_dict()
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        logger.error(f"Error interno en login: {str(e)}")
        return Response({
            'success': False,
            'message': f'Error interno del servidor: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def verify_connection(request):
    """Endpoint para verificar la conexión con la base de datos"""
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        
        return Response({
            'status': 'success',
            'message': 'Conexión a la base de datos exitosa'
        }, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error en verificación de conexión: {str(e)}")
        return Response({
            'status': 'error',
            'message': f'Error de conexión: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def list_users(request):
    """Endpoint para listar todos los usuarios (para debug)"""
    try:
        users = User.objects.all()
        users_data = [user.to_dict() for user in users]
        
        return Response({
            'users': users_data,
            'total': len(users_data)
        }, status=status.HTTP_200_OK)
    except Exception as e:
        logger.error(f"Error al listar usuarios: {str(e)}")
        return Response({
            'error': f'Error: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_user_info(request, username):
    """Endpoint para obtener información de un usuario específico"""
    try:
        try:
            user = User.objects.get(username=username, is_active=True)
            return Response({
                'status': 'found',
                'user': user.to_dict()
            }, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            return Response({
                'status': 'not_found',
                'message': f'Usuario \'{username}\' no encontrado'
            }, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"Error al buscar usuario: {str(e)}")
        return Response({
            'error': f'Error: {str(e)}'
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)