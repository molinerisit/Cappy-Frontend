// cho_assistant.dart
// Cho AI assistant — contextual cooking helper.
// ONLY available inside active recipe screens.
//
// Usage:
//   ChoAssistantButton(
//     recipeId: '...',
//     recipeName: 'Asado',
//     stepIndex: 2,
//     stepDescription: 'Sellá la carne a fuego fuerte',
//     elapsedSeconds: 180,
//   )
//
// Add as floatingActionButton in the recipe Scaffold.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../config/app_config.dart';
import '../../core/api_service.dart';

// ─── Data ──────────────────────────────────────────────────────────────────

class _ChatMessage {
  final bool isUser;
  final String text;
  final bool isLoading;
  _ChatMessage({required this.isUser, required this.text, this.isLoading = false});
}

// ─── Floating button ───────────────────────────────────────────────────────

class ChoAssistantButton extends StatelessWidget {
  final String recipeId;
  final String recipeName;
  final int stepIndex;
  final String stepDescription;
  final int elapsedSeconds;

  const ChoAssistantButton({
    super.key,
    required this.recipeId,
    required this.recipeName,
    required this.stepIndex,
    required this.stepDescription,
    required this.elapsedSeconds,
  });

  void _open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChoModal(
        recipeId: recipeId,
        recipeName: recipeName,
        stepIndex: stepIndex,
        stepDescription: stepDescription,
        elapsedSeconds: elapsedSeconds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Image.asset(
        'assets/Choia.png',
        width: 88,
        height: 88,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.chat_rounded,
          color: Color(0xFF22C55E),
          size: 64,
        ),
      ),
    );
  }
}

// ─── Modal ─────────────────────────────────────────────────────────────────

class _ChoModal extends StatefulWidget {
  final String recipeId;
  final String recipeName;
  final int stepIndex;
  final String stepDescription;
  final int elapsedSeconds;

  const _ChoModal({
    required this.recipeId,
    required this.recipeName,
    required this.stepIndex,
    required this.stepDescription,
    required this.elapsedSeconds,
  });

  @override
  State<_ChoModal> createState() => _ChoModalState();
}

class _ChoModalState extends State<_ChoModal> {
  final _ctrl    = TextEditingController();
  final _scroll  = ScrollController();
  final _picker  = ImagePicker();

  final List<_ChatMessage> _messages = [];
  bool _loading  = false;
  int  _textLeft  = 3;
  int  _imgLeft   = 1;
  File? _pendingImage;

