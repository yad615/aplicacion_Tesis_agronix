# 🏗️ Arquitectura MVVM - Agronix App

## 📁 Estructura Completa del Proyecto

```
lib/
├── core/                                    # ✅ Núcleo de la aplicación
│   ├── constants/
│   │   ├── app_constants.dart              # Constantes globales
│   │   └── app_colors.dart                 # Paleta de colores
│   ├── routes/
│   │   └── app_routes.dart                 # Rutas de navegación
│   ├── theme/
│   │   └── app_theme.dart                  # Temas light/dark
│   └── utils/
│       ├── validators.dart                 # Validaciones de formularios
│       └── date_formatter.dart             # Formateo de fechas
│
├── data/                                    # ✅ Capa de Datos
│   ├── models/                             # Modelos con JSON serialization
│   │   ├── user_model.dart                 # ✅
│   │   ├── parcela_model.dart              # ✅
│   │   └── sensor_data_model.dart          # ✅
│   ├── repositories/                        # Implementaciones
│   │   └── auth_repository_impl.dart       # TODO
│   └── data_sources/
│       ├── remote/
│       │   └── api_client.dart             # ✅ Cliente HTTP
│       └── local/
│           └── local_storage.dart          # ✅ SharedPreferences wrapper
│
├── domain/                                  # ✅ Lógica de Negocio
│   ├── entities/                           # Entidades puras
│   │   ├── user_entity.dart                # ✅
│   │   ├── parcela_entity.dart             # ✅
│   │   ├── sensor_data_entity.dart         # ✅
│   │   ├── task_entity.dart                # ✅
│   │   └── alert_entity.dart               # ✅
│   ├── repositories/                        # Interfaces
│   │   └── auth_repository.dart            # ✅
│   └── use_cases/                          # TODO: Casos de uso
│
├── presentation/                            # ✅ Capa de Presentación
│   ├── view_models/                        # Estado y lógica
│   │   └── auth_view_model.dart            # ✅ Ejemplo completo
│   ├── views/                              # Pantallas organizadas
│   │   ├── auth/                           # Login, Register
│   │   ├── dashboard/                      # Dashboard principal
│   │   ├── parcelas/                       # Gestión de parcelas
│   │   ├── calendar/                       # Calendario de tareas
│   │   ├── chatbot/                        # Asistente IA
│   │   └── profile/                        # Perfil de usuario
│   └── widgets/
│       └── common/                         # Widgets reutilizables
│
├── config/                                  # ✅ Configuración existente
│   └── api_config.dart                     # Config de API
│
├── services/                                # ✅ Servicios existentes
│   ├── api_service.dart                    # Servicio legacy (migrar)
│   └── endpoints/                          # Endpoints organizados
│
├── models/                                  # ⚠️ Legacy (migrar a data/models)
├── screens/                                 # ⚠️ Legacy (migrar a presentation/views)
└── widgets/                                 # ⚠️ Legacy (migrar a presentation/widgets)

```

## 🎯 Estado Actual

### ✅ Completado
- [x] Estructura de carpetas MVVM
- [x] Core: Constants, Routes, Theme, Utils
- [x] Domain: Entities (User, Parcela, SensorData, Task, Alert)
- [x] Domain: Repository Interfaces
- [x] Data: Models con serialización
- [x] Data: ApiClient y LocalStorage
- [x] Presentation: AuthViewModel (ejemplo completo)
- [x] Documentación completa
- [x] Provider agregado a pubspec.yaml

### 🚧 Pendiente
- [ ] Implementar repositorios en `data/repositories/`
- [ ] Migrar screens a `presentation/views/`
- [ ] Crear ViewModels para cada módulo
- [ ] Configurar Provider en main.dart
- [ ] Migrar widgets a `presentation/widgets/common/`
- [ ] Crear use cases en `domain/use_cases/` (opcional)
- [ ] Tests unitarios

## 🚀 Cómo Usar

### 1. Instalar Dependencias
```bash
flutter pub get
```

