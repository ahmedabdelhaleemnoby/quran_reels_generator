import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../core/providers/theme_provider.dart';
import 'export/providers/export_provider.dart';
import 'filters/domain/filter_model.dart';
import 'filters/presentation/filters_bottom_sheet.dart';
import 'filters/providers/filters_provider.dart';
import 'media_picker/providers/media_picker_provider.dart';

/// Main application screen
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  String? _currentMediaPath;
  bool _isVideo = false;
  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initVideoPlayer(String path) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(File(path));
    await _videoController!.initialize();
    await _videoController!.setLooping(true);
    await _videoController!.play();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtersState = ref.watch(filtersProvider);
    final exportState = ref.watch(exportProvider);

    // Listen to processed file updates
    ref.listen<FiltersState>(filtersProvider, (previous, next) {
      if (next.processedFilePath != null && next.processedFilePath != _currentMediaPath) {
        setState(() {
          _currentMediaPath = next.processedFilePath;
        });
        if (_isVideo) {
          _initVideoPlayer(next.processedFilePath!);
        }
      }
    });

    // Theme toggle
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark || 
                      (themeMode == ThemeMode.system && Theme.of(context).brightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('📸 فلاتر الميديا'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeModeProvider.notifier).state = 
                  isDarkMode ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Media display area
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: _buildMediaDisplay(),
            ),
          ),

          // Controls area
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Media picker buttons
                  if (_currentMediaPath == null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _buildMediaPickerButton(
                            icon: Icons.image,
                            label: 'اختر صورة',
                            onTap: () => _pickMedia(false),
                          ),
                          const SizedBox(height: 12),
                          _buildMediaPickerButton(
                            icon: Icons.video_library,
                            label: 'اختر فيديو',
                            onTap: () => _pickMedia(true),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Filter and export controls
                  if (_currentMediaPath != null) ...[
                    // Active filters display
                    if (filtersState.activeFilters.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: filtersState.activeFilters.keys.map((type) {
                            return Chip(
                              label: Text(type.toString().split('.').last),
                              onDeleted: () {
                                ref.read(filtersProvider.notifier).updateFilter(
                                      type,
                                      Filters.getFilterByType(type)?.defaultValue ?? 0,
                                    );
                              },
                            );
                          }).toList(),
                        ),
                      ),

                    // Processing progress
                    if (filtersState.isProcessing)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              value: filtersState.processingProgress,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'جاري المعالجة... ${(filtersState.processingProgress * 100).toInt()}%',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),

                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Filters button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: filtersState.isProcessing
                                  ? null
                                  : () => _showFiltersBottomSheet(),
                              icon: const Icon(Icons.filter_alt),
                              label: const Text('فلاتر'),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Apply button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: filtersState.activeFilters.isEmpty ||
                                      filtersState.isProcessing
                                  ? null
                                  : () => _applyFilters(),
                              icon: const Icon(Icons.check),
                              label: const Text('تطبيق'),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Save and Share buttons
                    if (filtersState.processedFilePath != null &&
                        !filtersState.isProcessing)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: exportState.isExporting
                                    ? null
                                    : () => _saveToGallery(),
                                icon: const Icon(Icons.save),
                                label: const Text('حفظ'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: exportState.isExporting
                                    ? null
                                    : () => _shareMedia(),
                                icon: const Icon(Icons.share),
                                label: const Text('مشاركة'),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Reset button
                    TextButton.icon(
                      onPressed: filtersState.isProcessing ? null : _reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة تعيين'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaDisplay() {
    if (_currentMediaPath == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 80,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'اختر صورة أو فيديو للبدء',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      );
    }

    if (_isVideo) {
      if (_videoController == null || !_videoController!.value.isInitialized) {
        return const Center(child: CircularProgressIndicator());
      }

      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    return Center(
      child: Image.file(
        File(_currentMediaPath!),
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildMediaPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMedia(bool isVideo) async {
    final mediaPicker = ref.read(mediaPickerProvider.notifier);

    if (isVideo) {
      await mediaPicker.pickVideo();
    } else {
      await mediaPicker.pickImage();
    }

    final selectedMedia = ref.read(mediaPickerProvider).selectedMedia;
    if (selectedMedia != null) {
      setState(() {
        _currentMediaPath = selectedMedia.path;
        _isVideo = selectedMedia.isVideo;
      });

      if (_isVideo) {
        await _initVideoPlayer(selectedMedia.path);
      }
    }
  }

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FiltersBottomSheet(isVideo: _isVideo),
    );
  }

  Future<void> _applyFilters() async {
    if (_currentMediaPath == null) return;

    final filtersNotifier = ref.read(filtersProvider.notifier);
    await filtersNotifier.applyFilters(_currentMediaPath!, _isVideo);

    final filtersState = ref.read(filtersProvider);
    if (filtersState.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${filtersState.error}')),
        );
      }
    }
  }

  Future<void> _saveToGallery() async {
    final filtersState = ref.read(filtersProvider);
    if (filtersState.processedFilePath == null) return;

    final exportNotifier = ref.read(exportProvider.notifier);
    await exportNotifier.saveToGallery(filtersState.processedFilePath!);

    if (mounted) {
      final exportState = ref.read(exportProvider);
      if (exportState.savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ تم الحفظ بنجاح')),
        );
      }
    }
  }

  Future<void> _shareMedia() async {
    final filtersState = ref.read(filtersProvider);
    if (filtersState.processedFilePath == null) return;

    final exportNotifier = ref.read(exportProvider.notifier);
    await exportNotifier.shareMedia(filtersState.processedFilePath!);
  }

  void _reset() {
    setState(() {
      _currentMediaPath = null;
      _isVideo = false;
    });
    _videoController?.dispose();
    _videoController = null;

    ref.read(filtersProvider.notifier).resetAllFilters();
    ref.read(filtersProvider.notifier).clearProcessedFile();
    ref.read(mediaPickerProvider.notifier).clearSelection();
    ref.read(exportProvider.notifier).reset();
  }
}

