import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../core/constants/app_constants.dart';
import '../../../services/storage_service.dart';
import '../domain/filter_theme.dart';
import '../domain/generation_request.dart';
import '../domain/reciter.dart';
import '../domain/surah.dart';
import '../providers/generation_provider.dart';
import '../providers/metadata_providers.dart';
import 'widgets/filter_card.dart';

class QuranGeneratorScreen extends ConsumerStatefulWidget {
  const QuranGeneratorScreen({super.key});

  @override
  ConsumerState<QuranGeneratorScreen> createState() => _QuranGeneratorScreenState();
}

class _QuranGeneratorScreenState extends ConsumerState<QuranGeneratorScreen> {
  final _fromController = TextEditingController(text: '1');
  final _toController = TextEditingController(text: '1');
  final _durationController = TextEditingController(text: '15');
  
  Reciter? _selectedReciter;
  Surah? _selectedSurah;
  FilterTheme _selectedFilter = FilterThemes.all.first;
  VideoPlayerController? _videoController;
  List<String> _selectedMediaPaths = [];

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _durationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }


  Future<void> _pickBackgroundMedia() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov'],
      allowMultiple: true,
    );

    if (result != null) {
      final paths = result.files.map((f) => f.path).whereType<String>().toList();
      
      // Determine if it's video or images
      final hasVideo = paths.any((p) => p.endsWith('.mp4') || p.endsWith('.mov'));
      
      setState(() {
        if (hasVideo) {
          // If video, only take the first one
          _selectedMediaPaths = [paths.first];
          _selectedFilter = _selectedFilter.copyWith(backgroundType: BackgroundType.videoFile);
        } else {
          // If images, allow up to 10
          _selectedMediaPaths = [..._selectedMediaPaths, ...paths].take(10).toList();
          _selectedFilter = _selectedFilter.copyWith(backgroundType: BackgroundType.imageFile);
        }
      });
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _selectedMediaPaths.removeAt(index);
      if (_selectedMediaPaths.isEmpty) {
        _selectedFilter = _selectedFilter.copyWith(backgroundType: BackgroundType.solidColor);
      }
    });
  }

  Future<void> _initVideoPlayer(String path) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.file(File(path));
    await _videoController!.initialize();
    await _videoController!.setLooping(false);
    // Don't auto-play
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final recitersAsync = ref.watch(recitersProvider);
    final surahsAsync = ref.watch(surahsProvider);
    final generationState = ref.watch(generationProvider);

    ref.listen<GenerationState>(generationProvider, (previous, next) {
      if (next.outputPath != null && next.outputPath != previous?.outputPath) {
        _initVideoPlayer(next.outputPath!);
      } else if (next.outputPath == null && previous?.outputPath != null) {
        _videoController?.dispose();
        _videoController = null;
        if (mounted) setState(() {});
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('سكينة القرآن - Quran Serenity'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('1. اختيار السورة والقارئ', Icons.book_outlined),
              const SizedBox(height: 12),
              _buildDropdownRow(
                recitersAsync: recitersAsync,
                surahsAsync: surahsAsync,
              ),
              const SizedBox(height: 16),
              _buildAyahInputs(),
              const SizedBox(height: 24),
               _buildSectionTitle('2. الفلاتر الجاهزة', Icons.auto_awesome_outlined),
               const SizedBox(height: 12),
               _buildFiltersGrid(),
               const SizedBox(height: 24),
               _buildSectionTitle('3. تخصيص المظهر (الاستايل)', Icons.brush_outlined),
               const SizedBox(height: 12),
               _buildStylingControls(),
               const SizedBox(height: 24),
               _buildSectionTitle('4. اختيار الخلفيات', Icons.collections_outlined),
               const SizedBox(height: 12),
               _buildMediaPicker(),
               const SizedBox(height: 24),
               _buildSectionTitle('5. خيارات العرض', Icons.visibility_outlined),
               const SizedBox(height: 12),
               _buildDisplayToggles(),
               const SizedBox(height: 24),
               _buildGenerateButton(generationState),
              const SizedBox(height: 16),
              if (generationState.isGenerating) _buildProgress(generationState),
              if (generationState.error != null) _buildError(generationState.error!),
              if (generationState.outputPath != null &&
                  !generationState.isGenerating)
                _buildPreviewSection(generationState.outputPath!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withAlpha(40),
            Theme.of(context).primaryColor.withAlpha(5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).primaryColor.withAlpha(30)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 0.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStylingControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildSliderRow(
              'حجم الخط',
              _selectedFilter.fontSize,
              20, 120,
              (val) => setState(() => _selectedFilter = _selectedFilter.copyWith(fontSize: val)),
            ),
            _buildSliderRow(
              'تباعد الأسطر',
              _selectedFilter.lineSpacing,
              0, 100,
              (val) => setState(() => _selectedFilter = _selectedFilter.copyWith(lineSpacing: val)),
            ),
            _buildSliderRow(
              'تباعد الحروف',
              _selectedFilter.letterSpacing ?? 0,
              -5, 20,
              (val) => setState(() => _selectedFilter = _selectedFilter.copyWith(letterSpacing: val)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12))),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        Text(value.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildChipToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: value,
      onSelected: onChanged,
    );
  }

  Widget _buildDropdownRow({
    required AsyncValue<List<Reciter>> recitersAsync,
    required AsyncValue<List<Surah>> surahsAsync,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final reciterDropdown = _buildReciterDropdown(recitersAsync);
        final surahDropdown = _buildSurahDropdown(surahsAsync);

        if (isWide) {
          return Row(
            children: [
              Expanded(child: reciterDropdown),
              const SizedBox(width: 12),
              Expanded(child: surahDropdown),
            ],
          );
        } else {
          return Column(
            children: [
              reciterDropdown,
              const SizedBox(height: 12),
              surahDropdown,
            ],
          );
        }
      },
    );
  }

  Widget _buildReciterDropdown(AsyncValue<List<Reciter>> recitersAsync) {
    return recitersAsync.when(
      data: (reciters) {
        if (_selectedReciter == null && reciters.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedReciter = reciters.firstWhere((r) => r.id == 'Alafasy_128kbps', orElse: () => reciters.first));
            }
          });
        }
        return DropdownButtonFormField<Reciter>(
          initialValue: _selectedReciter,
          items: reciters
              .map(
                (reciter) => DropdownMenuItem(
                  value: reciter,
                  child: Text(reciter.name),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() {
            _selectedReciter = value;
          }),
          decoration: const InputDecoration(
            labelText: 'القارئ / المصدر',
            border: OutlineInputBorder(),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => SizedBox(
        height: 60,
        child: Center(
          child: Text(
            'خطأ في تحميل القراء: $err',
            style: const TextStyle(color: Colors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildSurahDropdown(AsyncValue<List<Surah>> surahsAsync) {
    return surahsAsync.when(
      data: (surahs) {
        if (_selectedSurah == null && surahs.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _selectedSurah = surahs.first;
                _fromController.text = '1';
                _toController.text = surahs.first.numberOfAyahs.toString();
              });
            }
          });
        }
        return DropdownButtonFormField<Surah>(
          initialValue: _selectedSurah,
          items: surahs
              .map(
                (surah) => DropdownMenuItem(
                  value: surah,
                  child: Text('${surah.number}. ${surah.name}'),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedSurah = value;
              _fromController.text = '1';
              _toController.text = (value?.numberOfAyahs ?? 1).toString();
            });
          },
          decoration: const InputDecoration(
            labelText: 'السورة',
            border: OutlineInputBorder(),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => const SizedBox(
        height: 60,
        child: Center(
          child: Text(
            'خطأ في تحميل السور',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildAyahInputs() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        
        final fromInput = TextFormField(
          controller: _fromController,
          keyboardType: TextInputType.number,
          onChanged: (val) {
            final num = int.tryParse(val) ?? 1;
            final max = _selectedSurah?.numberOfAyahs ?? 1;
            if (num > max) _fromController.text = max.toString();
            if (num < 1) _fromController.text = '1';
          },
          decoration: const InputDecoration(
            labelText: 'من آية',
            border: OutlineInputBorder(),
          ),
        );

        final toInput = TextFormField(
          controller: _toController,
          keyboardType: TextInputType.number,
          onChanged: (val) {
            final num = int.tryParse(val) ?? 1;
            final max = _selectedSurah?.numberOfAyahs ?? 1;
            if (num > max) _toController.text = max.toString();
            if (num < 1) _toController.text = '1';
          },
          decoration: const InputDecoration(
            labelText: 'إلى آية',
            border: OutlineInputBorder(),
          ),
        );

        if (isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: fromInput),
                  const SizedBox(width: 12),
                  Expanded(child: toInput),
                ],
              ),
              _buildAyahRangeWarning(),
            ],
          );
        } else {
          return Column(
            children: [
              fromInput,
              const SizedBox(height: 12),
              toInput,
              _buildAyahRangeWarning(),
            ],
          );
        }
      },
    );
  }

  Widget _buildAyahRangeWarning() {
    final from = int.tryParse(_fromController.text) ?? 1;
    final to = int.tryParse(_toController.text) ?? 1;
    final count = (to - from + 1).abs();

    if (count > 20) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'تنبيه: النطاق كبير ($count آية). قد يستغرق التوليد وقتاً أطول.',
                style: const TextStyle(color: Colors.orange, fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildFiltersGrid() {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 900 ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: FilterThemes.all.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (context, index) {
        final filter = FilterThemes.all[index];
        return FilterCard(
          filter: filter,
          isSelected: filter.id == _selectedFilter.id,
          onTap: () => setState(() => _selectedFilter = filter),
        );
      },
    );
  }

  Widget _buildGenerateButton(GenerationState state) {
    return ElevatedButton.icon(
      onPressed: state.isGenerating ? null : _onGenerate,
      icon: const Icon(Icons.auto_awesome),
      label: const Text('بدء التوليد بخياراتك'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildProgress(GenerationState state) {
    return Column(
      children: [
        LinearProgressIndicator(value: state.progress),
        const SizedBox(height: 8),
        Text(state.statusMessage),
      ],
    );
  }

  Widget _buildError(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        error,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }

  Widget _buildDisplayToggles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('خيارات العرض:', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildChipToggle('اسم السورة', _selectedFilter.showSurahName, 
                (val) => setState(() => _selectedFilter = _selectedFilter.copyWith(showSurahName: val))),
            _buildChipToggle('رقم الآية', _selectedFilter.showAyahNumber, 
                (val) => setState(() => _selectedFilter = _selectedFilter.copyWith(showAyahNumber: val))),
            _buildChipToggle('اسم القارئ', _selectedFilter.showReciterName, 
                (val) => setState(() => _selectedFilter = _selectedFilter.copyWith(showReciterName: val))),
          ],
        ),
        const SizedBox(height: 12),
        const Text('زخرفة الخلفية:', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        DropdownButtonFormField<DecorationPattern>(
          initialValue: _selectedFilter.decorationPattern,
          items: DecorationPattern.values.map((p) {
            String label = 'بدون';
            if (p == DecorationPattern.hexagon) label = 'شبكة (Hex)';
            if (p == DecorationPattern.dots) label = 'نقاط (Grain)';
            if (p == DecorationPattern.islamic) label = 'تظليل (Vignette)';
            return DropdownMenuItem(value: p, child: Text(label));
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedFilter = _selectedFilter.copyWith(decorationPattern: val));
            }
          },
          decoration: const InputDecoration(
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection(String path) {
    final videoReady =
        _videoController != null && _videoController!.value.isInitialized;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        _buildSectionTitle('المعاينه النهائيه', Icons.play_circle_outline),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 9 / 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (videoReady) ...[
                VideoPlayer(_videoController!),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _videoController!.value.isPlaying
                          ? _videoController!.pause()
                          : _videoController!.play();
                    });
                  },
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: Icon(
                        _videoController!.value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 64,
                        color: Colors.white.withAlpha(150),
                      ),
                    ),
                  ),
                ),
              ] else
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saveOutput,
                icon: const Icon(Icons.download),
                label: const Text('حفظ'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareOutput,
                icon: const Icon(Icons.share),
                label: const Text('مشاركة'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SelectableText(
          'مسار الإخراج: $path',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _onGenerate() async {
    if (_selectedReciter == null || _selectedSurah == null) return;

    var fromAyah = int.tryParse(_fromController.text) ?? 1;
    var toAyah = int.tryParse(_toController.text) ?? fromAyah;
    
    // Stability Limit: Max 50 ayahs
    if ((toAyah - fromAyah + 1).abs() > 50) {
      toAyah = fromAyah + 49;
      if (toAyah > (_selectedSurah?.numberOfAyahs ?? 1)) {
        toAyah = _selectedSurah?.numberOfAyahs ?? 1;
      }
      _toController.text = toAyah.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تقليل النطاق لـ 50 آية لضمان استقرار التطبيق')),
      );
    }

    final duration = int.tryParse(_durationController.text) ?? 20;

    final request = GenerationRequest(
      reciter: _selectedReciter!,
      surah: _selectedSurah!,
      fromAyah: fromAyah,
      toAyah: toAyah,
      durationSeconds: duration,
      filter: _selectedFilter.copyWith(backgroundPaths: _selectedMediaPaths),
      backgroundPaths: _selectedMediaPaths,
    );

    // Stop current video if any
    _videoController?.pause();

    await ref.read(generationProvider.notifier).generate(request);
  }

  Future<void> _saveOutput() async {
    final outputPath = ref.read(generationProvider).outputPath;
    if (outputPath == null) return;
    final storage = StorageService();
    try {
      final savedPath = await storage.saveToGallery(outputPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم الحفظ في: $savedPath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: $e')),
        );
      }
    }
  }

  Future<void> _shareOutput() async {
    final outputPath = ref.read(generationProvider).outputPath;
    if (outputPath == null) return;
    final storage = StorageService();
    try {
      await storage.shareMedia(outputPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في المشاركة: $e')),
        );
      }
    }
  }

  Widget _buildMediaPicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _pickBackgroundMedia,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('إضافة صور أو فيديو'),
            ),
            if (_selectedMediaPaths.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMediaPaths.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final path = _selectedMediaPaths[index];
                    final isVideo = path.endsWith('.mp4') || path.endsWith('.mov');
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey.shade200,
                            child: isVideo
                                ? const Center(child: Icon(Icons.videocam))
                                : Image.file(File(path), fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          top: 2,
                          right: 2,
                          child: GestureDetector(
                            onTap: () => _removeMedia(index),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.red.withAlpha(200),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'عدد الملفات: ${_selectedMediaPaths.length}/10',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
