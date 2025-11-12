# Estructura de Endpoints - Agronix App

## 📁 Organización de la API

Los endpoints de la aplicación han sido reorganizados en una estructura modular para facilitar el mantenimiento y escalabilidad del proyecto.

### Estructura de Carpetas

```
lib/
├── config/
│   └── api_config.dart          # Configuración general de la API
├── services/
│   ├── api_service.dart         # Servicio principal de API
│   └── endpoints/
│       ├── endpoints.dart        # Barrel file (exporta todos los endpoints)
│       ├── auth_endpoints.dart   # Endpoints de autenticación
│       ├── parcela_endpoints.dart # Endpoints de parcelas
│       ├── chatbot_endpoints.dart # Endpoints del chatbot
│       ├── plan_endpoints.dart   # Endpoints de planes
│       ├── sensor_endpoints.dart # Endpoints de sensores
│       ├── alert_endpoints.dart  # Endpoints de alertas
│       └── task_endpoints.dart   # Endpoints de tareas
```

## 📋 Descripción de Archivos

### `api_config.dart`
Configuración centralizada de la API:
- **baseUrl**: URL base del servidor backend
- **timeout**: Tiempo de espera para peticiones HTTP
- **defaultHeaders**: Headers por defecto
- **authHeaders**: Headers con token de autenticación

### Endpoints por Módulo

#### 1. **AuthEndpoints** - Autenticación
```dart
- login         // POST: Iniciar sesión
- register      // POST: Registrar usuario
- logout        // POST: Cerrar sesión
- userProfile   // GET/PATCH: Perfil del usuario
```

#### 2. **ParcelaEndpoints** - Gestión de Parcelas
```dart
- list          // GET: Lista de parcelas
- create        // POST: Crear parcela
- update(id)    // PUT: Actualizar parcela
- delete(id)    // DELETE: Eliminar parcela
- detail(id)    // GET: Detalle de parcela
```

#### 3. **ChatbotEndpoints** - Asistente IA
```dart
- cropData      // GET: Datos del cultivo
- chat          // POST: Enviar mensaje al chatbot
- history       // GET: Historial de conversaciones
```

#### 4. **PlanEndpoints** - Planes de Suscripción
```dart
- list          // GET: Lista de planes
- current       // GET: Plan actual del usuario
- detail(id)    // GET: Detalle de un plan
```

#### 5. **SensorEndpoints** - Datos de Sensores
```dart
- readings                           // GET: Lecturas de sensores
- latest                             // GET: Última lectura
- parcelaReadings(parcelaId)         // GET: Lecturas de una parcela
- readingsInRange(id, start, end)    // GET: Lecturas en rango de fechas
```

#### 6. **AlertEndpoints** - Alertas del Sistema
```dart
- list              // GET: Lista de alertas
- active            // GET: Alertas activas
- detail(id)        // GET: Detalle de alerta
- acknowledge(id)   // POST: Reconocer alerta
- dismiss(id)       // POST: Descartar alerta
```

#### 7. **TaskEndpoints** - Tareas y Recomendaciones
```dart
- list          // GET: Lista de tareas
- create        // POST: Crear tarea
- suggested     // GET: Tareas sugeridas por IA
- detail(id)    // GET: Detalle de tarea
- update(id)    // PUT: Actualizar tarea
- delete(id)    // DELETE: Eliminar tarea
- complete(id)  // POST: Marcar como completada
- accept(id)    // POST: Aceptar tarea sugerida
- reject(id)    // POST: Rechazar tarea sugerida
```

## 🚀 Uso en el Código

### Importación
```dart
import '../config/api_config.dart';
import 'endpoints/endpoints.dart';
```

### Ejemplo de Uso
```dart
// Antes
final response = await http.get(
  Uri.parse('https://agro-ai-plataform-1.onrender.com/api/parcelas/'),
  headers: {'Authorization': 'Token $token'},
);

// Ahora
final response = await http.get(
  Uri.parse(ParcelaEndpoints.list),
  headers: ApiConfig.authHeaders(token),
);
```

## ✅ Ventajas de esta Estructura

1. **Centralización**: Todos los endpoints están en un solo lugar
2. **Mantenibilidad**: Fácil de actualizar URLs sin tocar lógica de negocio
3. **Type Safety**: Menos errores de tipeo en URLs
4. **Reutilización**: Headers y configuración compartidos
5. **Escalabilidad**: Fácil agregar nuevos endpoints
6. **Claridad**: Endpoints organizados por funcionalidad

## 🔄 Migración desde Código Antiguo

Si estás actualizando código que usa URLs hardcodeadas:

1. Importa los endpoints necesarios
2. Reemplaza URLs literales con la clase de endpoints correspondiente
3. Usa `ApiConfig.authHeaders(token)` para headers autenticados
4. Usa `ApiConfig.defaultHeaders` para headers sin autenticación

## 📝 Agregar Nuevos Endpoints

1. Crear archivo en `lib/services/endpoints/` si es un nuevo módulo
2. Definir la clase con métodos estáticos
3. Exportar en `endpoints.dart`
4. Usar en `api_service.dart` o directamente en widgets

Ejemplo:
```dart
// lib/services/endpoints/nuevo_modulo_endpoints.dart
import '../../config/api_config.dart';

class NuevoModuloEndpoints {
  static String get list => '${ApiConfig.baseUrl}/api/nuevo-modulo/';
  static String detail(int id) => '${ApiConfig.baseUrl}/api/nuevo-modulo/$id/';
}
```

