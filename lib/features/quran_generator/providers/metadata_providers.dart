import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quran_api_service.dart';
import '../data/reciter_service.dart';
import '../domain/reciter.dart';
import '../domain/surah.dart';

final recitersProvider = FutureProvider<List<Reciter>>((ref) async {
  final service = ReciterService();
  return service.fetchReciters();
});

final surahsProvider = FutureProvider<List<Surah>>((ref) async {
  final service = QuranApiService();
  return service.fetchSurahList();
});
