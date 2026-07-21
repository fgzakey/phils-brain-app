// Data models mirroring the Phils Library backend's graph/synthesis shapes.

/// A syntopical synthesis essay (served by /api/essays). [body] is Markdown.
class Essay {
  final dynamic id;
  final String slug;
  final String title;
  final String body;
  final String? targetTitle;
  final String? targetType;
  final String? updatedAt;

  Essay({
    this.id,
    required this.slug,
    required this.title,
    required this.body,
    this.targetTitle,
    this.targetType,
    this.updatedAt,
  });

  factory Essay.fromJson(Map<String, dynamic> j) => Essay(
        id: j['id'],
        slug: j['slug']?.toString() ?? '',
        title: j['title']?.toString() ?? 'Untitled essay',
        body: j['body']?.toString() ?? '',
        targetTitle: j['target_title']?.toString(),
        targetType: j['target_type']?.toString(),
        updatedAt: j['updated_at']?.toString(),
      );
}

/// Conceptual-level counts from /api/graph?stats=1.
class GraphStats {
  final int nodes;
  final int edges;
  final List<TypeCount> byNodeType;
  final List<TypeCount> byEdgeType;
  final int apexServes;
  final int pendingEmbeddings;

  GraphStats({
    this.nodes = 0,
    this.edges = 0,
    this.byNodeType = const [],
    this.byEdgeType = const [],
    this.apexServes = 0,
    this.pendingEmbeddings = 0,
  });

  factory GraphStats.fromJson(Map<String, dynamic> j) => GraphStats(
        nodes: (j['nodes'] as num?)?.toInt() ?? 0,
        edges: (j['edges'] as num?)?.toInt() ?? 0,
        byNodeType: ((j['byNodeType'] as List?) ?? [])
            .map((e) => TypeCount.fromJson(Map<String, dynamic>.from(e), 'node_type'))
            .toList(),
        byEdgeType: ((j['byEdgeType'] as List?) ?? [])
            .map((e) => TypeCount.fromJson(Map<String, dynamic>.from(e), 'edge_type'))
            .toList(),
        apexServes: (j['apexServes'] as num?)?.toInt() ?? 0,
        pendingEmbeddings: (j['pendingEmbeddings'] as num?)?.toInt() ?? 0,
      );
}

class TypeCount {
  final String type;
  final int n;
  TypeCount(this.type, this.n);
  factory TypeCount.fromJson(Map<String, dynamic> j, String key) =>
      TypeCount(j[key]?.toString() ?? '?', (j['n'] as num?)?.toInt() ?? 0);
}

/// A knowledge-graph node (list row from /api/graph).
class GraphNode {
  final dynamic id;
  final String slug;
  final String nodeType;
  final String title;
  final List<String> domains;
  final int? truth, good, beauty, relevance;
  final String? sourceKind;
  final String? sourceId;
  final String? updatedAt;

  GraphNode({
    this.id,
    required this.slug,
    required this.nodeType,
    required this.title,
    this.domains = const [],
    this.truth,
    this.good,
    this.beauty,
    this.relevance,
    this.sourceKind,
    this.sourceId,
    this.updatedAt,
  });

  factory GraphNode.fromJson(Map<String, dynamic> j) => GraphNode(
        id: j['id'],
        slug: j['slug']?.toString() ?? '',
        nodeType: j['node_type']?.toString() ?? 'idea',
        title: j['title']?.toString() ?? '(untitled)',
        domains: ((j['domains'] as List?) ?? []).map((e) => e.toString()).toList(),
        truth: (j['truth'] as num?)?.toInt(),
        good: (j['good'] as num?)?.toInt(),
        beauty: (j['beauty'] as num?)?.toInt(),
        relevance: (j['relevance'] as num?)?.toInt(),
        sourceKind: j['source_kind']?.toString(),
        sourceId: j['source_id']?.toString(),
        updatedAt: j['updated_at']?.toString(),
      );
}

