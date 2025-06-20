from django.urls import path
from . import views

urlpatterns = [
    # Auth endpoints
    path('register', views.register, name='register'),
    path('login', views.login, name='login'),
    path('verify', views.verify_connection, name='verify_connection'),
    
    # User endpoints
    path('list', views.list_users, name='list_users'),
    path('<str:username>', views.get_user_info, name='get_user_info'),
]