import 'dart:io';
import 'package:dio/dio.dart';

class VoiceService {
  final Dio _dio = Dio();

  Future<Map<String, dynamic>> sendAudio(String path) async {
    FormData data = FormData.fromMap({
      "file": await MultipartFile.fromFile(path),
    });

    final response = await _dio.post(
      "http://localhost:8000/voice",
      data: data,
    );

    return response.data;
  }
}