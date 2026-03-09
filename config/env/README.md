# 🌍 Cappy Flutter App - Environment Configuration
# 
# Esta carpeta contiene la configuración por ambiente.
# Los archivos .env de cada environment NO se commitean a git por seguridad.
#
# Uso:
# - Desarrollo: flutter run --dart-define-from-file=config/env/.env.development
# - Staging: flutter run --dart-define-from-file=config/env/.env.staging  
# - Producción: flutter run --dart-define-from-file=config/env/.env.production

## ✅ Instrucciones:

1. Copia .env.example a .env.development, .env.staging, .env.production
2. Configura las URLs según corresponda
3. Agrégalos a .gitignore (NO commitear credenciales)

## 📝 Variables disponibles:

- API_BASE_URL: URL del servidor API backend
- APP_ENVIRONMENT: 'dev', 'staging', o 'production'