/// Full node detail + its edges (from /api/graph?nodeId=…).
class NodeDetail {
  final GraphNode node;
  final String body;
  final List<GraphEdge> edgesOut;
  final List<GraphEdge> edgesIn;

  NodeDetail({
    required this.node,
    this.body = '',
    this.edgesOut = const [],
    this.edgesIn = const [],
  });

  factory NodeDetail.fromJson(Map<String, dynamic> j) {
    final n = Map<String, dynamic>.from(j['node'] as Map);
    return NodeDetail(
      node: GraphNode.fromJson(n),
      body: n['body']?.toString() ?? '',
      edgesOut: ((j['edgesOut'] as List?) ?? [])
          .map((e) => GraphEdge.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      edgesIn: ((j['edgesIn'] as List?) ?? [])
          .map((e) => GraphEdge.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class GraphEdge {
  final dynamic id; // the OTHER node's id
  final String edgeType;
  final String nodeType;
  final String title;

  GraphEdge({this.id, required this.edgeType, required this.nodeType, required this.title});

  factory GraphEdge.fromJson(Map<String, dynamic> j) => GraphEdge(
        id: j['id'],
        edgeType: j['edge_type']?.toString() ?? 'related',
        nodeType: j['node_type']?.toString() ?? 'idea',
        title: j['title']?.toString() ?? '(untitled)',
      );
}

/// A praxis node (theme / goal / project / task) from /api/graph/praxis.
class PraxisNode {
  final dynamic id;
  final String slug;
  final String nodeType; // theme | goal | project | task
  final String title;
  final String body;
  final List<String> domains;

  PraxisNode({
    this.id,
    required this.slug,
    required this.nodeType,
    required this.title,
    this.body = '',
    this.domains = const [],
  });

  factory PraxisNode.fromJson(Map<String, dynamic> j) => PraxisNode(
        id: j['id'],
        slug: j['slug']?.toString() ?? '',
        nodeType: j['node_type']?.toString() ?? 'task',
        title: j['title']?.toString() ?? '(untitled)',
        body: j['body']?.toString() ?? '',
        domains: ((j['domains'] as List?) ?? []).map((e) => e.toString()).toList(),
      );
}

/// One serves/enacts edge in the praxis spine (by node id).
class PraxisEdge {
  final dynamic from;
  final dynamic to;
  final String edgeType;
  PraxisEdge({this.from, this.to, required this.edgeType});
  factory PraxisEdge.fromJson(Map<String, dynamic> j) => PraxisEdge(
        from: j['from_node'],
        to: j['to_node'],
        edgeType: j['edge_type']?.toString() ?? 'serves',
      );
}

class ModelInfo {
  final String id;
  final String name;
  ModelInfo({required this.id, required this.name});
  factory ModelInfo.fromJson(Map<String, dynamic> j) =>
      ModelInfo(id: j['id'] as String, name: j['name'] as String? ?? j['id'] as String);
}

class ChatResponse {
  final String content;
  final String? model;
  final Map<String, dynamic>? usage;
  ChatResponse({required this.content, this.model, this.usage});
}

// ---- Visual Scribe options (ids must match lib/prompts.js on the server) ----

class ScribeOption {
  final String id;
  final String name;
  const ScribeOption(this.id, this.name);
}

const scribeModes = [
  ScribeOption('whiteboard', 'Whiteboard (graphic recording)'),
  ScribeOption('palace', 'Memory palace (method of loci)'),
  ScribeOption('graph', 'Knowledge graph (semantic map)'),
];

const scribeArtStyles = [
  ScribeOption('marker', 'Whiteboard marker (classic)'),
  ScribeOption('editorial', 'Editorial ink'),
  ScribeOption('isometric', 'Isometric diorama'),
  ScribeOption('codex', 'Da Vinci codex'),
  ScribeOption('watercolor', 'Watercolor sketchnote'),
  ScribeOption('retro', 'Retro-futurist poster'),
  ScribeOption('chalk', 'Chalkboard chiaroscuro'),
];
