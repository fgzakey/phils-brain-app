import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../app_state.dart';
import '../main.dart';
import '../models.dart';
import '../scribe_svg.dart';
import '../md_toc.dart';

/// Visual Scribe — turn a syntopical essay into a hand-drawn board (whiteboard,
/// memory palace, or knowledge-graph map) with embedded AI-painted art. A
/// mnemonic tool: the essay's argument becomes something you can picture.
class ScribeScreen extends StatefulWidget {
  const ScribeScreen({super.key});

  @override
  State<ScribeScreen> createState() => _ScribeScreenState();
}

class _ScribeScreenState extends State<ScribeScreen> {
  Essay? _essay;
  String _mode = 'palace'; // default to memory palace — the mnemonic tool
  String _artStyle = 'marker';
  bool _genImages = true;
  bool _running = false;
  String _status = '';
  String? _error;

  Map<String, dynamic>? _rec; // {svg, spec, images, ...}
  WebViewController? _web;
  String _loadedSvg = '';

  @override
  void initState() {
    super.initState();
    // Make sure essays are available to pick from.
    Future.microtask(() {
      final s = context.read<AppState>();
      if (s.essays.isEmpty) s.refreshEssays();
    });
  }

  Future<void> _run() async {
    final state = context.read<AppState>();
    if (_essay == null) {
      setState(() => _error = 'Pick an essay first.');
      return;
    }
    final src = _essay!.body.trim();
    if (src.isEmpty) {
      setState(() => _error = 'That essay has no text to work from.');
      return;
    }
    if (state.model.isEmpty) {
      setState(() => _error = 'Pick a model in Settings first.');
      return;
    }
    setState(() {
      _running = true;
      _error = null;
      _status = 'Designing the board…';
    });
    try {
      final data = await state.api.scribeSpec(
        booktext: src,
        title: _essay!.title,
        textModel: state.model,
        mode: _mode,
        artStyle: _artStyle,
        temperature: state.temperature,
      );
      final spec = Map<String, dynamic>.from(data['spec'] as Map);
      setState(() => _rec = {'spec': spec, 'images': [], 'svg': buildScribeSvg(spec, [])});

      final jobs = _genImages
          ? ((spec['illustrations'] as List?) ?? [])
              .whereType<Map>()
              .where((j) => (j['prompt'] ?? '').toString().isNotEmpty)
              .take(3)
              .toList()
          : <Map>[];
      if (jobs.isNotEmpty) {
        final ctx = (spec['title'] ?? '').toString().isNotEmpty
            ? 'Illustration for "${spec['title']}". '
            : '';
        final images = <Map<String, dynamic>>[];
        for (var i = 0; i < jobs.length; i++) {
          if (mounted) {
            setState(() => _status = 'Painting illustration ${i + 1} of ${jobs.length}…');
          }
          try {
            final url = await state.api.scribeImage(
              imagePrompt: jobs[i]['prompt'].toString(),
              imageContext: ctx,
              artStyle: _artStyle,
              imageModel: state.scribeImageModel,
            );
            images.add({
              'role': (jobs[i]['role'] ?? (i == 0 ? 'hero' : 'spot')).toString(),
              'url': url,
            });
          } catch (_) {/* skip a failed illustration */}
        }
        if (mounted) {
          setState(() => _rec = {
                'spec': spec,
                'images': images,
                'svg': buildScribeSvg(spec, images),
              });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    if (mounted) {
      setState(() {
        _running = false;
        _status = '';
      });
    }
  }

  Future<void> _shareSvg() async {
    final svg = (_rec?['svg'] ?? '').toString();
    if (svg.isEmpty) return;
    final dir = await getTemporaryDirectory();
    final name =
        downloadName(title: _essay?.title ?? 'Whiteboard', kind: 'Whiteboard', ext: 'svg');
    final file = File('${dir.path}/$name');
    await file.writeAsString(svg);
    await Share.shareXFiles([XFile(file.path, mimeType: 'image/svg+xml')],
        subject: _essay?.title);
  }

  Widget _board(String svg) {
    if (_web == null || _loadedSvg != svg) {
      _web ??= WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFFFFFFF));
      _loadedSvg = svg;
      _web!.loadHtmlString(
          '<!doctype html><html><head><meta name="viewport" content="width=device-width, initial-scale=1"><style>html,body{margin:0;padding:0;background:#fff}svg{width:100%;height:auto;display:block}</style></head><body>$svg</body></html>');
    }
    return LayoutBuilder(builder: (context, c) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
            width: c.maxWidth,
            height: c.maxWidth / 1.6,
            child: WebViewWidget(controller: _web!)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rec = _rec;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Scribe'),
        actions: [
          const TextSizeButtons(),
          if (rec != null)
            IconButton(
                icon: const Icon(Icons.share_outlined), onPressed: _shareSvg),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(
            'Turn a syntopical essay into a hand-drawn board — a whiteboard, a memory palace, or a knowledge map — with AI-painted art. A mnemonic tool for the library\'s ideas.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<Essay>(
            initialValue: _essay,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'Essay', border: OutlineInputBorder(), isDense: true),
            items: state.essays
                .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.title, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) => setState(() => _essay = v),
          ),
          if (state.essays.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('No essays loaded yet — open the Essays tab to fetch them.',
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _mode,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'Board mode',
                border: OutlineInputBorder(),
                isDense: true),
            items: scribeModes
                .map((m) => DropdownMenuItem(value: m.id, child: Text(m.name)))
                .toList(),
            onChanged: (v) => setState(() => _mode = v ?? 'palace'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _artStyle,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'Art style',
                border: OutlineInputBorder(),
                isDense: true),
            items: scribeArtStyles
                .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                .toList(),
            onChanged: (v) => setState(() => _artStyle = v ?? 'marker'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Generate embedded AI illustration(s)'),
            value: _genImages,
            onChanged: (v) => setState(() => _genImages = v),
          ),
          FilledButton.icon(
            icon: _running
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.draw_outlined),
            label: Text(_running
                ? (_status.isEmpty ? 'Drawing…' : _status)
                : (rec != null ? 'Re-draw board' : 'Generate board')),
            onPressed: _running ? null : _run,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          if (rec != null) ...[
            const SizedBox(height: 14),
            _board((rec['svg'] ?? '').toString()),
          ],
        ],
      ),
    );
  }
}
