import 'dart:io';

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
  Reciter? _selectedReciter;
  Surah? _selectedSurah;
  FilterTheme _selectedFilter = FilterThemes.all.first;

  final _fromController = TextEditingController(text: '1');
  final _toController = TextEditingController(text: '1');
  final _durationController = TextEditingController(text: '20');

  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _durationController.dispose();
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
    final recitersAsync = ref.watch(recitersProvider);
    final surahsAsync = ref.watch(surahsProvider);
    final generationState = ref.watch(generationProvider);

    ref.listen<GenerationState>(generationProvider, (previous, next) {
      if (next.outputPath != null && next.outputPath != previous?.outputPath) {
        _initVideoPlayer(next.outputPath!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('مولد حالات قرآنيه'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('الإعدادات الأساسية'),
              const SizedBox(height: 12),
              _buildDropdownRow(
                recitersAsync: recitersAsync,
                surahsAsync: surahsAsync,
              ),
              const SizedBox(height: 16),
              _buildAyahInputs(),
              const SizedBox(height: 16),
              _buildDurationInput(),
              const SizedBox(height: 24),
              _buildSectionTitle('الفلاتر الجاهزة'),
              const SizedBox(height: 12),
              _buildFiltersGrid(),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
              setState(() => _selectedReciter = reciters.first);
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
          onChanged: (value) => setState(() => _selectedReciter = value),
          decoration: const InputDecoration(
            labelText: 'القارئ',
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
                _toController.text = '1';
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
              _toController.text = value?.numberOfAyahs.toString() ?? '1';
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
          decoration: const InputDecoration(
            labelText: 'من آية',
            border: OutlineInputBorder(),
          ),
        );

        final toInput = TextFormField(
          controller: _toController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'إلى آية',
            border: OutlineInputBorder(),
          ),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: fromInput),
              const SizedBox(width: 12),
              Expanded(child: toInput),
            ],
          );
        } else {
          return Column(
            children: [
              fromInput,
              const SizedBox(height: 12),
              toInput,
            ],
          );
        }
      },
    );
  }

  Widget _buildDurationInput() {
    return TextFormField(
      controller: _durationController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'مدة الفيديو (بالثواني)',
        border: OutlineInputBorder(),
      ),
    );
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
      icon: const Icon(Icons.movie_creation_outlined),
      label: const Text('توليد الفيديو'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildPreviewSection(String path) {
    final videoReady =
        _videoController != null && _videoController!.value.isInitialized;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        _buildSectionTitle('المعاينة'),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 9 / 16,
          child: videoReady
              ? VideoPlayer(_videoController!)
              : const Center(child: CircularProgressIndicator()),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _saveOutput,
          icon: const Icon(Icons.download),
          label: const Text('حفظ الفيديو'),
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
    final fromAyah = int.tryParse(_fromController.text) ?? 1;
    final toAyah = int.tryParse(_toController.text) ?? fromAyah;
    final duration = int.tryParse(_durationController.text) ?? 20;

    final request = GenerationRequest(
      reciter: _selectedReciter!,
      surah: _selectedSurah!,
      fromAyah: fromAyah,
      toAyah: toAyah,
      durationSeconds: duration,
      filter: _selectedFilter,
    );

    await ref.read(generationProvider.notifier).generate(request);
  }

  Future<void> _saveOutput() async {
    final outputPath = ref.read(generationProvider).outputPath;
    if (outputPath == null) return;
    final storage = StorageService();
    final savedPath = await storage.saveToGallery(outputPath);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم الحفظ في: $savedPath')),
      );
    }
  }
}
