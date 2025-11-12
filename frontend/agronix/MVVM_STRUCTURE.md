# Estructura MVVM - Agronix App

## 📁 Arquitectura del Proyecto

```
lib/
├── core/                       # Núcleo de la aplicación
│   ├── constants/             # Constantes globales
│   ├── routes/                # Rutas de navegación
│   ├── theme/                 # Temas y estilos
│   └── utils/                 # Utilidades generales
│
├── data/                      # Capa de Datos
│   ├── models/                # Modelos de datos
│   ├── repositories/          # Implementaciones de repositorios
│   └── data_sources/          # Fuentes de datos (API, local)
│       ├── remote/            # API calls
│       └── local/             # SharedPreferences, SQLite
│
├── domain/                    # Lógica de Negocio
│   ├── entities/              # Entidades del dominio
│   ├── repositories/          # Interfaces de repositorios
│   └── use_cases/             # Casos de uso
│
├── presentation/              # Capa de Presentación
│   ├── view_models/           # ViewModels (estado + lógica)
│   ├── views/                 # Pantallas (UI)
│   │   ├── auth/              # Autenticación
│   │   ├── dashboard/         # Dashboard
│   │   ├── parcelas/          # Parcelas
│   │   ├── calendar/          # Calendario
│   │   ├── chatbot/           # Chatbot
│   │   └── profile/           # Perfil
│   └── widgets/               # Widgets reutilizables
│
└── main.dart                  # Punto de entrada
```

## 🎯 Patrón MVVM

### Model (Modelo)
- **Ubicación**: `data/models/` y `domain/entities/`
- **Responsabilidad**: Representa los datos y la lógica de negocio
- **Ejemplo**: `UserModel`, `ParcelaModel`, `SensorDataModel`

### View (Vista)
- **Ubicación**: `presentation/views/`
- **Responsabilidad**: Presenta la UI y captura eventos del usuario
- **Ejemplo**: `LoginView`, `DashboardView`, `ParcelasView`

### ViewModel (ViewModel)
- **Ubicación**: `presentation/view_models/`
- **Responsabilidad**: Maneja el estado y la lógica de presentación
- **Ejemplo**: `AuthViewModel`, `DashboardViewModel`, `ParcelasViewModel`

## 🔄 Flujo de Datos

```
View → ViewModel → Repository → DataSource → API
  ↑         ↓           ↓            ↓
  └─────────┴───────────┴────────────┘
        (Estado Observable)
```
