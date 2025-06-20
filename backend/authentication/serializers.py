from rest_framework import serializers
from .models import User

class UserLoginSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=50)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    
    def validate_email(self, value):
        if not value.endswith('@agronix.com'):
            raise serializers.ValidationError("Solo se permiten emails con dominio @agronix.com")
        return value

class UserRegisterSerializer(serializers.Serializer):
    username = serializers.CharField(max_length=50)
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    
    def validate_email(self, value):
        if not value.endswith('@agronix.com'):
            raise serializers.ValidationError("Solo se permiten emails con dominio @agronix.com")
        return value

class UserResponseSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    username = serializers.CharField()
    email = serializers.EmailField()
    is_active = serializers.BooleanField()
    created_at = serializers.CharField()

class TokenSerializer(serializers.Serializer):
    access_token = serializers.CharField()
    token_type = serializers.CharField()
    user = UserResponseSerializer()

class LoginResponseSerializer(serializers.Serializer):
    success = serializers.BooleanField()
    message = serializers.CharField()
    data = TokenSerializer(required=False, allow_null=True)

class RegisterResponseSerializer(serializers.Serializer):
    success = serializers.BooleanField()
    message = serializers.CharField()
    user = UserResponseSerializer(required=False, allow_null=True)