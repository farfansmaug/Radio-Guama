# iOS Platform Folder

Esta carpeta contiene la configuración específica para iOS del proyecto Radio Guamá.

## Estructura Esperada

Cuando Flutter esté instalado y se ejecute `flutter create --platforms=ios .`, se generarán los siguientes archivos:

```
ios/
├── Runner/
│   ├── AppDelegate.swift
│   ├── Info.plist
│   ├── Assets.xcassets/
│   └── Base.lproj/
│       ├── LaunchScreen.storyboard
│       └── Main.storyboard
├── Runner.xcodeproj/
├── Runner.xcworkspace/
├── Podfile
└── Flutter/
    └── AppFrameworkInfo.plist
```

## Requisitos Previos

- macOS con Xcode instalado (versión 14.0 o superior recomendada)
- CocoaPods instalado: `sudo gem install cocoapods`
- Flutter SDK instalado

## Configuración Posterior

Después de generar la carpeta iOS:

1. Instalar pods:
   ```bash
   cd ios
   pod install
   ```

2. Configurar permisos en `Info.plist`:
   - Background audio
   - Internet access

3. Abrir en Xcode:
   ```bash
   open Runner.xcworkspace
   ```

## Notas Importantes

⚠️ **Flutter no está instalado en este entorno**. Para generar completamente la carpeta iOS:

1. Instala Flutter SDK siguiendo la guía oficial: https://docs.flutter.dev/get-started/install
2. Ejecuta: `flutter create --platforms=ios .`
3. Ejecuta: `cd ios && pod install`

La carpeta `ios/` fue creada como directorio vacío. Necesitas Flutter para generar los archivos de configuración completos.
