import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/reciter.dart';

class ReciterService {
  ReciterService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://everyayah.com/data/';

  Future<List<Reciter>> fetchReciters() async {
    final uri = Uri.parse(_baseUrl);
    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        return _getFallbackReciters();
      }
      final html = utf8.decode(response.bodyBytes);
      final matches = RegExp(r'href="([^"/]+)/"').allMatches(html);
      final excluded = <String>{
        'Parent Directory',
        'images_png',
        'images_jpg',
        'quranpngs',
        'quranpng',
        'QuranText',
        'QuranText_jpg',
        'QuranText_png',
        'translations',
        'timings_files',
        'tools',
        'XML',
        'English',
        'MultiLanguage',
        'audio',
      };

      final reciters = <Reciter>[];
      for (final match in matches) {
        final dirName = match.group(1);
        if (dirName == null) continue;
        if (excluded.contains(dirName)) continue;
        if (dirName.startsWith('.')) continue;
        if (dirName.contains('..')) continue;

        final displayName = _formatName(dirName);
        reciters.add(
          Reciter(
            id: dirName,
            name: displayName,
            directory: dirName,
          ),
        );
      }

      reciters.sort((a, b) => a.name.compareTo(b.name));
      if (reciters.isEmpty) {
        return _getFallbackReciters();
      }
      return reciters;
    } catch (e) {
      return _getFallbackReciters();
    }
  }

  List<Reciter> _getFallbackReciters() {
    return [
      Reciter(
        id: 'Abdul_Basit_Murattal_192kbps',
        name: 'عبد الباسط عبد الصمد (مرتل)',
        directory: 'Abdul_Basit_Murattal_192kbps',
      ),
      Reciter(
        id: 'Abdul_Basit_Mujawwad_128kbps',
        name: 'عبد الباسط عبد الصمد (مجود)',
        directory: 'Abdul_Basit_Mujawwad_128kbps',
      ),
      Reciter(
        id: 'Alafasy_128kbps',
        name: 'مشاري راشد العفاسي',
        directory: 'Alafasy_128kbps',
      ),
      Reciter(
        id: 'Minshawy_Murattal_128kbps',
        name: 'محمد صديق المنشاوي (مرتل)',
        directory: 'Minshawy_Murattal_128kbps',
      ),
      Reciter(
        id: 'Minshawy_Mujawwad_192kbps',
        name: 'محمد صديق المنشاوي (مجود)',
        directory: 'Minshawy_Mujawwad_192kbps',
      ),
      Reciter(
        id: 'Husary_128kbps',
        name: 'محمود خليل الحصري',
        directory: 'Husary_128kbps',
      ),
      Reciter(
        id: 'Abdurrahmaan_As-Sudais_192kbps',
        name: 'عبد الرحمن السديس',
        directory: 'Abdurrahmaan_As-Sudais_192kbps',
      ),
      Reciter(
        id: 'Saood_ash-Shuraym_128kbps',
        name: 'سعود الشريم',
        directory: 'Saood_ash-Shuraym_128kbps',
      ),
      Reciter(
        id: 'Maher_AlMuaiqly_64kbps',
        name: 'ماهر المعيقلي',
        directory: 'Maher_AlMuaiqly_64kbps',
      ),
      Reciter(
        id: 'Abu_Bakr_Ash-Shaatree_128kbps',
        name: 'أبو بكر الشاطري',
        directory: 'Abu_Bakr_Ash-Shaatree_128kbps',
      ),
      Reciter(
        id: 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net',
        name: 'أحمد العجمي',
        directory: 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net',
      ),
      Reciter(
        id: 'Ghamadi_40kbps',
        name: 'سعد الغامدي',
        directory: 'Ghamadi_40kbps',
      ),
      Reciter(
        id: 'custom_audio',
        name: 'رفع ملف صوتي من الجهاز ✨',
        directory: 'custom',
      ),
    ];
  }

  String buildAyahAudioUrl({
    required Reciter reciter,
    required int surahNumber,
    required int ayahNumber,
  }) {
    final surah = surahNumber.toString().padLeft(3, '0');
    final ayah = ayahNumber.toString().padLeft(3, '0');
    final fileName = '$surah$ayah.mp3';
    final encodedDir = Uri.encodeComponent(reciter.directory);
    return '$_baseUrl$encodedDir/$fileName';
  }

  String _formatName(String directory) {
    var name = directory.replaceAll('_', ' ');
    name = name.replaceAll(RegExp(r'\b\d+kbps\b', caseSensitive: false), '');
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    return name;
  }
}
