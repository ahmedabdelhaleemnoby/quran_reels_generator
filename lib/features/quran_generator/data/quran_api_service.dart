import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/errors/exceptions.dart';
import '../domain/surah.dart';

class QuranApiService {
  QuranApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://api.alquran.cloud/v1';

  Future<List<Surah>> fetchSurahList() async {
    final uri = Uri.parse('$_baseUrl/surah');
    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        throw ProcessingException(
          'Failed to load surah list',
          'Status: ${response.statusCode}',
        );
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = payload['data'] as List<dynamic>;
      return data
          .map(
            (item) => Surah(
              number: item['number'] as int,
              name: item['name'] as String,
              englishName: item['englishName'] as String,
              numberOfAyahs: item['numberOfAyahs'] as int,
            ),
          )
          .toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ProcessingException('Failed to parse surah list', e.toString());
    }
  }

  Future<List<String>> fetchAyahText({
    required int surahNumber,
    required int fromAyah,
    required int toAyah,
  }) async {
    final uri = Uri.parse('$_baseUrl/surah/$surahNumber');
    try {
      final response = await _client.get(uri);
      if (response.statusCode != 200) {
        throw ProcessingException(
          'Failed to load ayah text',
          'Status: ${response.statusCode}',
        );
      }
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = payload['data'] as Map<String, dynamic>;
      final ayahs = data['ayahs'] as List<dynamic>;
      final startIndex = fromAyah - 1;
      final endIndex = toAyah;
      if (startIndex < 0 || endIndex > ayahs.length) {
        throw ProcessingException('Ayah range is out of bounds');
      }
      return ayahs
          .sublist(startIndex, endIndex)
          .map((ayah) => ayah['text'] as String)
          .toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw ProcessingException('Failed to parse ayah text', e.toString());
    }
  }
}