### 2. Implementar un Repositorio
```dart
// lib/data/repositories/auth_repository_impl.dart
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../data_sources/remote/api_client.dart';
import '../data_sources/local/local_storage.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient = ApiClient();
  final LocalStorage _localStorage = LocalStorage();

  @override
  Future<UserEntity> login(String username, String password) async {
    final response = await _apiClient.post(
      '/auth/login/',
      {'username': username, 'password': password},
      requiresAuth: false,
    );
    
    final token = response['token'];
    await _localStorage.saveToken(token);
    
    final userModel = UserModel.fromJson(response['user']);
    await _localStorage.saveUserData(userModel.toJson());
    
    return userModel;
  }

  // ... otros métodos
}
```

### 3. Configurar Provider
```dart
// lib/main.dart
import 'package:provider/provider.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'presentation/view_models/auth_view_model.dart';
import 'data/data_sources/local/local_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorage().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(AuthRepositoryImpl()),
        ),
        // Más providers aquí
      ],
      child: const AgroNixApp(),
    ),
  );
}
```

### 4. Usar ViewModel en una View
```dart
// lib/presentation/views/auth/login_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/auth_view_model.dart';

class LoginView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authVM, child) {
        if (authVM.isLoading) {
          return Center(child: CircularProgressIndicator());
        }
        
        return Scaffold(
          body: LoginForm(
            onSubmit: (username, password) async {
              try {
                await authVM.login(username, password);
                Navigator.pushReplacementNamed(context, '/dashboard');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(authVM.errorMessage ?? 'Error')),
                );
              }
            },
          ),
        );
      },
    );
  }
}
```

## 📋 Checklist de Migración

### Fase 1: Setup (✅ Completado)
- [x] Crear estructura de carpetas
- [x] Agregar provider a pubspec.yaml
- [x] Crear constantes y utilidades
- [x] Crear entidades del dominio
- [x] Crear modelos de datos
- [x] Crear cliente API y storage local

### Fase 2: Repositorios
- [ ] Implementar AuthRepositoryImpl
- [ ] Implementar ParcelaRepositoryImpl
- [ ] Implementar SensorRepositoryImpl
- [ ] Implementar TaskRepositoryImpl
- [ ] Implementar AlertRepositoryImpl

### Fase 3: ViewModels
- [x] AuthViewModel (ejemplo)
- [ ] DashboardViewModel
- [ ] ParcelasViewModel
- [ ] CalendarViewModel
- [ ] ChatbotViewModel
- [ ] ProfileViewModel

### Fase 4: Views
- [ ] Migrar LoginScreen → LoginView
- [ ] Migrar RegisterScreen → RegisterView
- [ ] Migrar DashboardScreen → DashboardView
- [ ] Migrar ParcelasScreen → ParcelasView
- [ ] Migrar CalendarScreen → CalendarView
- [ ] Migrar ChatbotScreen → ChatbotView
- [ ] Migrar ProfileScreen → ProfileView

### Fase 5: Limpieza
- [ ] Eliminar carpetas legacy (screens/, models/ antiguo)
- [ ] Actualizar imports en toda la app
- [ ] Limpiar código no utilizado
- [ ] Agregar tests

## 🎨 Convenciones de Código

### Naming
- **Entities**: `UserEntity`, `ParcelaEntity`
- **Models**: `UserModel`, `ParcelaModel`
- **ViewModels**: `AuthViewModel`, `DashboardViewModel`
- **Views**: `LoginView`, `DashboardView`
- **Repositories**: `AuthRepository` (interface), `AuthRepositoryImpl` (implementation)

### Estructura de Archivos
- Cada archivo debe tener un propósito único
- Usar snake_case para nombres de archivo
- Usar PascalCase para nombres de clase
- Agrupar por feature, no por tipo

### Estado
- Usar `ChangeNotifier` para ViewModels
- Usar `Consumer` o `Provider.of` en Views
- Mantener el estado lo más local posible
- No poner lógica de negocio en las Views

## 📚 Recursos

- [Provider Documentation](https://pub.dev/packages/provider)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [MVVM Pattern](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel)
- [Flutter Best Practices](https://flutter.dev/docs/development/best-practices)

## 🤝 Contribuir

1. Seguir la estructura MVVM establecida
2. Usar Provider para gestión de estado
3. Mantener separación de responsabilidades
4. Documentar código complejo
5. Agregar tests cuando sea posible

---

**Estado**: 🚧 Estructura base completada - Listo para migración
**Próximo paso**: Implementar AuthRepositoryImpl y configurar Provider
