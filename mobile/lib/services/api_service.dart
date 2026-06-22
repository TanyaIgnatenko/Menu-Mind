import 'dart:io';
import 'package:dio/dio.dart';
import '../models/menu.dart';

const _baseUrl = 'https://me-0413d7154a1b47ee95b74759203fbe89.ecs.eu-central-1.on.aws/api/v1';
const _imageBase = 'https://me-0413d7154a1b47ee95b74759203fbe89.ecs.eu-central-1.on.aws';

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

  Future<Menu> uploadMenu(File imageFile) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: 'menu.jpg',
      ),
    });

    final response = await _dio.post('/menus/', data: formData);

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Menu.fromJson(response.data);
    }
    throw ApiException(_errorMessage(response.data));
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
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
