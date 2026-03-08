import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import '../core/api_service.dart';
import '../providers/auth_provider.dart';

/// Widget profesional para subir y gestionar imágenes
/// Soporta: selección, crop, upload, preview y URL manual
class ImageUploadField extends StatefulWidget {
  final String? initialUrl;
  final Map<String, dynamic>? initialAdjustments;
  final String label;
  final Function(String? url) onImageChanged;
  final Function(Map<String, dynamic>)? onAdjustmentsChanged;
  final double aspectRatio;
  final int maxWidth;
  final int maxHeight;
  final bool required;
  final String? helperText;

  const ImageUploadField({
    super.key,
    this.initialUrl,
    this.initialAdjustments,
    this.label = 'Imagen',
    required this.onImageChanged,
    this.onAdjustmentsChanged,
    this.aspectRatio = 1.0,
    this.maxWidth = 1200,
    this.maxHeight = 1200,
    this.required = false,
    this.helperText,
  });

  @override
  State<ImageUploadField> createState() => _ImageUploadFieldState();
}

class _ImageUploadFieldState extends State<ImageUploadField> {
  static const String _legacyTokenKey = 'auth_token';
  static const String _currentTokenKey = 'cooklevel_jwt';

  String? _imageUrl;
  bool _isUploading = false;
  bool _useManualUrl = false;
  String _fitMode = 'cover';
  double _zoom = 1.0;
  double _offsetX = 0.0;
  double _offsetY = 0.0;
  final TextEditingController _urlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const List<String> _fitModes = [
    'cover',
    'contain',
    'fill',
    'fitWidth',
    'fitHeight',
  ];

  static Map<String, dynamic> _defaultAdjustments() {
    return {'fit': 'cover', 'zoom': 1.0, 'offsetX': 0.0, 'offsetY': 0.0};
  }

  static Map<String, dynamic> _sanitizeAdjustments(dynamic raw) {
    final defaults = _defaultAdjustments();
    if (raw is! Map) {
      return defaults;
    }

    final fit = raw['fit']?.toString() ?? 'cover';
    final zoomRaw = raw['zoom'];
    final offsetXRaw = raw['offsetX'];
    final offsetYRaw = raw['offsetY'];

    final zoom = zoomRaw is num
        ? zoomRaw.toDouble().clamp(1.0, 2.5)
        : double.tryParse('$zoomRaw')?.clamp(1.0, 2.5) ?? 1.0;
    final offsetX = offsetXRaw is num
        ? offsetXRaw.toDouble().clamp(-1.0, 1.0)
        : double.tryParse('$offsetXRaw')?.clamp(-1.0, 1.0) ?? 0.0;
    final offsetY = offsetYRaw is num
        ? offsetYRaw.toDouble().clamp(-1.0, 1.0)
        : double.tryParse('$offsetYRaw')?.clamp(-1.0, 1.0) ?? 0.0;

    return {
      'fit': _fitModes.contains(fit) ? fit : 'cover',
      'zoom': zoom,
      'offsetX': offsetX,
      'offsetY': offsetY,
    };
  }

  Map<String, dynamic> _currentAdjustments() {
    return {
      'fit': _fitMode,
      'zoom': _zoom,
      'offsetX': _offsetX,
      'offsetY': _offsetY,
    };
  }

  void _emitAdjustmentsChanged() {
    widget.onAdjustmentsChanged?.call(_currentAdjustments());
  }

  BoxFit _boxFitFromMode(String mode) {
    switch (mode) {
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'cover':
      default:
        return BoxFit.cover;
    }
  }

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialUrl;
    _urlController.text = widget.initialUrl ?? '';

    final adjustments = _sanitizeAdjustments(widget.initialAdjustments);
    _fitMode = adjustments['fit'] as String;
    _zoom = adjustments['zoom'] as double;
    _offsetX = adjustments['offsetX'] as double;
    _offsetY = adjustments['offsetY'] as double;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: widget.maxWidth.toDouble(),
        maxHeight: widget.maxHeight.toDouble(),
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Crop image
      final croppedFile = await _cropImage(pickedFile.path);
      if (croppedFile == null) return;

