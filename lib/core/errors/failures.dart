// lib/core/errors/failures.dart

import 'package:equatable/equatable.dart';

/// Clase base abstracta para los fallos de la aplicación
/// Usamos Equatable para facilitar la comparación de fallos
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// Failures de Configuración
// ============================================================================

/// Fallo al cargar o procesar la configuración local
class CacheFailure extends Failure {
  const CacheFailure([String message = 'Error al cargar configuración local'])
      : super(message);
}

// ============================================================================
// Failures de Red y Conectividad
// ============================================================================

/// Fallo de conexión a internet
class NetworkFailure extends Failure {
  const NetworkFailure(
      [String message = 'Error de conexión. Verifica tu internet'])
      : super(message);
}

/// Fallo en comunicación con el servidor
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Error en el servidor'])
      : super(message);
}

// ============================================================================
// Failures de Almacenamiento (AWS S3)
// ============================================================================

/// Fallo al subir o gestionar archivos en almacenamiento
class StorageFailure extends Failure {
  const StorageFailure([String message = 'Error al subir archivos'])
      : super(message);
}

// ============================================================================
// Failures de Validación
// ============================================================================

/// Fallo de validación de datos del formulario
class ValidationFailure extends Failure {
  const ValidationFailure([String message = 'Datos inválidos'])
      : super(message);
}

// ============================================================================
// Failures de Archivos
// ============================================================================

/// Fallo al procesar archivos locales
class FileFailure extends Failure {
  const FileFailure([String message = 'Error al procesar el archivo'])
      : super(message);
}

// ============================================================================
// Failures Generales
// ============================================================================

/// Fallo inesperado que no encaja en otras categorías
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([String message = 'Error inesperado'])
      : super(message);
}

// Fallo de permisos
class PermissionFailure extends Failure {
  const PermissionFailure([String message = 'Permisos insuficientes'])
      : super(message);
}
