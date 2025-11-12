# Guía de Implementación MVVM - Agronix App

## 📚 Estructura Creada

### ✅ Core (Núcleo)
- `core/constants/` - Constantes globales (app_constants, app_colors)
- `core/routes/` - Rutas de navegación
- `core/theme/` - Tema de la aplicación (light & dark)
- `core/utils/` - Utilidades (validators, date_formatter)

### ✅ Domain (Dominio)
- `domain/entities/` - Entidades puras (User, Parcela, SensorData, Task, Alert)
- `domain/repositories/` - Interfaces de repositorios

### ✅ Data (Datos)
- `data/models/` - Modelos con serialización JSON
- `data/data_sources/local/` - Storage local (SharedPreferences)
- `data/data_sources/remote/` - Cliente API
- `data/repositories/` - Implementaciones de repositorios

### ✅ Presentation (Presentación)
- `presentation/view_models/` - ViewModels con ChangeNotifier
- `presentation/views/` - Carpetas por módulo (auth, dashboard, etc.)
- `presentation/widgets/common/` - Widgets reutilizables

## 🚀 Próximos Pasos

### 1. Instalar Dependencia Provider
```yaml
# pubspec.yaml
dependencies:
  provider: ^6.1.1  # Para gestión de estado
```

### 2. Implementar Repositorios
Crear implementaciones en `data/repositories/`:
- `auth_repository_impl.dart`
- `parcela_repository_impl.dart`
- `sensor_repository_impl.dart`
- etc.

### 3. Migrar Screens a Views
Mover las pantallas existentes de `screens/` a `presentation/views/`:
```
screens/login_screen.dart → presentation/views/auth/login_view.dart
screens/dashboard_screen.dart → presentation/views/dashboard/dashboard_view.dart
screens/parcelas_screen.dart → presentation/views/parcelas/parcelas_view.dart
...
```

### 4. Crear ViewModels
Para cada vista principal, crear su ViewModel:
- `auth_view_model.dart` ✅ (Ya creado)
- `dashboard_view_model.dart`
- `parcelas_view_model.dart`
- `calendar_view_model.dart`
- `chatbot_view_model.dart`
- etc.

### 5. Configurar Provider en main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar LocalStorage
  await LocalStorage().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(AuthRepositoryImpl()),
        ),
        // Agregar más providers aquí
      ],
      child: const AgroNixApp(),
    ),
  );
}
```

### 6. Usar ViewModels en las Views
```dart
class LoginView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    
    return Scaffold(
      body: authViewModel.isLoading
          ? CircularProgressIndicator()
          : LoginForm(
              onSubmit: (username, password) {
                authViewModel.login(username, password);
              },
            ),
    );
  }
}
```

## 📝 Patrón de Código

### Entidad (Domain)
```dart
class UserEntity {
  final int id;
  final String username;
  // Solo propiedades y getters computados
}
```

### Modelo (Data)
```dart
class UserModel extends UserEntity {
  UserModel({required super.id, required super.username});
  
  factory UserModel.fromJson(Map<String, dynamic> json) { }
  Map<String, dynamic> toJson() { }
}
```

### Repository Interface (Domain)
```dart
abstract class AuthRepository {
  Future<UserEntity> login(String username, String password);
}
```

### Repository Implementation (Data)
```dart
class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;
  
  @override
  Future<UserEntity> login(String username, String password) async {
    final response = await _apiClient.post('/auth/login/', {
      'username': username,
      'password': password,
    });
    return UserModel.fromJson(response);
  }
}
```

### ViewModel (Presentation)
```dart
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  
  AuthState _state = AuthState.initial;
  AuthState get state => _state;
  
  Future<void> login(String username, String password) async {
    _state = AuthState.loading;
    notifyListeners();
    
    try {
      await _repository.login(username, password);
      _state = AuthState.authenticated;
    } catch (e) {
      _state = AuthState.error;
    }
    notifyListeners();
  }
}
```

### View (Presentation)
```dart
class LoginView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          body: // UI basada en viewModel.state
        );
      },
    );
  }
}
```

## 🎯 Ventajas de Esta Arquitectura

1. **Separación de Responsabilidades**: Cada capa tiene un propósito específico
2. **Testeable**: Fácil crear tests unitarios para cada capa
3. **Escalable**: Agregar nuevas features es sencillo
4. **Mantenible**: Código organizado y fácil de entender
5. **Reutilizable**: Componentes desacoplados y reutilizables
6. **Independencia**: Domain no depende de Flutter ni de implementaciones

## 📦 Flujo de Datos

```
User Action → View → ViewModel → Use Case → Repository → Data Source → API
                ↓         ↓          ↓            ↓            ↓          ↓
              UI ← notify ← return ← return ← return ← return ← JSON
```

## 🔧 Comandos Útiles

```bash
# Instalar dependencias
flutter pub get

# Limpiar build
flutter clean

# Ejecutar app
flutter run

# Generar código (si usas freezed o json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs
```
