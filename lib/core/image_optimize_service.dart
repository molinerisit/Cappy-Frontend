import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageOptimizeService {
  static const String _cloudinaryHost = 'res.cloudinary.com';
  static const int _maxPrewarmUrls = 4;
  static final Map<String, DateTime> _recentPrewarm = <String, DateTime>{};

  static String optimizeUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;

    Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (_) {
      return trimmed;
    }

    if (uri.host.toLowerCase() != _cloudinaryHost) {
      return trimmed;
    }

    final segments = List<String>.from(uri.pathSegments);
    final uploadIndex = segments.indexOf('upload');
    if (uploadIndex < 0) {
      return trimmed;
    }

    final transformIndex = uploadIndex + 1;
    const requiredTokens = <String>['f_auto', 'q_auto'];

    if (segments.length <= transformIndex) {
      segments.add(requiredTokens.join(','));
      return uri.replace(pathSegments: segments).toString();
    }

    final nextSegment = segments[transformIndex];

    if (_isVersionSegment(nextSegment)) {
      segments.insert(transformIndex, requiredTokens.join(','));
      return uri.replace(pathSegments: segments).toString();
    }

    if (_isTransformationSegment(nextSegment)) {
      final tokens = nextSegment.split(',').where((t) => t.isNotEmpty).toList();
      final hasFAuto = tokens.any((t) => t == 'f_auto');
      final hasQAuto = tokens.any(
        (t) => t == 'q_auto' || t.startsWith('q_auto:'),
      );

      if (!hasFAuto) tokens.add('f_auto');
      if (!hasQAuto) tokens.add('q_auto');

      segments[transformIndex] = tokens.join(',');
      return uri.replace(pathSegments: segments).toString();
    }

    segments.insert(transformIndex, requiredTokens.join(','));
    return uri.replace(pathSegments: segments).toString();
  }

  static Future<void> prewarmRouteImages({
    required BuildContext context,
    required String routeName,
    Object? arguments,
  }) async {
    final routeUrls = _collectRouteUrls(routeName, arguments)
        .map(optimizeUrl)
        .where((url) => url.isNotEmpty)
        .take(_maxPrewarmUrls)
        .toList(growable: false);

    if (routeUrls.isEmpty) return;

    final cacheKey = '$routeName|${routeUrls.join('|')}';
    final now = DateTime.now();
    final last = _recentPrewarm[cacheKey];
    if (last != null && now.difference(last).inSeconds < 45) {
      return;
    }
    _recentPrewarm[cacheKey] = now;

    await Future.wait(
      routeUrls.map((url) async {
        try {
          await precacheImage(CachedNetworkImageProvider(url), context);
        } catch (_) {}
      }),
    );
  }

  static List<String> _collectRouteUrls(String routeName, Object? arguments) {
    final urls = <String>{};

    if (arguments is Map) {
      final prewarmUrls = arguments['prewarmUrls'];
      if (prewarmUrls is Iterable) {
        for (final value in prewarmUrls) {
          if (value is String && _isHttpUrl(value)) {
            urls.add(value.trim());
          }
        }
      }
    }

    _collectUrlsRecursive(arguments, urls);

    // Fallback visual assets for key flows.
    if (routeName.startsWith('/experience/country/')) {
      urls.addAll(const <String>[]);
    }

    if (routeName.startsWith('/experience/recipe/')) {
      urls.addAll(const <String>[]);
    }

    return urls.toList(growable: false);
  }

  static void _collectUrlsRecursive(Object? value, Set<String> output) {
    if (value == null) return;

    if (value is String) {
      final candidate = value.trim();
      if (_isHttpUrl(candidate)) {
        output.add(candidate);
      }
      return;
    }

    if (value is Iterable) {
      for (final item in value) {
        _collectUrlsRecursive(item, output);
      }
      return;
    }

    if (value is Map) {
      value.forEach((key, nested) {
        final normalizedKey = key.toString().toLowerCase();
        if (nested is String) {
          final candidate = nested.trim();
          if ((normalizedKey.contains('image') ||
                  normalizedKey.endsWith('url') ||
                  normalizedKey.contains('avatar')) &&
              _isHttpUrl(candidate)) {
            output.add(candidate);
          }
        }
        _collectUrlsRecursive(nested, output);
      });
    }
  }

  static bool _isHttpUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static bool _isVersionSegment(String value) {
    return RegExp(r'^v\d+$').hasMatch(value);
  }

  static bool _isTransformationSegment(String value) {
    if (value.contains('.')) return false;

    final tokens = value.split(',').where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return false;

    return tokens.every((token) {
      final separator = token.indexOf('_');
      if (separator <= 0 || separator > 4) return false;
      final key = token.substring(0, separator);
      return RegExp(r'^[a-z]{1,4}$').hasMatch(key);
    });
  }
}
