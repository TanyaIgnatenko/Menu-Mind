import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../app_version.dart';
import '../models/menu.dart';

const _baseUrl = 'https://menu-mind-production-559d.up.railway.app/api/v1';
const _imageBase = 'https://menu-mind-production-559d.up.railway.app';

class ApiService {
  final _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  String imageUrl(String relativePath) {
    if (relativePath.startsWith('http')) return relativePath;
    return '$_imageBase$relativePath';
  }

  Future<Menu> uploadMenu(File imageFile, {String? deviceId}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'menu.jpg',
      ),
    });

    Response response;
    try {
      response = await _dio.post(
        '/menus/',
        data: formData,
        // OCR + translation can take a while for big menus — give it room, and
        // allow a slow upload of the photo on poor connections.
        options: Options(
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 3),
          // Forward the anonymous analytics id so the backend's scan events
          // attribute to the same person (scans-per-user).
          headers: deviceId != null ? {'X-Device-Id': deviceId} : null,
        ),
      );
    } on DioException catch (e) {
      debugPrint('[uploadMenu] DioException: type=${e.type} '
          'status=${e.response?.statusCode} data=${e.response?.data}');
      throw ApiException(_friendlyError(e));
    }

    if (response.statusCode == 201 || response.statusCode == 200) {
      try {
        return Menu.fromJson(response.data);
      } catch (e) {
        debugPrint('[uploadMenu] parse error: $e | data=${response.data}');
        throw ApiException('Got an unexpected response from the server.');
      }
    }
    debugPrint('[uploadMenu] unexpected status=${response.statusCode} '
        'data=${response.data}');
    throw ApiException(_errorMessage(response.data));
  }

  /// Submit in-app feedback. The backend emails it to the support inbox, with
  /// any [attachmentPaths] (screenshots) attached to the message.
  Future<void> submitFeedback({
    required String message,
    required String replyTo,
    List<String> attachmentPaths = const [],
    String? deviceId,
  }) async {
    final formData = FormData.fromMap({
      'message': message,
      'reply_to': replyTo,
      'platform': 'mobile',
      'app_version': kAppVersion,
      // Multiple parts share the field name 'attachments' → FastAPI collects
      // them into a list[UploadFile].
      'attachments': [
        for (final path in attachmentPaths)
          await MultipartFile.fromFile(
            path,
            filename: path.split(Platform.pathSeparator).last,
            contentType: _imageMediaType(path),
          ),
      ],
    });

    try {
      await _dio.post(
        '/feedback',
        data: formData,
        options: Options(
          sendTimeout: const Duration(minutes: 1),
          headers: deviceId != null ? {'X-Device-Id': deviceId} : null,
        ),
      );
    } on DioException catch (e) {
      debugPrint('[submitFeedback] DioException: type=${e.type} '
          'status=${e.response?.statusCode} data=${e.response?.data}');
      throw ApiException(_friendlyError(e));
    }
  }

  /// Best-effort image content type from a file extension, so the email
  /// attaches the screenshot with a sensible MIME type.
  DioMediaType? _imageMediaType(String path) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return DioMediaType('image', 'png');
    if (p.endsWith('.webp')) return DioMediaType('image', 'webp');
    if (p.endsWith('.heic')) return DioMediaType('image', 'heic');
    if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return DioMediaType('image', 'jpeg');
    return null;
  }

  Future<Menu> getMenu(String menuId) async {
    final response = await _dio.get('/menus/$menuId');
    if (response.statusCode == 200) {
      return Menu.fromJson(response.data);
    }
    throw ApiException('Menu not found');
  }

  String _errorMessage(dynamic data) {
    if (data is Map) return data['message'] ?? 'Unknown error';
    return 'Request failed';
  }

  /// Turns a raw DioException into a short, user-facing message.
  String _friendlyError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Processing took too long. Please try again.';
      case DioExceptionType.connectionError:
        return 'No connection. Check your internet and try again.';
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          return data['message'].toString();
        }
        if (data is Map && data['detail'] != null) {
          return data['detail'].toString();
        }
        final code = e.response?.statusCode;
        return 'Server error${code != null ? ' ($code)' : ''}. Please try again.';
      default:
        return 'Could not process the menu. Please try again.';
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
