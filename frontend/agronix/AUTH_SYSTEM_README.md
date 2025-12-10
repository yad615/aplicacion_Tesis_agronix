# 🔐 Sistema de Autenticación - SOLO AGRICULTORES

## ⚠️ IMPORTANTE
Este sistema **SOLO permite acceso a usuarios con `role="agricultor"`**.  
Los administradores NO pueden usar la app móvil.

---

## 📁 Archivos Creados

### **Modelos**
- `lib/models/user_model.dart` - Modelo de usuario con validación `isAgricultor`

### **Servicios**
- `lib/services/auth_service.dart` - Lógica de autenticación con validación de rol
- `lib/services/endpoints/auth_endpoints.dart` - Endpoints actualizados

### **Pantallas**
- `lib/screens/auth_splash_screen.dart` - Splash con verificación de token y rol
- `lib/screens/auth_login_screen.dart` - Login con validación de agricultor
- `lib/screens/auth_profile_screen.dart` - Perfil (editar datos, foto, contraseña)

### **Configuración**
- `lib/core/routes/app_routes.dart` - Rutas agregadas: `authSplash`, `authLogin`, `authProfile`
- `lib/main.dart` - Rutas registradas

---

## 🚀 Cómo Usar

### **Opción 1: Cambiar pantalla inicial (Recomendado)**

En `lib/main.dart`, cambiar:

```dart
initialRoute: AppRoutes.splash,  // ❌ Sistema anterior
```

Por:

```dart
initialRoute: AppRoutes.authSplash,  // ✅ Sistema con validación de agricultor
```

### **Opción 2: Navegar manualmente**

Desde cualquier pantalla:

```dart
Navigator.pushNamed(context, AppRoutes.authSplash);
```

---

## 🔄 Flujo de Autenticación

```
AuthSplashScreen
  ├─ ¿Hay token guardado?
  │   ├─ NO → AuthLoginScreen
  │   └─ SÍ → Verificar token
  │       ├─ Token válido Y role="agricultor" → HomeScreen
  │       └─ Token inválido O role≠"agricultor" → AuthLoginScreen (limpia sesión)
  │
AuthLoginScreen
  ├─ Usuario ingresa credenciales
  ├─ Validar credenciales en backend
  ├─ ¿role == "agricultor"?
  │   ├─ SÍ → Guardar token + userData → HomeScreen
  │   └─ NO → Mostrar error "Acceso Denegado" (NO guarda nada)
```

---

## 🔒 Validaciones Implementadas

### **1. En el Login (`AuthLoginScreen`)**
```dart
try {
  final authResponse = await AuthService.login(...);
  // ✅ Si llegamos aquí, el usuario ES agricultor
  Navigator.pushReplacement(/* HomeScreen */);
} on AgricultorOnlyException catch (e) {
  // 🚨 Usuario NO es agricultor
  _showErrorDialog('Acceso Denegado', e.message);
}
```

### **2. En el Splash (`AuthSplashScreen`)**
```dart
final isValidAgricultor = await AuthService.verifyTokenAndRole();
if (isValidAgricultor) {
  _navigateToHome(/* con userData actualizado */);
} else {
  _navigateToLogin(); // Sesión inválida o no es agricultor
}
```

### **3. En AuthService**
```dart
// Login
if (!authResponse.user.isAgricultor) {
  throw AgricultorOnlyException('Solo agricultores...');
}

// Verify Token
if (isValid && role != 'agricultor') {
  await clearAuthData(); // Limpia automáticamente
  throw AgricultorOnlyException(...);
}

// Get Profile
if (!user.isAgricultor) {
  await clearAuthData();
  throw AgricultorOnlyException(...);
}
```

---

## 📱 Pantallas Disponibles

### **AuthSplashScreen**
- Verifica token guardado
- Valida que sea agricultor
- Redirige a Login o Home

### **AuthLoginScreen**
- Formulario: Usuario/Email + Contraseña
- Botón para alternar entre usuario y email
- Validación de rol en el frontend
- Muestra error si no es agricultor

### **AuthProfileScreen**
- Ver/editar: nombre, apellido, email, teléfono
- Cambiar foto de perfil (ImagePicker + Cloudinary)
- Cambiar contraseña
- Cerrar sesión

---

## 🛠️ API Endpoints Usados

**Base URL:** `https://api.agronix.lat` ✅

Configurados en `auth_endpoints.dart`:

- `POST /api/auth/login/` - Login
- `POST /api/auth/logout/` - Logout
- `GET /api/auth/verify-token/` - Verificar token
- `GET /api/auth/profile/` - Obtener perfil
- `PATCH /api/auth/profile/` - Actualizar perfil
- `POST /api/auth/change-password/` - Cambiar contraseña
- `POST /api/auth/upload-profile-picture/` - Subir foto

**⚠️ IMPORTANTE:** Todos los endpoints usan `https://api.agronix.lat` (NO IP local)

---

## 💾 Almacenamiento Local

Usa `flutter_secure_storage` para guardar:

