import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';

/// Memory-palace scene gallery — read-only. Generation stays on the web app:
/// it needs a 4K image render, a vision pass and an OpenRouter key.
///
/// Three levels: sources (which books/videos have scenes) → scenes for a
/// source (metadata only) → one scene (the multi-MB 4K image, fetched only on
/// explicit tap and decoded off the UI isolate).
class MnemonicScreen extends StatefulWidget {
  const MnemonicScreen({super.key});

  @override
  State<MnemonicScreen> createState() => _MnemonicScreenState();
}

class _MnemonicScreenState extends State<MnemonicScreen> {
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      Future.microtask(() {
        if (mounted) context.read<AppState>().refreshMnemonicSources();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory palaces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.loadingMnemonicSources
                ? null
                : () => state.refreshMnemonicSources(),
          ),
        ],
      ),
      body: Builder(builder: (context) {
        if (state.loadingMnemonicSources && state.mnemonicSources.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.mnemonicSourcesError != null && state.mnemonicSources.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Could not load palaces:\n${state.mnemonicSourcesError}',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => state.refreshMnemonicSources(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (state.mnemonicSources.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No memory palaces yet.\nGenerate mnemonic scenes from a Visual Scribe board on the web app and they will appear here.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => state.refreshMnemonicSources(),
          child: ListView(
            children: [
              for (final s in state.mnemonicSources)
                ListTile(
                  leading: Icon(s.sourceKind == 'video'
                      ? Icons.ondemand_video_outlined
                      : Icons.menu_book_outlined),
                  title: Text(s.sourceTitle),
                  subtitle: Text(
                      '${s.boardCount} board${s.boardCount == 1 ? '' : 's'} · '
                      '${s.imageCount} scene${s.imageCount == 1 ? '' : 's'}'
                      '${s.latest == null ? '' : ' · ${_day(s.latest!)}'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => SceneListScreen(source: s),
                  )),
                ),
            ],
          ),
        );
      }),
    );
  }
}

/// Scene list for one source — metadata only, the server withholds the bytes.
class SceneListScreen extends StatefulWidget {
  final MnemonicSource source;
  const SceneListScreen({super.key, required this.source});

  @override
  State<SceneListScreen> createState() => _SceneListScreenState();
}

class _SceneListScreenState extends State<SceneListScreen> {
  List<MnemonicScene>? _scenes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final scenes = await context
          .read<AppState>()
          .api
          .listMnemonicScenes(widget.source.sourceKind, widget.source.sourceId);
      if (mounted) setState(() => _scenes = scenes);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.source.sourceTitle)),
      body: Builder(builder: (context) {
        if (_error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Could not load scenes:\n$_error',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (_scenes == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_scenes!.isEmpty) {
          return const Center(child: Text('No scenes for this source.'));
        }
        return ListView(
          children: [
            for (final m in _scenes!)
              ListTile(
                leading: const Icon(Icons.castle_outlined),
                title: Text(m.styleName ?? m.style ?? m.variant),
                subtitle: Text('${m.boardKey}\n'
                    '${m.width ?? '?'}×${m.height ?? '?'} · ~${_approxMb(m.imageChars)} download'
                    '${m.createdAt == null ? '' : ' · ${_day(m.createdAt!)}'}'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SceneViewScreen(meta: m),
                )),
              ),
          ],
        );
      }),
    );
  }
}

/// One scene: the 4K image in an InteractiveViewer with numbered pins where
/// the vision pass located a station, and a station list below — every
/// "legend" station lives only in the list, never pinned to wrong coordinates.
class SceneViewScreen extends StatefulWidget {
  final MnemonicScene meta;
  const SceneViewScreen({super.key, required this.meta});

  @override
  State<SceneViewScreen> createState() => _SceneViewScreenState();
}

// Strip the data-URL prefix and decode ~7 MB of base64. Top-level so it can
// run on a background isolate via compute().
Uint8List _decodeDataUrl(String dataUrl) {
  final comma = dataUrl.indexOf(',');
  return base64Decode(comma < 0 ? dataUrl : dataUrl.substring(comma + 1));
}

class _SceneViewScreenState extends State<SceneViewScreen> {
  Uint8List? _bytes;
  List<MnemonicHotspot> _hotspots = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _hotspots = widget.meta.hotspots;
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final full =
          await context.read<AppState>().api.getMnemonicScene(widget.meta.id);
      final bytes = await compute(_decodeDataUrl, full.image ?? '');
      if (mounted) {
        setState(() {
          _bytes = bytes;
          if (full.hotspots.isNotEmpty) _hotspots = full.hotspots;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.meta;
    // Hotspot x/y are fractions of the SCENE, which is 16:9; the stored canvas
    // extends a text panel to the right of it. Scenes without a panel are
    // exactly 16:9, so the scene width is min(width, height * 16/9).
    final w = (m.width ?? 0).toDouble();
    final h = (m.height ?? 0).toDouble();
    final sceneFrac = (w > 0 && h > 0) ? ((h * 16 / 9) / w).clamp(0.0, 1.0) : 1.0;
    final pinned = _hotspots.where((s) => s.placed == 'vision' && s.x != null && s.y != null).toList();

    return Scaffold(
      appBar: AppBar(title: Text(m.styleName ?? m.style ?? m.boardKey)),
      body: Builder(builder: (context) {
        if (_error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Could not load the scene:\n$_error',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        if (_bytes == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text('Fetching ~${_approxMb(m.imageChars)}…',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                maxScale: 8,
                minScale: 0.5,
                boundaryMargin: const EdgeInsets.all(64),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: (w > 0 && h > 0) ? w / h : 16 / 9,
                    child: LayoutBuilder(builder: (context, box) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(_bytes!, fit: BoxFit.fill,
                              gaplessPlayback: true),
                          for (final s in pinned)
                            Positioned(
                              left: s.x! * sceneFrac * box.maxWidth - 12,
                              top: s.y! * box.maxHeight - 12,
                              child: GestureDetector(
                                onTap: () => _showStation(context, s),
                                child: _pin(s),
                              ),
                            ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
            if (_hotspots.isNotEmpty)
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    for (final s in _hotspots)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: ActionChip(
                          avatar: CircleAvatar(
                            radius: 10,
                            backgroundColor: _hex(s.colorHex),
                            child: Text('${s.i + 1}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.white)),
                          ),
                          label: Text(s.heading,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          onPressed: () => _showStation(context, s),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      }),
    );
  }

  Widget _pin(MnemonicHotspot s) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _hex(s.colorHex),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
      ),
      child: Text('${s.i + 1}',
          style: const TextStyle(
              fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  void _showStation(BuildContext context, MnemonicHotspot s) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: _hex(s.colorHex),
                    child: Text('${s.i + 1}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.heading,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                ],
              ),
              if (s.placed == 'legend')
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('Not located in the picture — legend only.',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              const SizedBox(height: 12),
              for (final p in s.points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(p)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// data-URL characters ≈ bytes over the wire (base64 already includes the
/// ~33% inflation), so the char count IS the approximate download size.
String _approxMb(int chars) {
  if (chars <= 0) return '? MB';
  final mb = chars / (1024 * 1024);
  return mb >= 0.95 ? '${mb.toStringAsFixed(1)} MB' : '${(chars / 1024).round()} KB';
}

String _day(String iso) => iso.length >= 10 ? iso.substring(0, 10) : iso;

Color _hex(String hex) {
  final h = hex.replaceFirst('#', '');
  if (h.length == 6) {
    final v = int.tryParse(h, radix: 16);
    if (v != null) return Color(0xFF000000 | v);
  }
  return Colors.blueGrey;
}
