import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../main.dart';
import '../md_zoom.dart';
import '../models.dart';

/// Knowledge graph at the conceptual level: headline counts, a breakdown by
/// node/edge type, and a browsable, filterable node list. Tapping a node opens
/// its detail (body + typed edges in and out).
class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  bool _loadedOnce = false;
  String _type = '';
  final _search = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      Future.microtask(() {
        if (mounted) context.read<AppState>().refreshGraph();
      });
    }
  }

  void _reload() => context
      .read<AppState>()
      .refreshGraph(type: _type.isEmpty ? null : _type, query: _search.text.trim());

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final stats = state.stats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge graph'),
        actions: [
          const TextSizeButtons(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.loadingGraph
                ? null
                : () {
                    state.stats = null; // force a stats reload too
                    _reload();
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          if (stats != null) _StatsHeader(stats: stats),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search nodes…',
                isDense: true,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward), onPressed: _reload),
              ),
              onSubmitted: (_) => _reload(),
            ),
          ),
          if (stats != null && stats.byNodeType.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _typeChip('All', ''),
                  ...stats.byNodeType.map((t) => _typeChip('${t.type} (${t.n})', t.type)),
                ],
              ),
            ),
          if (state.loadingGraph) const LinearProgressIndicator(),
          Expanded(
            child: Builder(builder: (context) {
              if (state.graphError != null && state.nodes.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not load the graph:\n${state.graphError}',
                        textAlign: TextAlign.center),
                  ),
                );
              }
              if (state.nodes.isEmpty && !state.loadingGraph) {
                return const Center(child: Text('No nodes match.'));
              }
              return ListView.separated(
                itemCount: state.nodes.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final n = state.nodes[i];
                  return ListTile(
                    dense: true,
                    leading: _NodeTypeBadge(n.nodeType),
                    title: Text(n.title,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: n.domains.isEmpty
                        ? null
                        : Text(n.domains.join(' · '),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => NodeDetailScreen(nodeId: n.id, title: n.title))),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _typeChip(String label, String type) {
    final selected = _type == type;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _type = type);
          _reload();
        },
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final GraphStats stats;
  const _StatsHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _stat('${stats.nodes}', 'nodes'),
              _stat('${stats.edges}', 'edges'),
              _stat('${stats.apexServes}', 'serve the apex'),
              if (stats.pendingEmbeddings > 0)
                _stat('${stats.pendingEmbeddings}', 'pending embeddings'),
            ],
          ),
          if (stats.byEdgeType.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Relations: ${stats.byEdgeType.map((e) => '${e.type} ×${e.n}').join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String big, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(big, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(label),
        ],
      );
}

class _NodeTypeBadge extends StatelessWidget {
  final String type;
  const _NodeTypeBadge(this.type);

  static const _icons = {
    'theme': Icons.category_outlined,
    'idea': Icons.lightbulb_outline,
    'note': Icons.sticky_note_2_outlined,
    'goal': Icons.flag_outlined,
    'project': Icons.rocket_launch_outlined,
    'task': Icons.check_circle_outline,
    'source': Icons.description_outlined,
  };

  @override
  Widget build(BuildContext context) =>
      Icon(_icons[type] ?? Icons.circle_outlined, size: 22);
}

/// Node detail: title, type, body (Markdown) and its typed edges.
class NodeDetailScreen extends StatefulWidget {
  final dynamic nodeId;
  final String title;
  const NodeDetailScreen({super.key, required this.nodeId, required this.title});

  @override
  State<NodeDetailScreen> createState() => _NodeDetailScreenState();
}

class _NodeDetailScreenState extends State<NodeDetailScreen> {
  NodeDetail? _detail;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await context.read<AppState>().api.getNode(widget.nodeId);
      if (mounted) setState(() => _detail = d);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: const [TextSizeButtons(), SizedBox(width: 4)],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load node:\n$_error',
                      textAlign: TextAlign.center)))
          : d == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Chip(label: Text(d.node.nodeType)),
                        for (final dom in d.node.domains) Chip(label: Text(dom)),
                        if (d.node.truth != null)
                          Chip(label: Text('T ${d.node.truth}')),
                        if (d.node.good != null) Chip(label: Text('G ${d.node.good}')),
                        if (d.node.beauty != null)
                          Chip(label: Text('B ${d.node.beauty}')),
                        if (d.node.relevance != null)
                          Chip(label: Text('R ${d.node.relevance}')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (d.body.trim().isNotEmpty)
                      ZoomMd(data: d.body)
                    else
                      const Text('No body text for this node.'),
                    if (d.edgesOut.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Points to',
                          style: Theme.of(context).textTheme.titleMedium),
                      ..._edges(context, d.edgesOut),
                    ],
                    if (d.edgesIn.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Pointed to by',
                          style: Theme.of(context).textTheme.titleMedium),
                      ..._edges(context, d.edgesIn),
                    ],
                  ],
                ),
    );
  }

  List<Widget> _edges(BuildContext context, List<GraphEdge> edges) => edges
      .map((e) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: _NodeTypeBadge(e.nodeType),
            title: Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(e.edgeType),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        NodeDetailScreen(nodeId: e.id, title: e.title))),
          ))
      .toList();
}
