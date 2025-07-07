from django.urls import path
from .views import register, LoginView, verify_connection, list_users, get_user_info

urlpatterns = [
    # Auth endpoints
    path('register', register, name='register'),
    path('login/', LoginView.as_view(), name='login'), 
    path('verify', verify_connection, name='verify_connection'),
    
    # User endpoints
    path('list', list_users, name='list_users'),
    path('<str:username>', get_user_info, name='get_user_info'),
]