import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'camera_page.dart';

// ── Bitrate presets ───────────────────────────────────────────────────────────

class _BitratePreset {
  const _BitratePreset(this.label, this.bps);
  final String label;
  final int bps; // bits per second
}

const _kBitratePresets = [
  _BitratePreset('Low · 500 kbps', 500 * 1024),
  _BitratePreset('Medium · 1.2 Mbps', 1200 * 1024),
  _BitratePreset('High · 2.5 Mbps', 2500 * 1024),
  _BitratePreset('Ultra · 4 Mbps', 4000 * 1024),
];

// ── Prefs keys ────────────────────────────────────────────────────────────────

class _Prefs {
  static const rtmpUrl = 'rtmpUrl';
  static const streamKey = 'streamKey';
  static const bitrateIndex = 'bitrateIndex';

  static Future<Map<String, dynamic>> load() async {
    final p = await SharedPreferences.getInstance();
    return {
      rtmpUrl: p.getString(rtmpUrl) ?? 'rtmp://192.168.1.75:1935/live',
      streamKey: p.getString(streamKey) ?? 'mystream',
      bitrateIndex: p.getInt(bitrateIndex) ?? 1, // default: Medium
    };
  }

  static Future<void> save({
    required String url,
    required String key,
    required int bitrateIndex,
  }) async {
    final p = await SharedPreferences.getInstance();
    await Future.wait([
      p.setString(rtmpUrl, url),
      p.setString(streamKey, key),
      p.setInt(_Prefs.bitrateIndex, bitrateIndex),
    ]);
  }
}

// ── SetupPage ─────────────────────────────────────────────────────────────────

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();

  bool _keyVisible = false;
  bool _isLoading = false;
  int _bitrateIndex = 1; // index into _kBitratePresets

  // ── Derived ─────────────────────────────────────────────────────────────────

  String get _composedUrl {
    final base = _urlController.text.trimRight().replaceAll(RegExp(r'/+$'), '');
    final key = _keyController.text.trim();
    if (base.isEmpty || key.isEmpty) return '';
    return '$base/$key';
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Rebuild URL preview whenever fields change.
    _urlController.addListener(_rebuild);
    _keyController.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _urlController
      ..removeListener(_rebuild)
      ..dispose();
    _keyController
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  // ── Settings I/O ─────────────────────────────────────────────────────────────

  Future<void> _loadSettings() async {
    final data = await _Prefs.load();
    if (!mounted) return;
    setState(() {
      _urlController.text = data[_Prefs.rtmpUrl] as String;
      _keyController.text = data[_Prefs.streamKey] as String;
      _bitrateIndex = (data[_Prefs.bitrateIndex] as int).clamp(
        0,
        _kBitratePresets.length - 1,
      );
    });
  }

  Future<void> _saveSettings() => _Prefs.save(
    url: _urlController.text,
    key: _keyController.text,
    bitrateIndex: _bitrateIndex,
  );

  // ── Validation ────────────────────────────────────────────────────────────────

  String? _validateUrl(String? v) {
    if (v == null || v.trim().isEmpty) return 'RTMP URL is required';
    if (!v.trim().startsWith('rtmp://')) return 'Must start with rtmp://';
    final uri = Uri.tryParse(v.trim().replaceFirst('rtmp://', 'http://'));
    if (uri == null || uri.host.isEmpty) return 'Enter a valid host';
    return null;
  }

  String? _validateKey(String? v) {
    if (v == null || v.trim().isEmpty) return 'Stream key is required';
    if (v.trim().contains('/')) return 'Key should not contain /';
    return null;
  }

  // ── Navigation ────────────────────────────────────────────────────────────────

  Future<void> _launch({required bool autoStart}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await _saveSettings();
    setState(() => _isLoading = false);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CameraPage(
          streamUrl: _composedUrl,
          autoStart: autoStart,
          bitrate: _kBitratePresets[_bitrateIndex].bps,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('STREAM SETUP')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────────
                const Icon(Icons.live_tv_rounded, size: 80),
                const SizedBox(height: 16),
                const Text(
                  'Ready to go live?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure your RTMP endpoint below.',
                  style: TextStyle(fontSize: 14, color: theme.hintColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // ── Server URL ───────────────────────────────────────────────
                TextFormField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  validator: _validateUrl,
                  decoration: const InputDecoration(
                    labelText: 'RTMP Server URL',
                    hintText: 'rtmp://192.168.x.x:1935/live',
                    prefixIcon: Icon(Icons.dns_rounded),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Stream key ───────────────────────────────────────────────
                TextFormField(
                  controller: _keyController,
                  obscureText: !_keyVisible,
                  autocorrect: false,
                  validator: _validateKey,
                  decoration: InputDecoration(
                    labelText: 'Stream Key',
                    hintText: 'e.g. mystream',
                    prefixIcon: const Icon(Icons.key_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _keyVisible
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      tooltip: _keyVisible ? 'Hide key' : 'Show key',
                      onPressed: () =>
                          setState(() => _keyVisible = !_keyVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── URL preview ──────────────────────────────────────────────
                if (_composedUrl.isNotEmpty) ...[
                  _UrlPreviewCard(url: _composedUrl),
                  const SizedBox(height: 24),
                ],

                // ── Bitrate selector ─────────────────────────────────────────
                _BitratePicker(
                  selectedIndex: _bitrateIndex,
                  onChanged: (i) => setState(() => _bitrateIndex = i),
                ),
                const SizedBox(height: 40),

                // ── Buttons ──────────────────────────────────────────────────
                _ActionButton(
                  label: 'LAUNCH CAMERA PREVIEW',
                  icon: Icons.videocam_rounded,
                  isLoading: _isLoading,
                  onPressed: () => _launch(autoStart: false),
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  label: 'CONNECT & STREAM',
                  icon: Icons.stream_rounded,
                  isLoading: _isLoading,
                  filled: true,
                  onPressed: () => _launch(autoStart: true),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── URL preview card ──────────────────────────────────────────────────────────

class _UrlPreviewCard extends StatelessWidget {
  const _UrlPreviewCard({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.link_rounded, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              url,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: color,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bitrate picker ────────────────────────────────────────────────────────────

class _BitratePicker extends StatelessWidget {
  const _BitratePicker({required this.selectedIndex, required this.onChanged});
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VIDEO QUALITY',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
            color: theme.hintColor,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_kBitratePresets.length, (i) {
            final selected = i == selectedIndex;
            return ChoiceChip(
              label: Text(_kBitratePresets[i].label),
              selected: selected,
              onSelected: (_) => onChanged(i),
            );
          }),
        ),
      ],
    );
  }
}

// ── Reusable action button ────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final spinner = const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );

    if (filled) {
      return FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading ? spinner : Icon(icon),
        label: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading ? spinner : Icon(icon),
      label: Text(label),
    );
  }
}