```dart
{
  "auth_token": "a1b2c3d4e5f6...",
  "user_data": {
    "id": 15,
    "username": "juan_perez",
    "email": "juan@ejemplo.com",
    "first_name": "Juan",
    "last_name": "Pérez",
    "phone": "987654321",
    "role": "agricultor",  // ⚠️ Siempre verificado
    "profile_picture": "https://...",
    ...
  }
}
```

---

## ✅ Casos de Prueba

### **Caso 1: Usuario Agricultor**
```
1. Login con credenciales de agricultor
2. ✅ Se guarda el token
3. ✅ Navega al HomeScreen
4. ✅ Puede usar todas las funciones
```

### **Caso 2: Usuario Admin/Otro**
```
1. Login con credenciales de admin
2. ❌ Backend responde con role="admin"
3. ❌ Frontend detecta role≠"agricultor"
4. ❌ Muestra error "Acceso Denegado"
5. ❌ NO guarda el token
6. ❌ NO navega al HomeScreen
```

### **Caso 3: Token Expirado**
```
1. Abrir app con token guardado
2. AuthSplashScreen verifica token
3. ❌ Token inválido
4. ✅ Limpia sesión automáticamente
5. ✅ Navega a AuthLoginScreen
```

### **Caso 4: Rol Cambiado**
```
1. Usuario logueado como agricultor
2. Admin cambia su rol a "técnico" en el backend
3. App llama a getProfile()
4. ❌ Detecta role≠"agricultor"
5. ✅ Cierra sesión automáticamente
6. ✅ Navega a AuthLoginScreen
```

---

## 🔧 Métodos Principales de `AuthService`

```dart
// Login con validación de rol
AuthService.login(username: '...', password: '...')

// Verificar token y rol
AuthService.verifyTokenAndRole()

// Obtener perfil actualizado
AuthService.getProfile()

// Actualizar datos de perfil
AuthService.updateProfile(firstName: '...', email: '...')

// Cambiar contraseña
AuthService.changePassword(oldPassword: '...', newPassword: '...', newPassword2: '...')

// Subir foto de perfil
AuthService.uploadProfilePicture(File imageFile)

// Logout
AuthService.logout()

// Verificar si hay sesión activa
AuthService.hasActiveSession()

// Obtener token guardado
AuthService.getToken()

// Obtener datos de usuario guardados
AuthService.getUserData()

// Limpiar toda la sesión
AuthService.clearAuthData()
```

---

## 🚨 Excepciones

### **AgricultorOnlyException**
Lanzada cuando un usuario intenta acceder pero no es agricultor:

```dart
try {
  await AuthService.login(...);
} on AgricultorOnlyException catch (e) {
  print(e.message); // "Esta cuenta no tiene acceso..."
}
```

---

## 📝 Notas Importantes

1. **No hay pantalla de registro** en la app móvil (solo login)
2. **El role NO es editable** por el usuario
3. **La validación de role ocurre en múltiples puntos**:
   - Login
   - Verify token
   - Get profile
   - Splash screen
4. **Si el rol cambia**, la app cierra sesión automáticamente
5. **Token guardado con flutter_secure_storage** (más seguro que SharedPreferences)
6. **Todas las validaciones son case-sensitive**: `"agricultor"` exacto

---

## 🎨 Diseño

- Fondo degradado oscuro (`#1A1A1A` → `#2A2A2A`)
- Color principal: `#4A9B8E` (verde agricultura)
- Animaciones: Fade + Slide
- Inputs con borde al focus
- Botones con estados (loading, disabled)

---

## 🔄 Para Cambiar de Sistema Viejo a Nuevo

En `lib/main.dart`:

```dart
// ANTES
initialRoute: AppRoutes.splash,  // Sistema viejo

// DESPUÉS
initialRoute: AppRoutes.authSplash,  // ✅ Sistema con validación
```

**O eliminar la ruta `/`** en `app_routes.dart` y cambiarla por `/auth-splash`.

---

## 🐛 Debug

Para ver logs de autenticación:

```dart
// En auth_service.dart ya hay prints:
print('📸 Usuario intenta login: $username');
print('✅ Usuario válido y es agricultor');
print('🚨 Usuario NO es agricultor: ${user.role}');
```

Verifica la consola al hacer login/verificar token.

---

## ✅ Checklist de Implementación

- [x] Modelos (UserModel, AuthResponse)
- [x] Endpoints (auth_endpoints.dart)
- [x] AuthService con validación de role
- [x] AuthLoginScreen con validación
- [x] AuthSplashScreen con verificación
- [x] AuthProfileScreen (editar, foto, contraseña)
- [x] Rutas agregadas en app_routes.dart
- [x] Imports en main.dart
- [ ] **Cambiar initialRoute a authSplash** ← **FALTA ESTE PASO**

---

## 🎯 Próximos Pasos

1. Cambiar `initialRoute` en `main.dart` a `AppRoutes.authSplash`
2. Probar login con usuario agricultor
3. Probar login con usuario admin (debe rechazar)
4. Probar edición de perfil
5. Probar cambio de foto
6. Probar cambio de contraseña
7. Probar logout

---

**¿Dudas?** Este sistema está completamente desacoplado del sistema anterior.  
Puedes usar ambos o migrar gradualmente cambiando la ruta inicial.
