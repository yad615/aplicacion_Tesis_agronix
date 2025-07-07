from django.urls import path
from . import views

urlpatterns = [
     path('', views.ChatbotAPIView.as_view(), name='chatbot_api'),
    path('crop-data/', views.CropDataAPIView.as_view(), name='crop_data_api'),

]
