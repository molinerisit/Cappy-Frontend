import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';

import '../core/api_service.dart';
import '../providers/auth_provider.dart';

class VideoUploadField extends StatefulWidget {
  final String? initialUrl;
  final String label;
  final Function(String? url) onVideoChanged;
  final bool required;
  final String? helperText;
  final int maxSizeMb;

  const VideoUploadField({
    super.key,
    this.initialUrl,
    this.label = 'Video',
    required this.onVideoChanged,
    this.required = false,
    this.helperText,
    this.maxSizeMb = 100,
  });

  @override
  State<VideoUploadField> createState() => _VideoUploadFieldState();
}

class _VideoUploadFieldState extends State<VideoUploadField> {
  static const String _legacyTokenKey = 'auth_token';
  static const String _currentTokenKey = 'cooklevel_jwt';

  String? _videoUrl;
  bool _isUploading = false;
  bool _useManualUrl = false;
  final TextEditingController _urlController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _videoUrl = widget.initialUrl;
    _urlController.text = widget.initialUrl ?? '';
  }

  @override
  void didUpdateWidget(covariant VideoUploadField oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldUrl = oldWidget.initialUrl?.trim() ?? '';
    final newUrl = widget.initialUrl?.trim() ?? '';
    if (oldUrl == newUrl) {
      return;
    }

    _videoUrl = newUrl.isEmpty ? null : newUrl;
    if (_urlController.text.trim() != newUrl) {
      _urlController.text = newUrl;
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final picked = result.files.single;
      final filename = picked.name.isNotEmpty
          ? picked.name
          : 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      Uint8List? bytes = picked.bytes;
      if (bytes == null && picked.path != null && picked.path!.isNotEmpty) {
        bytes = await File(picked.path!).readAsBytes();
      }

      if (bytes == null || bytes.isEmpty) {
        _showError('No se pudo leer el archivo de video');
        return;
      }

      final sizeMb = bytes.length / (1024 * 1024);
      if (sizeMb > widget.maxSizeMb) {
        _showError('El archivo excede ${widget.maxSizeMb}MB');
        return;
      }

      final resolvedMimeType =
          lookupMimeType(filename, headerBytes: bytes.take(24).toList()) ??
          'video/mp4';

      if (!resolvedMimeType.toLowerCase().startsWith('video/')) {
        _showError('El archivo seleccionado no es un video válido');
        return;
      }

      await _uploadVideoBytes(
        bytes,
        filename: filename,
        mimeType: resolvedMimeType,
      );
    } catch (e) {
      _showError('Error al seleccionar video: $e');
    }
  }

  Future<void> _uploadVideoBytes(
    Uint8List videoBytes, {
    required String filename,
    required String mimeType,
  }) async {
    setState(() => _isUploading = true);

    try {
      final token = await _resolveAuthToken();
      if (token == null || token.isEmpty) {
        _showError('No hay sesión activa');
        return;
      }

      final dio = Dio();
      final formData = FormData.fromMap({
        'video': MultipartFile.fromBytes(
          videoBytes,
          filename: filename,
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      final response = await dio.post(
        '${ApiService.baseUrl}/admin/v2/upload/video',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final url = response.data['data']['url']?.toString();
        if (url == null || url.isEmpty) {
          _showError('La respuesta no incluye URL del video');
          return;
        }

        setState(() {
          _videoUrl = url;
          _urlController.text = url;
        });
        widget.onVideoChanged(url);
        _showSuccess('Video subido exitosamente');
      } else {
        _showError(response.data['message'] ?? 'Error al subir video');
      }
    } catch (e) {
      _showError(_extractUploadErrorMessage(e));
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
      // This widget can be mounted outside provider scope.
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

  String _extractUploadErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final directError = data['error'];
        if (directError is String && directError.trim().isNotEmpty) {
          return directError;
        }
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }

      final status = error.response?.statusCode;
      if (status != null) {
        return 'Error del servidor ($status) al subir video';
      }
    }

    return 'Error de conexión al subir video: $error';
  }

  void _applyManualUrl() {
    final url = _urlController.text.trim();
    setState(() => _videoUrl = url.isEmpty ? null : url);
    widget.onVideoChanged(url.isEmpty ? null : url);

    if (url.isNotEmpty) {
      _showSuccess('URL aplicada correctamente');
    }
  }

  void _syncManualUrlWithoutFeedback(String value) {
    final normalized = value.trim();
    setState(() => _videoUrl = normalized.isEmpty ? null : normalized);
    widget.onVideoChanged(normalized.isEmpty ? null : normalized);
  }

  void _clearVideo() {
    setState(() {
      _videoUrl = null;
      _urlController.clear();
    });
    widget.onVideoChanged(null);
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
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: _TabButton(
                  label: 'Subir Video',
                  icon: Icons.upload,
                  isSelected: !_useManualUrl,
                  onTap: () => setState(() => _useManualUrl = false),
                ),
              ),
              Expanded(
                child: _TabButton(
                  label: 'URL Directa',
                  icon: Icons.link,
                  isSelected: _useManualUrl,
                  onTap: () => setState(() => _useManualUrl = true),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_useManualUrl) _buildManualUrlInput() else _buildUploadInterface(),
        if (_videoUrl != null && _videoUrl!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildVideoPreview(),
        ],
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
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          if (_isUploading) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            const Text(
              'Subiendo video...',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ] else ...[
            const Icon(Icons.video_library, size: 48, color: Colors.green),
            const SizedBox(height: 12),
            const Text(
              'Selecciona un video desde tu PC',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _ActionButton(
              icon: Icons.folder_open,
              label: 'Elegir archivo',
              onPressed: _pickAndUploadVideo,
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
            labelText: 'URL del video',
            hintText: 'https://.../video.mp4',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey.shade50,
            prefixIcon: const Icon(Icons.link),
          ),
          onChanged: _syncManualUrlWithoutFeedback,
          onSubmitted: (_) => _applyManualUrl(),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: _applyManualUrl,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Usar URL'),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _videoUrl!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: _clearVideo,
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }
}

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
                color: isSelected
                    ? Colors.green.shade700
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.green.shade700
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
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
