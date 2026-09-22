import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../main.dart';
import '../md_zoom.dart';
import '../models.dart';
import '../virtues.dart';

/// Praxis — the spine: themes → goals → projects → tasks linked by
/// serves/enacts edges, plus the Aristotelian Golden Mean Virtue Compass.
///
/// The Insights flash-cards used to be a second tab here. They moved to the
/// Syntopical essays screen (2026-08-07) to match the web dashboards, where
/// 🎴 Insights left 🕸 Graph → Praxis for the Syntopicon: the insights are the
/// raw material the essays open with, not part of the goals board.
class PraxisScreen extends StatefulWidget {
  const PraxisScreen({super.key});

  @override
  State<PraxisScreen> createState() => _PraxisScreenState();
}

class _PraxisScreenState extends State<PraxisScreen> {
  bool _loadedOnce = false;
  String? _focusVirtueSlug;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      Future.microtask(() {
        if (mounted) context.read<AppState>().refreshPraxis();
      });
    }
  }

  VirtueDef get _currentFocusVirtue {
    if (_focusVirtueSlug != null) {
      final v = getVirtueBySlug(_focusVirtueSlug!);
      if (v != null) return v;
    }
    return getFocusVirtueForDate();
  }

  void _cycleFocusVirtue(int direction) {
    final cur = _currentFocusVirtue;
    final curIdx = kVirtues.indexWhere((v) => v.slug == cur.slug);
    final nextIdx = (curIdx + direction + kVirtues.length) % kVirtues.length;
    setState(() {
      _focusVirtueSlug = kVirtues[nextIdx].slug;
    });
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Praxis & Virtues'),
        actions: [
          const TextSizeButtons(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh praxis spine',
            onPressed: state.loadingPraxis ? null : () => state.refreshPraxis(),
          ),
        ],
      ),
      body: _spineBody(context, state),
    );
  }

  Widget _spineBody(BuildContext context, AppState state) {
    final themes = state.praxisNodes.where((n) => n.nodeType == 'theme').toList();
    // Goals whose parent isn't in the set show at the top level too.
    final topGoals = state.praxisNodes.where((n) {
      if (n.nodeType != 'goal') return false;
      final hasThemeParent = state.praxisEdges.any((e) =>
          '${e.from}' == '${n.id}' &&
          themes.any((t) => '${t.id}' == '${e.to}'));
      return !hasThemeParent;
    }).toList();

    return Builder(builder: (context) {
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

      return RefreshIndicator(
        onRefresh: () => state.refreshPraxis(),
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            _virtueCompassCard(context, state),
            const SizedBox(height: 8),
            if (state.praxisNodes.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No praxis nodes loaded yet.\nThemes, goals, projects, and virtue practices will appear here.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ] else ...[
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
          ],
        ),
      );
    });
  }

  Widget _virtueCompassCard(BuildContext context, AppState state) {
    final v = _currentFocusVirtue;
    final sphere = getSphereById(v.sphere);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row with cycle arrows
            Row(
              children: [
                const Icon(Icons.explore_outlined, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Virtue Compass · El Justo Medio',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Focus Virtue · Character & Personality',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_left, size: 20),
                  tooltip: 'Previous virtue',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _cycleFocusVirtue(-1),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_right, size: 20),
                  tooltip: 'Next virtue',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _cycleFocusVirtue(1),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Sphere badge & title
            Row(
              children: [
                Text(
                  '${sphere?.icon ?? '🏛️'} ${sphere?.titleEn ?? ''}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.secondary,
                  ),
                ),
                const Spacer(),
                Text(
                  sphere?.titleEs ?? '',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Main Golden Mean Continuum
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  // Deficiency
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Deficiency (−)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          v.deficiencyEn,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          v.deficiencyEs,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Text(' ↔ ', style: TextStyle(color: Colors.grey)),
                  // Golden Mean (Center Highlight)
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '🎯 The Mean',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            v.virtueEn,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            v.virtueEs,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Text(' ↔ ', style: TextStyle(color: Colors.grey)),
                  // Excess
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Excess (+)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          v.excessEn,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          v.excessEs,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Poetic Aphorism
            Text(
              '“${v.poeticEn}”',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Quick Actions: Enact with task / 32 Virtues Catalog
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.list_alt, size: 16),
                  label: const Text('32 Virtues'),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => _showAllVirtuesSheet(context, state),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add_task, size: 16),
                  label: const Text('Enact with task'),
                  style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                  onPressed: () => _enactVirtue(context, state, v),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAllVirtuesSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtl) => ListView(
          controller: scrollCtl,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            Text(
              '32 Canonical Virtues & 6 Spheres',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              'Aristotelian Character & Personality Continuum (Deficiency ↔ Mean ↔ Excess)',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final s in kVirtueSpheres) ...[
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 6),
                child: Row(
                  children: [
                    Text(s.icon, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${s.titleEn} (${s.titleEs})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              for (final v in kVirtues.where((item) => item.sphere == s.id))
                ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                  title: Text(
                    '🎯 ${v.virtueEn} (${v.virtueEs})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '− ${v.deficiencyEn}  |  + ${v.excessEn}\n“${v.poeticEn}”',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _focusVirtueSlug = v.slug;
                      });
                    },
                    child: const Text('Focus'),
                  ),
                ),
              const Divider(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _enactVirtue(BuildContext context, AppState state, VirtueDef v) async {
    final ctl = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Enact ${v.virtueEn}'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Task title',
            helperText: 'Enacts: ${v.virtueEn} (${v.virtueEs})',
          ),
          onSubmitted: (val) => Navigator.pop(ctx, val.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctl.text.trim()),
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
    if (title == null || title.isEmpty) return;

    try {
      await state.api.addPraxis(
        type: 'task',
        title: title,
        servesSlug: v.slug,
        enactsSlug: v.slug,
      );
      await state.refreshPraxis();
      if (context.mounted) showSnack(context, 'Enacted ${v.virtueEn} with new task.');
    } catch (e) {
      if (context.mounted) showSnack(context, 'Failed to add task: $e');
    }
  }

  Widget _node(BuildContext context, AppState state, PraxisNode n, int depth) {
    final children = _childrenOf(state, n);
    final isVirtue = n.isVirtue;
    final vDef = isVirtue ? getVirtueBySlug(n.slug) : null;
    final vm = n.virtueMeta;

    Widget? subtitleWidget;
    if (isVirtue && (vDef != null || vm != null)) {
      final defEn = vDef?.deficiencyEn ?? vm?.deficiencyEn ?? '';
      final meanEn = vDef?.virtueEn ?? vm?.virtueEn ?? n.title;
      final excEn = vDef?.excessEn ?? vm?.excessEn ?? '';
      final poetic = vDef?.poeticEn ?? vm?.poeticEn ?? '';

      subtitleWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '− $defEn ↔ 🎯 $meanEn ↔ + $excEn',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.teal),
          ),
          if (poetic.isNotEmpty)
            Text(
              '“$poetic”',
              style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      );
    } else if (n.body.isNotEmpty) {
      subtitleWidget = Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis);
    }

    final tile = Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: children.isEmpty
          ? ListTile(
              dense: depth > 0,
              leading: _icon(n.nodeType),
              title: Text(n.title),
              subtitle: subtitleWidget,
              trailing: _addButton(context, state, n),
              onTap: (n.body.isNotEmpty || isVirtue) ? () => _showBody(context, n) : null,
            )
          : ExpansionTile(
              initiallyExpanded: depth == 0,
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              leading: _icon(n.nodeType),
              title: Text(n.title),
              subtitle: subtitleWidget ??
                  Text('${children.length} under this',
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
      case 'practice':
        return const Icon(Icons.auto_awesome, color: Colors.amber);
      default:
        return const Icon(Icons.check_circle_outline);
    }
  }

  /// Add a child (goal under theme, project under goal, task under project or practice).
  Widget? _addButton(BuildContext context, AppState state, PraxisNode parent) {
    final childType = switch (parent.nodeType) {
      'theme' => 'goal',
      'goal' => 'project',
      'project' => 'task',
      'practice' => 'task',
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
    final isPractice = parent.nodeType == 'practice';
    final title = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('New $childType'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: '$childType title',
            helperText: isPractice
                ? 'Enacts virtue: ${parent.title}'
                : 'Serves: ${parent.title}',
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
        type: childType,
        title: title,
        servesSlug: parent.slug,
        enactsSlug: isPractice ? parent.slug : null,
      );
      await state.refreshPraxis();
      if (context.mounted) showSnack(context, 'Added $childType.');
    } catch (e) {
      if (context.mounted) showSnack(context, 'Add failed: $e');
    }
  }

  void _showBody(BuildContext context, PraxisNode n) {
    final vDef = n.isVirtue ? getVirtueBySlug(n.slug) : null;
    final vm = n.virtueMeta;

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
              if (n.isVirtue && (vDef != null || vm != null)) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🎯 Aristotelian Golden Mean Continuum',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• Deficiency (−): ${vDef?.deficiencyEn ?? vm?.deficiencyEn} (${vDef?.deficiencyEs ?? vm?.deficiencyEs})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        '• The Mean (🎯): ${vDef?.virtueEn ?? vm?.virtueEn} (${vDef?.virtueEs ?? vm?.virtueEs})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '• Excess (+): ${vDef?.excessEn ?? vm?.excessEn} (${vDef?.excessEs ?? vm?.excessEs})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '“${vDef?.poeticEn ?? vm?.poeticEn}”',
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                      ),
                      Text(
                        '“${vDef?.poeticEs ?? vm?.poeticEs}”',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (n.body.isNotEmpty) ZoomMd(data: n.body),
            ],
          ),
        ),
      ),
    );
  }
}