      // Upload to server
      await _uploadImage(File(croppedFile.path));
    } catch (e) {
      _showError('Error al seleccionar imagen: $e');
    }
  }

  Future<CroppedFile?> _cropImage(String imagePath) async {
    try {
      return await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: CropAspectRatio(ratioX: widget.aspectRatio, ratioY: 1.0),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Ajustar Imagen',
            toolbarColor: Colors.blue.shade600,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            hideBottomControls: false,
          ),
          IOSUiSettings(title: 'Ajustar Imagen', aspectRatioLockEnabled: false),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 520, height: 520),
          ),
        ],
      );
    } catch (e) {
      _showError('Error al recortar imagen: $e');
      return null;
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    setState(() => _isUploading = true);

    try {
      final token = await _resolveAuthToken();
      if (token == null || token.isEmpty) {
        _showError('No hay sesión activa');
        return;
      }

      final dio = Dio();
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      final response = await dio.post(
        'http://192.168.100.4:3000/api/admin/v2/upload/image',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
        onSendProgress: (sent, total) {
          // Opcional: mostrar progreso
          final progress = (sent / total * 100).toStringAsFixed(0);
          debugPrint('Upload progress: $progress%');
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final url = response.data['data']['url'];
        setState(() {
          _imageUrl = url;
          _urlController.text = url;
        });
        widget.onImageChanged(url);
        _showSuccess('Imagen subida exitosamente');
      } else {
        _showError(response.data['message'] ?? 'Error al subir imagen');
      }
    } catch (e) {
      _showError('Error de conexión: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _applyManualUrl() {
    final url = _urlController.text.trim();
    setState(() => _imageUrl = url.isEmpty ? null : url);
    widget.onImageChanged(url.isEmpty ? null : url);
    if (url.isNotEmpty) {
      _showSuccess('URL aplicada correctamente');
    }
  }

  Future<void> _importImageFromUrl() async {
    final sourceUrl = _urlController.text.trim();
    if (sourceUrl.isEmpty) {
      _showError('Ingresa una URL para importar');
      return;
    }

    final parsed = Uri.tryParse(sourceUrl);
    if (parsed == null ||
        !parsed.hasScheme ||
        !(parsed.isScheme('http') || parsed.isScheme('https'))) {
      _showError('URL inválida. Debe iniciar con http:// o https://');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final token = await _resolveAuthToken();
      if (token == null || token.isEmpty) {
        _showError('No hay sesión activa');
        return;
      }

      final dio = Dio();
      final response = await dio.post(
        'http://192.168.100.4:3000/api/admin/v2/upload/image/from-url',
        data: {'url': sourceUrl},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final importedUrl = response.data['data']['url']?.toString();
        if (importedUrl == null || importedUrl.isEmpty) {
          _showError('La respuesta no contiene URL de imagen');
          return;
        }

        setState(() {
          _imageUrl = importedUrl;
          _urlController.text = importedUrl;
        });
        widget.onImageChanged(importedUrl);
        _showSuccess('Imagen importada y subida exitosamente');
      } else {
        _showError(
          response.data['error'] ??
              response.data['message'] ??
              'No se pudo importar la imagen',
        );
      }
    } catch (e) {
      _showError('Error de conexión al importar URL: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<String?> _resolveAuthToken() async {
    final inMemoryToken = ApiService.getToken();
    if (inMemoryToken != null && inMemoryToken.isNotEmpty) {
      return inMemoryToken;
    }

    try {
      final authToken = Provider.of<AuthProvider>(context, listen: false).token;
      if (authToken != null && authToken.isNotEmpty) {
        ApiService.setToken(authToken);
        return authToken;
      }
    } catch (_) {
      // The widget can be used outside Provider scope in isolated contexts.
    }

    final currentToken = await _storage.read(key: _currentTokenKey);
    if (currentToken != null && currentToken.isNotEmpty) {
      ApiService.setToken(currentToken);
      return currentToken;
    }

    final legacyToken = await _storage.read(key: _legacyTokenKey);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      ApiService.setToken(legacyToken);
      return legacyToken;
    }

    final allStoredValues = await _storage.readAll();
    const fallbackKeys = ['token', 'jwt', 'access_token'];
    for (final key in fallbackKeys) {
      final value = allStoredValues[key];
      if (value != null && value.isNotEmpty) {
        ApiService.setToken(value);
        return value;
      }
    }

    return null;
  }

  void _clearImage() {
    setState(() {
      _imageUrl = null;
      _urlController.clear();
    });
    widget.onImageChanged(null);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (widget.required)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 14),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Tab selector
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: 'Subir Imagen',
                  icon: Icons.upload,
                  isSelected: !_useManualUrl,
                  onTap: () => setState(() => _useManualUrl = false),
                ),
              ),
              Expanded(
                child: _TabButton(
                  label: 'URL Externa',
                  icon: Icons.link,
                  isSelected: _useManualUrl,
                  onTap: () => setState(() => _useManualUrl = true),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Content based on selected tab
        if (_useManualUrl) _buildManualUrlInput() else _buildUploadInterface(),

        // Preview
        if (_imageUrl != null && _imageUrl!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildImagePreview(),
        ],

        // Helper text
        if (widget.helperText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.helperText!,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  Widget _buildUploadInterface() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          if (_isUploading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            const Text(
              'Subiendo imagen...',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ] else ...[
            const Icon(Icons.add_photo_alternate, size: 48, color: Colors.blue),
            const SizedBox(height: 12),
            const Text(
              'Selecciona una imagen',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ActionButton(
                  icon: Icons.photo_library,
                  label: 'Galería',
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  icon: Icons.camera_alt,
                  label: 'Cámara',
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManualUrlInput() {
    return Column(
      children: [
        TextField(
          controller: _urlController,
          decoration: InputDecoration(
            labelText: 'URL de la imagen',
            hintText: 'https://ejemplo.com/imagen.jpg',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey.shade50,
            prefixIcon: const Icon(Icons.link),
            suffixIcon: IconButton(
              icon: const Icon(Icons.cloud_upload, color: Colors.blue),
              onPressed: _isUploading ? null : _importImageFromUrl,
              tooltip: 'Importar y subir',
            ),
          ),
          onSubmitted: (_) => _importImageFromUrl(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _importImageFromUrl,
                icon: _isUploading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload, size: 18),
                label: Text(
                  _isUploading
                      ? 'Importando...'
                      : 'Importar y subir al servidor',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _applyManualUrl,
              icon: const Icon(Icons.link, size: 18),
              label: const Text('Usar URL directa'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vista Previa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: _clearImage,
                tooltip: 'Eliminar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 200,
              width: double.infinity,
              color: Colors.black.withValues(alpha: 0.04),
              child: Transform.scale(
                scale: _zoom,
                child: Image.network(
                  _imageUrl!,
                  fit: _boxFitFromMode(_fitMode),
                  alignment: Alignment(_offsetX, _offsetY),
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Error al cargar imagen',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildAdjustmentControls(),
        ],
      ),
    );
  }

  Widget _buildAdjustmentControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _fitMode,
          decoration: const InputDecoration(
            labelText: 'Ajuste de encuadre',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 'cover', child: Text('Cover')),
            DropdownMenuItem(value: 'contain', child: Text('Contain')),
            DropdownMenuItem(value: 'fill', child: Text('Fill')),
            DropdownMenuItem(value: 'fitWidth', child: Text('Fit Width')),
            DropdownMenuItem(value: 'fitHeight', child: Text('Fit Height')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _fitMode = value);
            _emitAdjustmentsChanged();
          },
        ),
        const SizedBox(height: 10),
        Text('Zoom (${_zoom.toStringAsFixed(2)}x)'),
        Slider(
          min: 1.0,
          max: 2.5,
          divisions: 30,
          value: _zoom,
          onChanged: (value) {
            setState(() => _zoom = value);
            _emitAdjustmentsChanged();
          },
        ),
        Text('Desplazamiento horizontal (${_offsetX.toStringAsFixed(2)})'),
        Slider(
          min: -1,
          max: 1,
          divisions: 40,
          value: _offsetX,
          onChanged: (value) {
            setState(() => _offsetX = value);
            _emitAdjustmentsChanged();
          },
        ),
        Text('Desplazamiento vertical (${_offsetY.toStringAsFixed(2)})'),
        Slider(
          min: -1,
          max: 1,
          divisions: 40,
          value: _offsetY,
          onChanged: (value) {
            setState(() => _offsetY = value);
            _emitAdjustmentsChanged();
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              final defaults = _defaultAdjustments();
              setState(() {
                _fitMode = defaults['fit'] as String;
                _zoom = defaults['zoom'] as double;
                _offsetX = defaults['offsetX'] as double;
                _offsetY = defaults['offsetY'] as double;
              });
              _emitAdjustmentsChanged();
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Restablecer'),
          ),
        ),
      ],
    );
  }
}

// Helper widget: Tab button
class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.blue.shade700
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget: Action button
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
