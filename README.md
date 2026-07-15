# Radio Guamá - Flutter App

## Descripción
Aplicación móvil oficial de Radio Guamá para Android/iOS. Consume API REST de WordPress, streams de audio en vivo y podcasts de Ivoox.

## Requisitos Mínimos
- **Android**: 5.1 (API 21)
- **iOS**: 12.0
- **Flutter**: 3.32+
- **Dart**: 3.0+

## Estructura del Proyecto

```
lib/
├── main.dart                    # Punto de entrada
├── app/                         # Configuración de la app
│   ├── providers.dart           # Riverpod providers
│   └── routes.dart              # GoRouter configuration
├── core/                        # Utilidades y constantes
│   ├── constants/               # Constantes de la app
│   ├── network/                 # HTTP client
│   ├── storage/                 # Hive & file cache
│   └── widgets/                 # Widgets reutilizables
├── data/                        # Capa de datos
│   ├── models/                  # Modelos de datos
│   ├── repositories/            # Repositorios
│   └── datasources/             # Fuentes de datos (remote/local)
├── presentation/                # UI layer
│   ├── screens/                 # Pantallas
│   └── widgets/                 # Widgets específicos
└── services/                    # Servicios (audio, background)
```

## Instalación

### 1. Instalar dependencias
```bash
flutter pub get
```

### 2. Generar archivos .g.dart (Hive adapters)
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Configurar assets
Colocar el logo en `assets/images/logo.png`

### 4. Ejecutar la app
```bash
flutter run
```

## Configuración de URLs

Editar `lib/core/constants/env.dart` para configurar las URLs reales de los feeds de Ivoox.

## Características Principales

1. **Noticias (WordPress API)**: Listado por categorías, detalle, comentarios
2. **Audio en Vivo**: Stream persistente con control flotante
3. **Podcasts (Ivoox RSS)**: Reproductor completo con navegación
4. **Offline Support**: Caché de contenido y sincronización en background

## Build de Producción

```bash
# Android APK
flutter build apk --release

# Android App Bundle  
flutter build appbundle --release
```

© Radio Guamá - Todos los derechos reservados.
