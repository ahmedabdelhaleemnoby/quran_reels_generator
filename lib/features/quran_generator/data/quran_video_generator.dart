import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../services/storage_service.dart';
import '../domain/filter_theme.dart';
import '../domain/generation_request.dart';
import 'audio_service.dart';
import 'background_service.dart';
import 'quran_api_service.dart';
import 'reciter_service.dart';
import 'text_render_service.dart';
import 'video_render_service.dart';

class QuranVideoGenerator {
  QuranVideoGenerator({
    QuranApiService? quranApi,
    ReciterService? reciterService,
    AudioService? audioService,
    BackgroundService? backgroundService,
    TextRenderService? textRender,
    VideoRenderService? videoRender,
    StorageService? storageService,
  })  : _quranApi = quranApi ?? QuranApiService(),
        _audioService = audioService ?? AudioService(),
        _backgroundService = backgroundService ?? BackgroundService(),
        _textRender = textRender ?? TextRenderService(),
        _videoRender = videoRender ?? VideoRenderService(),
        _storageService = storageService ?? StorageService();

  final QuranApiService _quranApi;
  final AudioService _audioService;
  final BackgroundService _backgroundService;
  final TextRenderService _textRender;
  final VideoRenderService _videoRender;
  final StorageService _storageService;

  static const int targetWidth = AppConstants.videoWidth;
  static const int targetHeight = AppConstants.videoHeight;

  Future<File> generate({
    required GenerationRequest request,
    void Function(double progress, String message)? onProgress,
  }) async {
    _validateRequest(request);

    onProgress?.call(0.05, 'جلب نص الآيات');
    final ayahTexts = await _quranApi.fetchAyahText(
      surahNumber: request.surah.number,
      fromAyah: request.fromAyah,
      toAyah: request.toAyah,
    );

    onProgress?.call(0.2, 'تجهيز المسارات');
    final tempDir = await _storageService.getTempDirectory();
    final outputDir = await _storageService.getOutputDirectory();

    onProgress?.call(0.25, 'تجهيز ملفات الصوت');
    final audioTrack = await _audioService.buildAudioTrack(
      reciter: request.reciter,
      surahNumber: request.surah.number,
      fromAyah: request.fromAyah,
      toAyah: request.toAyah,
      outputDir: tempDir,
      customAudioFile: request.customAudioPath != null ? File(request.customAudioPath!) : null,
      onProgress: (progress) {
        onProgress?.call(0.25 + (progress * 0.35), 'جاري تحميل الصوت...');
      },
    );

    onProgress?.call(0.65, 'تجهيز الخلفية');
    final backgroundFiles = await _resolveBackground(request.filter, tempDir);

    onProgress?.call(0.75, 'تصميم آيات القرآن');
    final textImages = await _textRender.renderAyahImages(
      ayahs: ayahTexts,
      filter: request.filter,
      surahName: request.surah.name,
      fromAyah: request.fromAyah,
      outputDir: tempDir,
      width: targetWidth,
      height: targetHeight,
    );

    onProgress?.call(0.85, 'توليد الفيديو النهائي');
    final videoFile = await _videoRender.renderVideo(
      filter: request.filter,
      audioFile: audioTrack.file,
      textImages: textImages,
      durations: audioTrack.ayahDurations,
      outputDir: outputDir,
      backgroundFiles: backgroundFiles,
      width: targetWidth,
      height: targetHeight,
    );

    onProgress?.call(1.0, 'اكتمل التوليد');
    return videoFile;
  }

  void _validateRequest(GenerationRequest request) {
    if (request.fromAyah < 1 ||
        request.toAyah < request.fromAyah ||
        request.toAyah > request.surah.numberOfAyahs) {
      throw ProcessingException('نطاق الآيات غير صحيح');
    }
  }

  Future<List<File>?> _resolveBackground(FilterTheme filter, Directory tempDir) async {
    if (filter.backgroundType == BackgroundType.solidColor) {
      return null;
    }

    if (filter.backgroundType == BackgroundType.gradientImage) {
      final file = await _backgroundService.createGradientBackground(
        outputDir: tempDir,
        width: targetWidth,
        height: targetHeight,
        colors: filter.gradientColors ?? [Colors.black, Colors.blueGrey],
      );
      return [file];
    }

    if (filter.backgroundType == BackgroundType.imageFile ||
        filter.backgroundType == BackgroundType.videoFile) {
      if (filter.backgroundPaths != null && filter.backgroundPaths!.isNotEmpty) {
        return filter.backgroundPaths!.map((p) => File(p)).toList();
      }
    }

    return null;
  }
}