  @override
  void initState() {
    super.initState();
    // Greeting message from Cho
    final greeting = widget.stepDescription.isNotEmpty
        ? 'Estás en "${widget.stepDescription}". ¿Qué querés revisar?'
        : 'Estás cocinando ${widget.recipeName}. ¿En qué te ayudo?';
    _messages.add(_ChatMessage(isUser: false, text: greeting));
    _loadUsage();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadUsage() async {
    try {
      final base = AppConfig.apiBaseUrl;
      final token = ApiService.token;
      final res = await http.get(
        Uri.parse('$base/cho/usage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final remaining = body['data']?['remaining'];
        if (remaining != null && mounted) {
          setState(() {
            _textLeft = (remaining['text'] as num?)?.toInt() ?? _textLeft;
            _imgLeft  = (remaining['images'] as num?)?.toInt() ?? _imgLeft;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    if (_imgLeft <= 0) {
      _addBot('Ya usaste tus análisis de imagen de hoy. ¿Tenés otra pregunta?');
      return;
    }
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (picked != null && mounted) {
      setState(() => _pendingImage = File(picked.path));
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if ((text.isEmpty && _pendingImage == null) || _loading) return;
    if (_textLeft <= 0) {
      _addBot('Llegaste al límite de consultas de hoy. Volvé mañana o pasate a Premium 🌟');
      return;
    }

    final image = _pendingImage;
    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text.isNotEmpty ? text : '📷 [imagen]'));
      _messages.add(_ChatMessage(isUser: false, text: '', isLoading: true));
      _pendingImage = null;
      _loading = true;
      _ctrl.clear();
    });
    _scrollDown();

    try {
      final base  = AppConfig.apiBaseUrl;
      final token = ApiService.token;

      http.Response res;

      if (image != null) {
        // Multipart with optional text
        final request = http.MultipartRequest('POST', Uri.parse('$base/cho/ask'));
        request.headers['Authorization'] = 'Bearer $token';
        request.fields['recipeId']        = widget.recipeId;
        request.fields['recipeName']      = widget.recipeName;
        request.fields['stepIndex']       = widget.stepIndex.toString();
        request.fields['stepDescription'] = widget.stepDescription;
        request.fields['elapsedTime']     = widget.elapsedSeconds.toString();
        request.fields['message']         = text;
        request.files.add(await http.MultipartFile.fromPath('image', image.path));
        final streamed = await request.send().timeout(const Duration(seconds: 30));
        res = await http.Response.fromStream(streamed);
      } else {
        // JSON only
        res = await http.post(
          Uri.parse('$base/cho/ask'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'recipeId':        widget.recipeId,
            'recipeName':      widget.recipeName,
            'stepIndex':       widget.stepIndex,
            'stepDescription': widget.stepDescription,
            'elapsedTime':     widget.elapsedSeconds,
            'message':         text,
          }),
        ).timeout(const Duration(seconds: 30));
      }

      final body = jsonDecode(res.body);

      if (res.statusCode == 200 && body['success'] == true) {
        final response  = body['data']['response'] as String;
        final remaining = body['data']['remaining'];
        setState(() {
          _messages.removeLast(); // remove loading
          _messages.add(_ChatMessage(isUser: false, text: response));
          if (remaining != null) {
            _textLeft = (remaining['text'] as num?)?.toInt() ?? _textLeft;
            _imgLeft  = (remaining['images'] as num?)?.toInt() ?? _imgLeft;
          }
        });
      } else {
        final msg = body['message'] as String? ?? 'Tuve un problema. Intentá de nuevo.';
        _replaceLast(msg);
      }
    } catch (e) {
      _replaceLast('Tuve un problema técnico. Seguí con el paso que tenés en pantalla.');
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollDown();
    }
  }

  void _addBot(String text) {
    setState(() => _messages.add(_ChatMessage(isUser: false, text: text)));
    _scrollDown();
  }

  void _replaceLast(String text) {
    setState(() {
      if (_messages.isNotEmpty && _messages.last.isLoading) {
        _messages.removeLast();
      }
      _messages.add(_ChatMessage(isUser: false, text: text));
    });
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      margin: EdgeInsets.only(bottom: kb),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Image.asset(
                  'assets/Choia.png',
                  width: 44,
                  height: 44,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.chat_rounded,
                    color: Color(0xFF22C55E),
                    size: 36,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cho', style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1E293B),
                      )),
                      Text(
                        widget.recipeName,
                        style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF64748B)),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Usage badges
                _UsageBadge(icon: '💬', count: _textLeft),
                const SizedBox(width: 6),
                _UsageBadge(icon: '📷', count: _imgLeft),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _buildBubble(_messages[i]),
            ),
          ),

          // Pending image preview
          if (_pendingImage != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF7DD3FC)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_pendingImage!, width: 48, height: 48, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Imagen lista para enviar', style: TextStyle(fontSize: 12, color: Color(0xFF0369A1)))),
                  IconButton(
                    onPressed: () => setState(() => _pendingImage = null),
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF0369A1)),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Camera button
                IconButton(
                  onPressed: _loading ? null : _pickImage,
                  icon: Icon(
                    Icons.camera_alt_rounded,
                    color: _imgLeft > 0 ? const Color(0xFF22C55E) : const Color(0xFFCBD5E1),
                    size: 24,
                  ),
                  tooltip: '$_imgLeft imágenes restantes',
                ),

                // Text field
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    enabled: !_loading,
                    maxLines: 3,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Preguntale algo a Cho…',
                      hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),

                // Send button
                GestureDetector(
                  onTap: _loading ? null : _send,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _loading ? const Color(0xFFE2E8F0) : const Color(0xFF22C55E),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF22C55E)))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    if (msg.isLoading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, right: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) => _Dot(delay: i * 200)),
          ),
        ),
      );
    }

    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 10,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF22C55E) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: isUser ? Colors.white : const Color(0xFF1E293B),
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────

class _UsageBadge extends StatelessWidget {
  final String icon;
  final int count;
  const _UsageBadge({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    final empty = count <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: empty ? const Color(0xFFF1F5F9) : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: empty ? const Color(0xFF94A3B8) : const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated typing dot
class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});
  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 8, height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF94A3B8),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
