import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../main.dart';
import '../md_zoom.dart';
import '../models.dart';

/// Syntopical synthesis essays — the library's living Adlerian essays that
/// weave one idea/theme across every analyzed source. Read-only viewer.
class EssaysScreen extends StatefulWidget {
  const EssaysScreen({super.key});

  @override
  State<EssaysScreen> createState() => _EssaysScreenState();
}

class _EssaysScreenState extends State<EssaysScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Syntopical essays'),
        actions: [
          const TextSizeButtons(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.loadingEssays ? null : () => state.refreshEssays(),
          ),
        ],
      ),
      body: Builder(builder: (context) {
        if (state.loadingEssays && state.essays.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.essaysError != null && state.essays.isEmpty) {
          return _ErrorBox(
              message: state.essaysError!, onRetry: () => state.refreshEssays());
        }
        if (state.essays.isEmpty) {
          return const _EmptyBox(
            text:
                'No syntopical essays yet.\nSynthesize an idea or theme in the web dashboard and it will appear here.',
          );
        }
        return RefreshIndicator(
          onRefresh: () => state.refreshEssays(),
          child: ListView.separated(
            itemCount: state.essays.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = state.essays[i];
              return ListTile(
                leading: const Icon(Icons.auto_stories_outlined),
                title: Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text([
                  if ((e.targetTitle ?? '').isNotEmpty) 'on ${e.targetTitle}',
                  if ((e.updatedAt ?? '').isNotEmpty) e.updatedAt!.split('T').first,
                ].join(' · ')),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => _EssayViewer(essay: e))),
              );
            },
          ),
        );
      }),
    );
  }
}

class _EssayViewer extends StatelessWidget {
  final Essay essay;
  const _EssayViewer({required this.essay});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(essay.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          const TextSizeButtons(),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: essay.body));
              showSnack(context, 'Essay copied.');
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: essay.body.trim().isEmpty
          ? const Center(child: Text('This essay has no text yet.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ZoomMd(data: essay.body, scrollable: true),
            ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBox({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(text, textAlign: TextAlign.center)),
      );
}
