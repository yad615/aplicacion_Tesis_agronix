# -*- coding: utf-8 -*-
import os
import google.generativeai as genai
import random
from datetime import timedelta, datetime
import json

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated

from django.utils import timezone
from django.core.cache import cache
from django.contrib.auth.models import User

from . import generic_calendar

OPTIMAL_RANGES = {
    'temperature_air': {'min': 20.0, 'max': 25.0, 'critical_min': 4.0, 'critical_max': 29.0},
    'humidity_air': {'min': 60.0, 'max': 80.0},
    'humidity_soil': {'min': 35.0, 'max': 65.0},
    'conductivity_ec': {'min': 0.7, 'max': 1.2},
    'temperature_soil': {'min': 15.0, 'max': 25.0},
    'solar_radiation': {'min': 300.0, 'max': 800.0},
}

CALENDAR_EVENTS = {}

class ChatbotAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def _get_real_crop_data(self, user_id):
        try:
            cache_key = f"crop_data_{user_id}"
            cached_data = cache.get(cache_key)
            
            if cached_data:
                return cached_data
            
            data = self._generate_simulated_data()
            cache.set(cache_key, data, 300)
            return data
            
        except Exception as e:
            print(f"Error obteniendo datos: {e}")
            return self._generate_simulated_data()

    def _generate_simulated_data(self):
        return {
            'temperature_air': round(random.uniform(18.0, 28.0), 1),
            'humidity_air': round(random.uniform(55.0, 85.0), 1),
            'humidity_soil': round(random.uniform(30.0, 70.0), 1),
            'conductivity_ec': round(random.uniform(0.5, 1.5), 2),
            'temperature_soil': round(random.uniform(12.0, 28.0), 1),
            'solar_radiation': round(random.uniform(250.0, 850.0), 1),
            'pest_risk': random.choice(['Bajo', 'Moderado', 'Alto']),
            'last_updated': timezone.now(),
        }

    def _get_status(self, value, param):
        ranges = OPTIMAL_RANGES.get(param)
        if not ranges:
            return 'Normal'
        
        if value < ranges['min']:
            return 'Bajo'
        elif value > ranges['max']:
            return 'Alto'
        else:
            return 'Óptimo'

    def _analyze_conditions(self, crop_data):
        alerts = []
        recommendations = []
        
        temp_air = crop_data['temperature_air']
        if temp_air < OPTIMAL_RANGES['temperature_air']['min']:
            alerts.append("⚠️ Temperatura del aire baja")
            recommendations.append("Considera usar calefacción o invernadero")
        elif temp_air > OPTIMAL_RANGES['temperature_air']['max']:
            alerts.append("🔥 Temperatura del aire alta")
            recommendations.append("Aumenta la ventilación o usa sombreado")
        
        humidity_soil = crop_data['humidity_soil']
        if humidity_soil < OPTIMAL_RANGES['humidity_soil']['min']:
            alerts.append("💧 Humedad del suelo baja")
            recommendations.append("Programa riego inmediato")
        elif humidity_soil > OPTIMAL_RANGES['humidity_soil']['max']:
            alerts.append("🌊 Humedad del suelo alta")
            recommendations.append("Reduce el riego y mejora el drenaje")
        
        ec = crop_data['conductivity_ec']
        if ec < OPTIMAL_RANGES['conductivity_ec']['min']:
            alerts.append("⚡ Conductividad baja")
            recommendations.append("Aplica fertilizante balanceado")
        elif ec > OPTIMAL_RANGES['conductivity_ec']['max']:
            alerts.append("⚡ Conductividad alta")
            recommendations.append("Riega para lixiviar sales")
        
        return alerts, recommendations

    def _create_context(self, crop_data):
        alerts, recommendations = self._analyze_conditions(crop_data)
        
        context = f"""
🌱 **DATOS ACTUALES - FRESAS 'SAN ANDREAS'**

📊 **Parámetros Principales:**
• Temperatura aire: {crop_data['temperature_air']}°C ({self._get_status(crop_data['temperature_air'], 'temperature_air')})
• Humedad aire: {crop_data['humidity_air']}% ({self._get_status(crop_data['humidity_air'], 'humidity_air')})
• Humedad suelo: {crop_data['humidity_soil']}% ({self._get_status(crop_data['humidity_soil'], 'humidity_soil')})
• Conductividad (EC): {crop_data['conductivity_ec']} dS/m ({self._get_status(crop_data['conductivity_ec'], 'conductivity_ec')})
• Temp. suelo: {crop_data['temperature_soil']}°C ({self._get_status(crop_data['temperature_soil'], 'temperature_soil')})
• Radiación solar: {crop_data['solar_radiation']} W/m² ({self._get_status(crop_data['solar_radiation'], 'solar_radiation')})
• Riesgo de plagas: {crop_data['pest_risk']}

🚨 **Alertas Actuales:**
{chr(10).join(alerts) if alerts else "✅ Todas las condiciones están normales"}

💡 **Recomendaciones:**
{chr(10).join(recommendations) if recommendations else "🎯 Mantén las condiciones actuales"}

⏰ **Última actualización:** {crop_data['last_updated'].strftime('%Y-%m-%d %H:%M:%S')}
        """
        return context.strip()

    def _create_calendar_task(self, user_id, title, description, priority="normal"):
        try:
            if user_id not in CALENDAR_EVENTS:
                CALENDAR_EVENTS[user_id] = []
            
            event = {
                'id': f"event_{len(CALENDAR_EVENTS[user_id]) + 1}",
                'title': title,
                'description': description,
                'date': timezone.now().date().isoformat(),
                'time': timezone.now().time().strftime('%H:%M'),
                'priority': priority,
                'created_by_ai': True,
                'created_at': timezone.now().isoformat()
            }
            
            CALENDAR_EVENTS[user_id].append(event)
            return event
        except Exception as e:
            print(f"Error creando evento: {e}")
            return None

    def _auto_create_tasks(self, user_id, crop_data):
        tasks_created = []
        
        today = timezone.now().date().isoformat()
        if user_id in CALENDAR_EVENTS:
            existing_auto_tasks = [
                event for event in CALENDAR_EVENTS[user_id] 
                if event.get('date') == today and event.get('created_by_ai', False)
            ]
            if existing_auto_tasks:
                return []
        
        if crop_data['humidity_soil'] < OPTIMAL_RANGES['humidity_soil']['min']:
            task = self._create_calendar_task(
                user_id,
                "🚨 Riego Urgente",
                f"Humedad del suelo: {crop_data['humidity_soil']}%. Riega inmediatamente.",
                "high"
            )
            if task:
                tasks_created.append(task['title'])
        
        if crop_data['conductivity_ec'] < OPTIMAL_RANGES['conductivity_ec']['min']:
            task = self._create_calendar_task(
                user_id,
                "🌱 Aplicar Fertilizante",
                f"Conductividad: {crop_data['conductivity_ec']} dS/m. Aplica fertilizante balanceado.",
                "medium"
            )
            if task:
                tasks_created.append(task['title'])
        
        if crop_data['pest_risk'] == 'Alto':
            task = self._create_calendar_task(
                user_id,
                "🐛 Inspección de Plagas",
                "Riesgo de plagas alto. Inspecciona cultivo y aplica tratamiento si es necesario.",
                "high"
            )
            if task:
                tasks_created.append(task['title'])
        
        task = self._create_calendar_task(
            user_id,
            "👀 Inspección Diaria",
            "Revisar estado general del cultivo, hojas y frutos.",
            "normal"
        )
        if task:
            tasks_created.append(task['title'])
        
        return tasks_created

    def _execute_tool_call(self, function_call, user_id):
        try:
            if function_call.name == "create_calendar_event":
                title = function_call.args.get('title', 'Tarea AgroNix')
                description = function_call.args.get('description', '')
                date = function_call.args.get('date', timezone.now().date().isoformat())
                time = function_call.args.get('time', '09:00')
                priority = function_call.args.get('priority', 'normal')
                
                result = generic_calendar.create_calendar_event(
                    title=title,
                    description=description,
                    date=date,
                    time=time,
                    priority=priority,
                    user_id=user_id
                )
                
                return result['details']['message']
                
            elif function_call.name == "search_calendar_events":
                query = function_call.args.get('query', '')
                start_date = function_call.args.get('start_date')
                end_date = function_call.args.get('end_date')
                
                result = generic_calendar.search_calendar_events(
                    query=query,
                    start_date=start_date,
                    end_date=end_date,
                    user_id=user_id
                )
                
                events = result['details']['events']
                if events:
                    formatted_events = []
                    for event in events:
                        formatted_events.append(f"📅 {event['title']} - {event['date']} {event['time']}")
                    return f"{result['details']['message']}\n" + "\n".join(formatted_events)
                else:
                    return result['details']['message']
                
            elif function_call.name == "show_calendar_events":
                date = function_call.args.get('date', timezone.now().date().isoformat())
                
                result = generic_calendar.show_calendar_events(
                    date=date,
                    user_id=user_id
                )
                
                events = result['details']['events']
                if events:
                    formatted_events = []
                    for event in events:
                        priority_emoji = {
                            'high': '🔴',
                            'medium': '🟡',
                            'normal': '🟢',
                            'low': '⚪'
                        }.get(event.get('priority', 'normal'), '🟢')
                        
                        formatted_events.append(f"{priority_emoji} {event['title']} - {event['time']}")
                    return f"{result['details']['message']}\n" + "\n".join(formatted_events)
                else:
                    return result['details']['message']
                
            elif function_call.name == "modify_calendar_event":
                event_id = function_call.args.get('event_id', '')
                title = function_call.args.get('title')
                description = function_call.args.get('description')
                date = function_call.args.get('date')
                time = function_call.args.get('time')
                priority = function_call.args.get('priority')
                
                result = generic_calendar.modify_calendar_event(
                    event_id=event_id,
                    title=title,
                    description=description,
                    date=date,
                    time=time,
                    priority=priority,
                    user_id=user_id
                )
                
                return result['details']['message']
                
            elif function_call.name == "delete_calendar_event":
                event_id = function_call.args.get('event_id', '')
                
                result = generic_calendar.delete_calendar_event(
                    event_id=event_id,
                    user_id=user_id
                )
                
                return result['details']['message']
                
            else:
                return f"❌ Herramienta no reconocida: {function_call.name}"
                
        except Exception as e:
            return f"❌ Error en herramienta: {str(e)}"

    def post(self, request, *args, **kwargs):
        user_message = request.data.get('message', '').strip()
        
        if not user_message:
            return Response({'error': 'Mensaje vacío'}, status=status.HTTP_400_BAD_REQUEST)

        gemini_api_key = os.getenv("GEMINI_API_KEY")
        if not gemini_api_key:
            return Response({
                'error': 'API no configurada'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        try:
            genai.configure(api_key=gemini_api_key)
            
            user_id = request.user.id
            crop_data = self._get_real_crop_data(user_id)
            context = self._create_context(crop_data)
            
            tasks_created = self._auto_create_tasks(user_id, crop_data)
            
            tools = [
                generic_calendar.create_calendar_event,
                generic_calendar.search_calendar_events,
                generic_calendar.show_calendar_events,
                generic_calendar.modify_calendar_event,
                generic_calendar.delete_calendar_event,
            ]
            
            model = genai.GenerativeModel('gemini-1.5-flash', tools=tools)
            
            system_prompt = f"""
Eres AgroNix, asistente IA para cultivo de fresas. Desarrollado por Yadhira Alcántara y Diego Sánchez.

REGLAS DE RESPUESTA:
• Respuestas CONCISAS (máximo 150 palabras)
• Usa emojis para hacer visual la información
• Identifica problemas y da soluciones específicas
• Crea tareas en el calendario cuando sea necesario
• Responde de forma amigable y profesional
• Si detectas problemas críticos, recomienda acciones inmediatas

{context}

TAREAS CREADAS AUTOMÁTICAMENTE HOY:
{chr(10).join([f"✅ {task}" for task in tasks_created]) if tasks_created else "🔄 No se crearon tareas nuevas hoy"}

Analiza los datos y responde a la consulta del usuario de forma práctica y útil.
"""
            
            chat = model.start_chat()
            response = chat.send_message(f"{system_prompt}\n\nConsulta del usuario: {user_message}")
            
            chatbot_response = ""
            
            if response.candidates and response.candidates[0].content.parts:
                for part in response.candidates[0].content.parts:
                    if part.function_call:
                        tool_response = self._execute_tool_call(part.function_call, user_id)
                        follow_up = chat.send_message(f"Resultado de la herramienta: {tool_response}")
                        if follow_up.text:
                            chatbot_response += follow_up.text
                    elif part.text:
                        chatbot_response += part.text

            if not chatbot_response:
                chatbot_response = "❓ No pude procesar tu consulta. ¿Podrías ser más específico?"

            return Response({
                'response': chatbot_response,
                'crop_data': crop_data,
                'tasks_created': tasks_created,
                'timestamp': timezone.now().isoformat()
            }, status=status.HTTP_200_OK)

        except Exception as e:
            print(f"Error en chatbot: {e}")
            
            if "404" in str(e):
                error_msg = "🔧 Error de configuración del modelo IA"
            elif "SAFETY" in str(e):
                error_msg = "🚫 Consulta bloqueada por políticas de seguridad"
            elif "QUOTA" in str(e):
                error_msg = "⏳ Servicio temporalmente no disponible"
            else:
                error_msg = "❌ Error interno del servidor"
            
            return Response({
                'response': error_msg,
                'error': True
            }, status=status.HTTP_200_OK)

    def get(self, request, *args, **kwargs):
        user_id = request.user.id
        
        if user_id not in CALENDAR_EVENTS:
            return Response({
                'events': [],
                'total': 0
            }, status=status.HTTP_200_OK)
        
        events = CALENDAR_EVENTS[user_id]
        
        date_filter = request.query_params.get('date')
        if date_filter:
            events = [event for event in events if event['date'] == date_filter]
        
        return Response({
            'events': events,
            'total': len(events)
        }, status=status.HTTP_200_OK)


class CropDataAPIView(APIView):
    permission_classes = [IsAuthenticated]
    
    def get(self, request, *args, **kwargs):
        try:
            user_id = request.user.id
            
            chatbot_view = ChatbotAPIView()
            
            crop_data = chatbot_view._get_real_crop_data(user_id)
            
            alerts, recommendations = chatbot_view._analyze_conditions(crop_data)
            
            status_summary = {}
            for param in ['temperature_air', 'humidity_air', 'humidity_soil', 'conductivity_ec', 'temperature_soil', 'solar_radiation']:
                if param in crop_data:
                    status_summary[param] = chatbot_view._get_status(crop_data[param], param)
            
            return Response({
                'success': True,
                'crop_data': crop_data,
                'status_summary': status_summary,
                'alerts': alerts,
                'recommendations': recommendations,
                'optimal_ranges': OPTIMAL_RANGES,
                'timestamp': timezone.now().isoformat()
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            print(f"Error en CropDataAPIView: {e}")
            return Response({
                'success': False,
                'error': 'Error al obtener datos del cultivo',
                'details': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def post(self, request, *args, **kwargs):
        try:
            user_id = request.user.id
            
            cache_key = f"crop_data_{user_id}"
            cache.delete(cache_key)
            
            chatbot_view = ChatbotAPIView()
            crop_data = chatbot_view._get_real_crop_data(user_id)
            alerts, recommendations = chatbot_view._analyze_conditions(crop_data)
            
            return Response({
                'success': True,
                'message': 'Datos del cultivo actualizados',
                'crop_data': crop_data,
                'alerts': alerts,
                'recommendations': recommendations,
                'timestamp': timezone.now().isoformat()
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            print(f"Error actualizando datos del cultivo: {e}")
            return Response({
                'success': False,
                'error': 'Error al actualizar datos del cultivo'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)