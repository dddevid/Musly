import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/now_playing_theme.dart';
import '../services/now_playing_theme_service.dart';
import '../theme/app_theme.dart';

class ThemeEditorScreen extends StatefulWidget {
  final String themeId;

  const ThemeEditorScreen({
    super.key,
    required this.themeId,
  });

  @override
  State<ThemeEditorScreen> createState() => _ThemeEditorScreenState();
}

class _ThemeEditorScreenState extends State<ThemeEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late NowPlayingTheme _draft;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    final service = context.read<NowPlayingThemeService>();
    final originalTheme = service.themes.firstWhere((t) => t.id == widget.themeId);
    _draft = originalTheme;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateDraft(NowPlayingTheme Function(NowPlayingTheme) updater) {
    setState(() {
      _draft = updater(_draft);
      _hasChanges = true;
    });
  }

  Future<void> _saveDraft() async {
    final service = context.read<NowPlayingThemeService>();
    await service.saveTheme(_draft);
    setState(() => _hasChanges = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Theme saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkSurface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _draft.themeName,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            if (_hasChanges)
              Text(
                'Unsaved changes',
                style: TextStyle(
                  color: Colors.orange.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => _confirmExit(),
        ),
        actions: [
          if (_hasChanges)
            IconButton(
              icon: const Icon(CupertinoIcons.checkmark_alt, color: Colors.white),
              onPressed: _saveDraft,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          padding: EdgeInsets.zero,
          indicatorColor: AppTheme.appleMusicRed,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          tabs: const [
            Tab(text: 'Info'),
            Tab(text: 'Background'),
            Tab(text: 'Text'),
            Tab(text: 'Artwork'),
            Tab(text: 'Progress'),
            Tab(text: 'Controls'),
            Tab(text: 'Animations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildBackgroundTab(),
          _buildTextTab(),
          _buildArtworkTab(),
          _buildProgressTab(),
          _buildControlsTab(),
          _buildAnimationsTab(),
        ],
      ),
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTextField(
          label: 'Theme Name',
          value: _draft.themeName,
          onChanged: (val) => _updateDraft(
            (d) => d.copyWith(themeName: val),
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Author',
          value: _draft.author,
          onChanged: (val) => _updateDraft(
            (d) => d.copyWith(author: val),
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Version',
          value: _draft.version,
          onChanged: (val) => _updateDraft(
            (d) => d.copyWith(version: val),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDropdown(
          label: 'Background Type',
          value: _draft.background.type,
          items: const ['solid', 'gradient', 'dynamic_blur'],
          onChanged: (val) => _updateDraft(
            (d) => d.copyWith(
              background: BackgroundConfig(
                type: val!,
                colors: d.background.colors,
                opacity: d.background.opacity,
                blurSigma: d.background.blurSigma,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildColorPicker(
          label: 'Color 1',
          color: _draft.background.getColor(0),
          onChanged: (color) {
            final hex = color.value.toRadixString(16).substring(2);
            final newColors = [..._draft.background.colors];
            if (newColors.isEmpty) {
              newColors.add('#$hex');
            } else {
              newColors[0] = '#$hex';
            }
            _updateDraft(
              (d) => d.copyWith(
                background: BackgroundConfig(
                  type: d.background.type,
                  colors: newColors,
                  opacity: d.background.opacity,
                  blurSigma: d.background.blurSigma,
                ),
              ),
            );
          },
        ),
        if (_draft.background.type == 'gradient') ...[
          const SizedBox(height: 16),
          _buildColorPicker(
            label: 'Color 2',
            color: _draft.background.getColor(1),
            onChanged: (color) {
              final hex = color.value.toRadixString(16).substring(2);
              final newColors = [..._draft.background.colors];
              while (newColors.length < 2) {
                newColors.add('#1a1a2e');
              }
              newColors[1] = '#$hex';
              _updateDraft(
                (d) => d.copyWith(
                  background: BackgroundConfig(
                    type: d.background.type,
                    colors: newColors,
                    opacity: d.background.opacity,
                    blurSigma: d.background.blurSigma,
                  ),
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Opacity',
          value: _draft.background.opacity,
          min: 0.0,
          max: 1.0,
          onChanged: (val) => _updateDraft(
            (d) => d.copyWith(
              background: BackgroundConfig(
                type: d.background.type,
                colors: d.background.colors,
                opacity: val,
                blurSigma: d.background.blurSigma,
              ),
            ),
          ),
        ),
        if (_draft.background.type == 'dynamic_blur') ...[
          const SizedBox(height: 16),
          _buildSlider(
            label: 'Blur Sigma',
            value: _draft.background.blurSigma,
            min: 0.0,
            max: 50.0,
            onChanged: (val) => _updateDraft(
              (d) => d.copyWith(
                background: BackgroundConfig(
                  type: d.background.type,
                  colors: d.background.colors,
                  opacity: d.background.opacity,
                  blurSigma: val,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Title Style',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextStyleEditor(_draft.text.title, (config) {
          _updateDraft(
            (d) => d.copyWith(
              text: TextConfig(
                title: config,
                artist: d.text.artist,
                album: d.text.album,
                duration: d.text.duration,
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        const Text(
          'Artist Style',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildTextStyleEditor(_draft.text.artist, (config) {
          _updateDraft(
            (d) => d.copyWith(
              text: TextConfig(
                title: d.text.title,
                artist: config,
                album: d.text.album,
                duration: d.text.duration,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTextStyleEditor(
    TextStyleConfig config,
    void Function(TextStyleConfig) onUpdate,
  ) {
    return Column(
      children: [
        _buildColorPicker(
          label: 'Color',
          color: config.getColor(),
          onChanged: (color) {
            final hex = color.value.toRadixString(16).substring(2);
            onUpdate(
              TextStyleConfig(
                color: '#$hex',
                fontSize: config.fontSize,
                fontWeight: config.fontWeight,
                fontFamily: config.fontFamily,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Font Size',
          value: config.fontSize,
          min: 8.0,
          max: 48.0,
          onChanged: (val) {
            onUpdate(
              TextStyleConfig(
                color: config.color,
                fontSize: val,
                fontWeight: config.fontWeight,
                fontFamily: config.fontFamily,
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Font Weight',
          value: config.fontWeight,
          items: const [
            'normal',
            'bold',
            'w100',
            'w200',
            'w300',
            'w400',
            'w500',
            'w600',
            'w700',
            'w800',
            'w900',
          ],
          onChanged: (val) {
            onUpdate(
              TextStyleConfig(
                color: config.color,
                fontSize: config.fontSize,
                fontWeight: val!,
                fontFamily: config.fontFamily,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildArtworkTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDropdown(
          label: 'Shape',
          value: _draft.artwork.shape,
          items: const ['square', 'circle', 'rounded_rect'],
          onChanged: (val) => _updateDraft(
            (d) => d.copyWith(
              artwork: ArtworkConfig(
                shape: val!,
                sizeFactor: d.artwork.sizeFactor,
                cornerRadius: d.artwork.cornerRadius,
                shadow: d.artwork.shadow,
                rotation: d.artwork.rotation,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Size Factor',
          value: _draft.artwork.sizeFactor,
          min: 0.1,
          max: 1.0,
          onChanged: (val) => _updateDraft(
            (d) => d.copyWith(
              artwork: ArtworkConfig(
                shape: d.artwork.shape,
                sizeFactor: val,
                cornerRadius: d.artwork.cornerRadius,
                shadow: d.artwork.shadow,
                rotation: d.artwork.rotation,
              ),
            ),
          ),
        ),
        if (_draft.artwork.shape == 'square') ...[
          const SizedBox(height: 16),
          _buildSlider(
            label: 'Corner Radius',
            value: _draft.artwork.cornerRadius,
            min: 0.0,
            max: 50.0,
            onChanged: (val) => _updateDraft(
              (d) => d.copyWith(
                artwork: ArtworkConfig(
                  shape: d.artwork.shape,
                  sizeFactor: d.artwork.sizeFactor,
                  cornerRadius: val,
                  shadow: d.artwork.shadow,
                  rotation: d.artwork.rotation,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildSwitch(
          label: 'Shadow',
          value: _draft.artwork.shadow,
          onChanged: (val) => _updateDraft(
            (d) => d.copyWith(
              artwork: ArtworkConfig(
                shape: d.artwork.shape,
                sizeFactor: d.artwork.sizeFactor,
                cornerRadius: d.artwork.cornerRadius,
                shadow: val,
                rotation: d.artwork.rotation,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSwitch(
          label: 'Rotation Animation',
          value: _draft.artwork.rotation,
          onChanged: (val) => _updateDraft(
            (d) => d.copyWith(
              artwork: ArtworkConfig(
                shape: d.artwork.shape,
                sizeFactor: d.artwork.sizeFactor,
                cornerRadius: d.artwork.cornerRadius,
                shadow: d.artwork.shadow,
                rotation: val,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildColorPicker(
          label: 'Active Color',
          color: _draft.progressBar.getActiveColor(),
          onChanged: (color) {
            final hex = color.value.toRadixString(16).substring(2);
            _updateDraft(
              (d) => d.copyWith(
                progressBar: ProgressBarConfig(
                  activeColor: '#$hex',
                  inactiveColor: d.progressBar.inactiveColor,
                  height: d.progressBar.height,
                  shape: d.progressBar.shape,
                  thumbVisible: d.progressBar.thumbVisible,
                  thumbColor: d.progressBar.thumbColor,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildColorPicker(
          label: 'Inactive Color',
          color: _draft.progressBar.getInactiveColor(),
          onChanged: (color) {
            final hex = color.value.toRadixString(16);
            _updateDraft(
              (d) => d.copyWith(
                progressBar: ProgressBarConfig(
                  activeColor: d.progressBar.activeColor,
                  inactiveColor: '#$hex',
                  height: d.progressBar.height,
                  shape: d.progressBar.shape,
                  thumbVisible: d.progressBar.thumbVisible,
                  thumbColor: d.progressBar.thumbColor,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Height',
          value: _draft.progressBar.height,
          min: 1.0,
          max: 10.0,
          onChanged: (val) => _updateDraft(
            (d) => d.copyWith(
              progressBar: ProgressBarConfig(
                activeColor: d.progressBar.activeColor,
                inactiveColor: d.progressBar.inactiveColor,
                height: val,
                shape: d.progressBar.shape,
                thumbVisible: d.progressBar.thumbVisible,
                thumbColor: d.progressBar.thumbColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Shape',
          value: _draft.progressBar.shape,
          items: const ['rounded', 'square'],
          onChanged: (val) => _updateDraft(
            (d) => d.copyWith(
              progressBar: ProgressBarConfig(
                activeColor: d.progressBar.activeColor,
                inactiveColor: d.progressBar.inactiveColor,
                height: d.progressBar.height,
                shape: val!,
                thumbVisible: d.progressBar.thumbVisible,
                thumbColor: d.progressBar.thumbColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSwitch(
          label: 'Thumb Visible',
          value: _draft.progressBar.thumbVisible,
          onChanged: (val) => _updateDraft(
            (d) => d.copyWith(
              progressBar: ProgressBarConfig(
                activeColor: d.progressBar.activeColor,
                inactiveColor: d.progressBar.inactiveColor,
                height: d.progressBar.height,
                shape: d.progressBar.shape,
                thumbVisible: val,
                thumbColor: d.progressBar.thumbColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildColorPicker(
          label: 'Button Color',
          color: _draft.controls.getColor(),
          onChanged: (color) {
            final hex = color.value.toRadixString(16).substring(2);
            _updateDraft(
              (d) => d.copyWith(
                controls: ControlsConfig(
                  playShape: d.controls.playShape,
                  color: '#$hex',
                  size: d.controls.size,
                  playButtonColor: d.controls.playButtonColor,
                  playButtonShape: d.controls.playButtonShape,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildColorPicker(
          label: 'Play Button Color',
          color: _draft.controls.getPlayButtonColor(),
          onChanged: (color) {
            final hex = color.value.toRadixString(16).substring(2);
            _updateDraft(
              (d) => d.copyWith(
                controls: ControlsConfig(
                  playShape: d.controls.playShape,
                  color: d.controls.color,
                  size: d.controls.size,
                  playButtonColor: '#$hex',
                  playButtonShape: d.controls.playButtonShape,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildSlider(
          label: 'Play Button Size',
          value: _draft.controls.size,
          min: 40.0,
          max: 100.0,
          onChanged: (val) => _updateDraft(
            (d) => d.copyWith(
              controls: ControlsConfig(
                playShape: d.controls.playShape,
                color: d.controls.color,
                size: val,
                playButtonColor: d.controls.playButtonColor,
                playButtonShape: d.controls.playButtonShape,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'Play Button Shape',
          value: _draft.controls.playShape,
          items: const ['circle', 'rounded_rect'],
          onChanged: (val) => _updateDraft(
            (d) => d.copyWith(
              controls: ControlsConfig(
                playShape: val!,
                color: d.controls.color,
                size: d.controls.size,
                playButtonColor: d.controls.playButtonColor,
                playButtonShape: val,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSwitch(
          label: 'Cover Rotation',
          value: _draft.animations.coverRotation,
          onChanged: (val) => _updateDraft(
            (d) => d.copyWith(
              animations: AnimationConfig(
                coverRotation: val,
                rotationSpeed: d.animations.rotationSpeed,
                pulse: d.animations.pulse,
                fadeIn: d.animations.fadeIn,
              ),
            ),
          ),
        ),
        if (_draft.animations.coverRotation) ...[
          const SizedBox(height: 16),
          _buildSlider(
            label: 'Rotation Speed (s/turn)',
            value: _draft.animations.rotationSpeed,
            min: 3.0,
            max: 60.0,
            onChanged: (val) => _updateDraft(
              (d) => d.copyWith(
                animations: AnimationConfig(
                  coverRotation: d.animations.coverRotation,
                  rotationSpeed: val,
                  pulse: d.animations.pulse,
                  fadeIn: d.animations.fadeIn,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _buildSwitch(
          label: 'Pulse Effect',
          value: _draft.animations.pulse,
          onChanged: (val) => _updateDraft(
            (d) => d.copyWith(
              animations: AnimationConfig(
                coverRotation: d.animations.coverRotation,
                rotationSpeed: d.animations.rotationSpeed,
                pulse: val,
                fadeIn: d.animations.fadeIn,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSwitch(
          label: 'Fade In',
          value: _draft.animations.fadeIn,
          onChanged: (val) => _updateDraft(
            (d) => d.copyWith(
              animations: AnimationConfig(
                coverRotation: d.animations.coverRotation,
                rotationSpeed: d.animations.rotationSpeed,
                pulse: d.animations.pulse,
                fadeIn: val,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String value,
    required void Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value)
            ..selection = TextSelection.collapsed(offset: value.length),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.darkCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required void Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: AppTheme.appleMusicRed,
          inactiveColor: Colors.white.withOpacity(0.3),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSwitch({
    required String label,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          CupertinoSwitch(
            value: value,
            activeColor: AppTheme.appleMusicRed,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppTheme.darkCard,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: AppTheme.darkCard,
            style: const TextStyle(color: Colors.white),
            underline: const SizedBox.shrink(),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker({
    required String label,
    required Color color,
    required void Function(Color) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final pickedColor = await showDialog<Color>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.darkSurface,
                title: Text(
                  'Pick $label',
                  style: const TextStyle(color: Colors.white),
                ),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: color,
                    onColorChanged: onChanged,
                    pickerAreaHeightPercent: 0.8,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Done',
                      style: TextStyle(color: AppTheme.appleMusicRed),
                    ),
                  ),
                ],
              ),
            );
            if (pickedColor != null) {
              onChanged(pickedColor);
            }
          },
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmExit() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text(
          'Unsaved Changes',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You have unsaved changes. Do you want to save before leaving?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Discard',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppTheme.appleMusicRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await _saveDraft();
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }
}
