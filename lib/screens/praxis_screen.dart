import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../main.dart';
import '../md_zoom.dart';
import '../models.dart';

/// Praxis — two modes over the same idea. The Spine tab browses themes →
/// goals → projects → tasks linked by serves/enacts edges; the Insights tab
/// reviews every Q4 flourishing insight across the library as flash-cards.
class PraxisScreen extends StatefulWidget {
  const PraxisScreen({super.key});

  @override
  State<PraxisScreen> createState() => _PraxisScreenState();
}

class _PraxisScreenState extends State<PraxisScreen>
    with SingleTickerProviderStateMixin {
  bool _loadedOnce = false;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

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
        title: const Text('Praxis'),
        actions: [
          const TextSizeButtons(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _tabs.index == 0
                ? (state.loadingPraxis ? null : state.refreshPraxis())
                : (state.loadingInsights ? null : state.refreshInsights()),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Spine'), Tab(text: 'Insights')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _spineBody(context, state),
          const InsightsTab(),
        ],
      ),
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
    });
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

/// Flash-card review of every Q4 flourishing insight across the library
/// (/api/graph/insights). Filter by theme and source, swipe through the deck,
/// tap a card to reveal where it came from.
class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key});

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  bool _loadedOnce = false;
  String? _theme; // slug, null = all
  String? _source; // source title, null = all
  final Set<int> _revealed = {};
  final PageController _pager = PageController();

  // TabBarView builds this tab the first time it is shown, so loading here
  // keeps Insights lazy: no request until the tab is opened.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      Future.microtask(() {
        if (!mounted) return;
        final s = context.read<AppState>();
        if (s.insights == null) s.refreshInsights();
      });
    }
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _setFilter({String? theme, bool themeSet = false, String? source, bool sourceSet = false}) {
    setState(() {
      if (themeSet) _theme = theme;
      if (sourceSet) _source = source;
      _revealed.clear();
    });
    if (_pager.hasClients) _pager.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final ins = state.insights;

    if (state.loadingInsights && ins == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.insightsError != null && ins == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Could not load insights:\n${state.insightsError}',
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => state.refreshInsights(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (ins == null || ins.cards.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No insights yet.\nRun the Adler prompts on a book or video and its Question 4 insights will land here.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final cards = ins.cards
        .where((c) => _theme == null || c.theme == _theme)
        .where((c) => _source == null || c.source == _source)
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${ins.total} insights · ${ins.sourceCount} sources',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (_theme != null || _source != null)
                TextButton(
                  onPressed: () =>
                      _setFilter(theme: null, themeSet: true, source: null, sourceSet: true),
                  child: const Text('Clear filters'),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final t in ins.themes)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: ChoiceChip(
                    label: Text('${t.title} (${t.count})'),
                    selected: _theme == t.slug,
                    onSelected: (sel) =>
                        _setFilter(theme: sel ? t.slug : null, themeSet: true),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final b in ins.books)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: ChoiceChip(
                    label: Text('${b.source} (${b.count})'),
                    selected: _source == b.source,
                    onSelected: (sel) =>
                        _setFilter(source: sel ? b.source : null, sourceSet: true),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: cards.isEmpty
              ? const Center(child: Text('No cards match these filters.'))
              : PageView.builder(
                  controller: _pager,
                  itemCount: cards.length,
                  itemBuilder: (context, i) => _card(context, cards, i),
                ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, List<InsightCard> cards, int i) {
    final c = cards[i];
    final revealed = _revealed.contains(i);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() {
            revealed ? _revealed.remove(i) : _revealed.add(i);
          }),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${i + 1} / ${cards.length}',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(c.text, style: theme.textTheme.titleMedium),
                  ),
                ),
                const SizedBox(height: 12),
                if (revealed)
                  Row(
                    children: [
                      Icon(
                        c.kind == 'video'
                            ? Icons.ondemand_video_outlined
                            : Icons.menu_book_outlined,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(c.source,
                            style: theme.textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(c.themeTitle),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  )
                else
                  Text('Tap to reveal source',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
