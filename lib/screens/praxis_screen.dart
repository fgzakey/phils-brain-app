import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../main.dart';
import '../md_zoom.dart';
import '../models.dart';

/// Praxis spine — themes → goals → projects → tasks, linked by serves/enacts
/// edges. This is the skeleton for the cognitive/planning tools: browse the
/// spine and add goals, projects and tasks hung off any node.
class PraxisScreen extends StatefulWidget {
  const PraxisScreen({super.key});

  @override
  State<PraxisScreen> createState() => _PraxisScreenState();
}

class _PraxisScreenState extends State<PraxisScreen> {
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      Future.microtask(() => context.read<AppState>().refreshPraxis());
    }
  }

  /// Children of [parent] via serves/enacts edges (child --serves--> parent).
  List<PraxisNode> _childrenOf(AppState s, PraxisNode parent) {
    final childIds = s.praxisEdges
        .where((e) => '${e.to}' == '${parent.id}')
        .map((e) => '${e.from}')
        .toSet();
    return s.praxisNodes.where((n) => childIds.contains('${n.id}')).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final themes = state.praxisNodes.where((n) => n.nodeType == 'theme').toList();
    // Goals whose parent isn't in the set show at the top level too.
    final topGoals = state.praxisNodes.where((n) {
      if (n.nodeType != 'goal') return false;
      final hasThemeParent = state.praxisEdges.any((e) =>
          '${e.from}' == '${n.id}' &&
          themes.any((t) => '${t.id}' == '${e.to}'));
      return !hasThemeParent;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Praxis'),
        actions: [
          const TextSizeButtons(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.loadingPraxis ? null : () => state.refreshPraxis(),
          ),
        ],
      ),
      body: Builder(builder: (context) {
        if (state.loadingPraxis && state.praxisNodes.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.praxisError != null && state.praxisNodes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Could not load praxis:\n${state.praxisError}',
                  textAlign: TextAlign.center),
            ),
          );
        }
        if (state.praxisNodes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No praxis nodes yet.\nThemes, goals, projects and tasks will appear here as the spine grows.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => state.refreshPraxis(),
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              for (final t in themes) _node(context, state, t, 0),
              if (topGoals.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Text('Goals',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                for (final g in topGoals) _node(context, state, g, 0),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _node(BuildContext context, AppState state, PraxisNode n, int depth) {
    final children = _childrenOf(state, n);
    final tile = Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: children.isEmpty
          ? ListTile(
              dense: depth > 0,
              leading: _icon(n.nodeType),
              title: Text(n.title),
              subtitle: n.body.isEmpty
                  ? null
                  : Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: _addButton(context, state, n),
              onTap: n.body.isEmpty ? null : () => _showBody(context, n),
            )
          : ExpansionTile(
              initiallyExpanded: depth == 0,
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              leading: _icon(n.nodeType),
              title: Text(n.title),
              subtitle: Text('${children.length} under this',
                  style: Theme.of(context).textTheme.bodySmall),
              trailing: _addButton(context, state, n),
              children:
                  children.map((c) => _node(context, state, c, depth + 1)).toList(),
            ),
    );
    return tile;
  }

  Widget _icon(String type) {
    switch (type) {
      case 'theme':
        return const Icon(Icons.category_outlined);
      case 'goal':
        return const Icon(Icons.flag_outlined);
      case 'project':
        return const Icon(Icons.rocket_launch_outlined);
      default:
        return const Icon(Icons.check_circle_outline);
    }
  }

  /// Add a child (goal under theme, project under goal, task under project).
  Widget? _addButton(BuildContext context, AppState state, PraxisNode parent) {
    final childType = switch (parent.nodeType) {
      'theme' => 'goal',
      'goal' => 'project',
      'project' => 'task',
      _ => null,
    };
    if (childType == null) return null;
    return IconButton(
      icon: const Icon(Icons.add),
      tooltip: 'Add $childType',
      onPressed: () => _addChild(context, state, parent, childType),
    );
  }

  Future<void> _addChild(BuildContext context, AppState state, PraxisNode parent,
      String childType) async {
    final ctl = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New $childType'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: '$childType title',
            helperText: 'Serves: ${parent.title}',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctl.text.trim()),
              child: const Text('Add')),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;
    try {
      await state.api.addPraxis(
          type: childType, title: title, servesSlug: parent.slug);
      await state.refreshPraxis();
      if (context.mounted) showSnack(context, 'Added $childType.');
    } catch (e) {
      if (context.mounted) showSnack(context, 'Add failed: $e');
    }
  }

  void _showBody(BuildContext context, PraxisNode n) {
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
              Text(n.title,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              ZoomMd(data: n.body),
            ],
          ),
        ),
      ),
    );
  }
}
