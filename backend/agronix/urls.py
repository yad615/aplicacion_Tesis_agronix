from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse

def root_view(request):
    return JsonResponse({"message": "AgroNix API - Sistema de Gestión Agrícola"})

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', root_view, name='root'),
    path('auth/', include('authentication.urls')),
    path('users/', include('authentication.urls')),
    path('api/chat/', include('chatbot_api.urls')), 
]