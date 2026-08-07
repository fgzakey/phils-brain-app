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

/// One Q4 flourishing insight from /api/graph/insights.
class InsightCard {
  final String text;
  final String source; // book or video title
  final String kind; // book | video
  final String theme; // slug, "untagged" when the sweep could not tag it
  final String themeTitle;
  // Provenance. `sourceKey` ("<kind>:<title>") indexes InsightsResponse.sources;
  // `pos` is this bullet's place in that analysis's QUESTION 4 list.
  final String sourceKey;
  final int pos;

  InsightCard({
    required this.text,
    required this.source,
    required this.kind,
    required this.theme,
    required this.themeTitle,
    this.sourceKey = '',
    this.pos = 0,
  });

  factory InsightCard.fromJson(Map<String, dynamic> j) => InsightCard(
        text: j['text']?.toString() ?? '',
        source: j['source']?.toString() ?? '',
        kind: j['kind']?.toString() ?? 'book',
        theme: j['theme']?.toString() ?? 'untagged',
        themeTitle: j['themeTitle']?.toString() ?? 'Untagged',
        sourceKey: j['sourceKey']?.toString() ?? '',
        pos: (j['pos'] as num?)?.toInt() ?? 0,
      );
}

/// One analysis run that contributed insights — the `sources` map on
/// /api/graph/insights, keyed by `"<kind>:<title>"`. Sent once per analysis
/// rather than copied onto every card.
class InsightRun {
  final String key;
  final String kind;
  final String title;
  final String? promptName;
  final String? model;
  final String? createdAt;
  final int bulletCount;

  InsightRun({
    required this.key,
    required this.kind,
    required this.title,
    this.promptName,
    this.model,
    this.createdAt,
    this.bulletCount = 0,
  });

  factory InsightRun.fromJson(Map<String, dynamic> j) => InsightRun(
        key: j['key']?.toString() ?? '',
        kind: j['kind']?.toString() ?? 'book',
        title: j['title']?.toString() ?? '',
        promptName: j['promptName']?.toString(),
        model: j['model']?.toString(),
        createdAt: j['createdAt']?.toString(),
        bulletCount: (j['bulletCount'] as num?)?.toInt() ?? 0,
      );
}

class InsightTheme {
  final String slug;
  final String title;
  final int count;
  InsightTheme({required this.slug, required this.title, required this.count});
  factory InsightTheme.fromJson(Map<String, dynamic> j) => InsightTheme(
        slug: j['slug']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        count: (j['count'] as num?)?.toInt() ?? 0,
      );
}

class InsightSource {
  final String source;
  final int count;
  InsightSource({required this.source, required this.count});
  factory InsightSource.fromJson(Map<String, dynamic> j) => InsightSource(
        source: j['source']?.toString() ?? '',
        count: (j['count'] as num?)?.toInt() ?? 0,
      );
}

/// The whole /api/graph/insights payload.
class InsightsResponse {
  final List<InsightCard> cards;
  final List<InsightTheme> themes;
  final List<InsightSource> books;
  final Map<String, InsightRun> sources;
  final int total;
  final int sourceCount;

  InsightsResponse({
    this.cards = const [],
    this.themes = const [],
    this.books = const [],
    this.sources = const {},
    this.total = 0,
    this.sourceCount = 0,
  });

  /// Every OTHER insight the same source contributed to the same theme — the
  /// back of a card. Mirrors siblingInsights() in the web dashboard.
  List<String> siblingsOf(InsightCard c) => cards
      .where((o) =>
          !identical(o, c) &&
          o.source == c.source &&
          o.kind == c.kind &&
          o.theme == c.theme)
      .map((o) => o.text)
      .toList();

  factory InsightsResponse.fromJson(Map<String, dynamic> j) => InsightsResponse(
        cards: ((j['cards'] as List?) ?? [])
            .map((c) => InsightCard.fromJson(Map<String, dynamic>.from(c)))
            .toList(),
        themes: ((j['themes'] as List?) ?? [])
            .map((t) => InsightTheme.fromJson(Map<String, dynamic>.from(t)))
            .toList(),
        books: ((j['books'] as List?) ?? [])
            .map((b) => InsightSource.fromJson(Map<String, dynamic>.from(b)))
            .toList(),
        sources: ((j['sources'] as Map?) ?? {}).map((k, v) => MapEntry(
            k.toString(), InsightRun.fromJson(Map<String, dynamic>.from(v)))),
        total: (j['total'] as num?)?.toInt() ?? 0,
        sourceCount: (j['sourceCount'] as num?)?.toInt() ?? 0,
      );
}

/// ---- Essay sections (/api/graph/sections) ----
/// One movement of one synthesis essay, with its spaced-repetition state.
class SectionCard {
  final String essaySlug;
  final String essayTitle;
  final String kind; // practical (theme essay) | theoretical (Great Idea) | other
  final String lang; // English | Spanish | …
  final String key; // slugified heading, numbering stripped
  final String heading;
  final String text;
  final int order;
  final int pos; // movement N of sectionCount
  final int sectionCount;
  final int level; // 2 = movement, 3 = sub-movement
  final int words;
  final int reviewCount;
  final String? lastReviewed;
  final int intervalDays;
  final bool due;

  SectionCard({
    required this.essaySlug,
    required this.essayTitle,
    required this.kind,
    required this.lang,
    required this.key,
    required this.heading,
    required this.text,
    this.order = 0,
    this.pos = 0,
    this.sectionCount = 0,
    this.level = 2,
    this.words = 0,
    this.reviewCount = 0,
    this.lastReviewed,
    this.intervalDays = 1,
    this.due = true,
  });

  factory SectionCard.fromJson(Map<String, dynamic> j) => SectionCard(
        essaySlug: j['essaySlug']?.toString() ?? '',
        essayTitle: j['essayTitle']?.toString() ?? '',
        kind: j['kind']?.toString() ?? 'other',
        lang: j['lang']?.toString() ?? 'English',
        key: j['key']?.toString() ?? '',
        heading: j['heading']?.toString() ?? '',
        text: j['text']?.toString() ?? '',
        order: (j['order'] as num?)?.toInt() ?? 0,
        pos: (j['pos'] as num?)?.toInt() ?? 0,
        sectionCount: (j['sectionCount'] as num?)?.toInt() ?? 0,
        level: (j['level'] as num?)?.toInt() ?? 2,
        words: (j['words'] as num?)?.toInt() ?? 0,
        reviewCount: (j['reviewCount'] as num?)?.toInt() ?? 0,
        lastReviewed: j['lastReviewed']?.toString(),
        intervalDays: (j['intervalDays'] as num?)?.toInt() ?? 1,
        due: j['due'] == true,
      );
}

/// One synthesis essay in the sections payload.
class SectionEssay {
  final String slug;
  final String title;
  final String kind;
  final String lang;
  final int sections;
  final String? updatedAt;
  final String? model;
  final String? targetSlug;
  final List<String> sources; // the essay's own "## Sources" block

  SectionEssay({
    required this.slug,
    required this.title,
    required this.kind,
    required this.lang,
    this.sections = 0,
    this.updatedAt,
    this.model,
    this.targetSlug,
    this.sources = const [],
  });

  factory SectionEssay.fromJson(Map<String, dynamic> j) => SectionEssay(
        slug: j['slug']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        kind: j['kind']?.toString() ?? 'other',
        lang: j['lang']?.toString() ?? 'English',
        sections: (j['sections'] as num?)?.toInt() ?? 0,
        updatedAt: j['updated_at']?.toString(),
        model: j['model']?.toString(),
        targetSlug: j['targetSlug']?.toString(),
        sources:
            ((j['sources'] as List?) ?? []).map((e) => e.toString()).toList(),
      );
}

/// The whole /api/graph/sections payload.
class SectionsResponse {
  final List<SectionCard> cards;
  final List<SectionEssay> essays;
  final int total;
  final int dueCount;
  final int essayCount;
  final int practical;
  final int theoretical;

  SectionsResponse({
    this.cards = const [],
    this.essays = const [],
    this.total = 0,
    this.dueCount = 0,
    this.essayCount = 0,
    this.practical = 0,
    this.theoretical = 0,
  });

  SectionEssay? essayOf(String slug) {
    for (final e in essays) {
      if (e.slug == slug) return e;
    }
    return null;
  }

  /// The languages actually present, English first — the language toggle.
  List<String> get languages {
    final set = <String>{for (final e in essays) e.lang};
    final list = set.toList()
      ..sort((a, b) => a == 'English'
          ? -1
          : b == 'English'
              ? 1
              : a.compareTo(b));
    return list;
  }

  /// The rest of this movement's essay, in reading order — the card back.
  List<String> siblingsOf(SectionCard c) {
    final rest = cards
        .where((o) => !identical(o, c) && o.essaySlug == c.essaySlug)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return rest.map((o) => o.heading).toList();
  }

  factory SectionsResponse.fromJson(Map<String, dynamic> j) => SectionsResponse(
        cards: ((j['cards'] as List?) ?? [])
            .map((c) => SectionCard.fromJson(Map<String, dynamic>.from(c)))
            .toList(),
        essays: ((j['essays'] as List?) ?? [])
            .map((e) => SectionEssay.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        total: (j['total'] as num?)?.toInt() ?? 0,
        dueCount: (j['dueCount'] as num?)?.toInt() ?? 0,
        essayCount: (j['essayCount'] as num?)?.toInt() ?? 0,
        practical: (j['practical'] as num?)?.toInt() ?? 0,
        theoretical: (j['theoretical'] as num?)?.toInt() ?? 0,
      );
}

/// A source (book or video) that has at least one mnemonic scene
/// (/api/mnemonic?sources=1).
class MnemonicSource {
  final String sourceKind; // book | video
  final String sourceId;
  final String sourceTitle;
  final int imageCount;
  final int boardCount;
  final String? latest;

  MnemonicSource({
    required this.sourceKind,
    required this.sourceId,
    required this.sourceTitle,
    this.imageCount = 0,
    this.boardCount = 0,
    this.latest,
  });

  factory MnemonicSource.fromJson(Map<String, dynamic> j) => MnemonicSource(
        sourceKind: j['source_kind']?.toString() ?? 'book',
        sourceId: j['source_id']?.toString() ?? '',
        sourceTitle: j['source_title']?.toString() ?? '(untitled source)',
        imageCount: (j['image_count'] as num?)?.toInt() ?? 0,
        boardCount: (j['board_count'] as num?)?.toInt() ?? 0,
        latest: j['latest']?.toString(),
      );
}

/// One station of a mnemonic scene. [x]/[y] are 0..1 fractions of the SCENE
/// area's width/height (not the composed canvas, which extends a text panel to
/// the right). placed == "vision" means the vision pass located the station;
/// "legend" means it fell back and the pin coordinates are meaningless.
class MnemonicHotspot {
  final int i;
  final String heading;
  final String theme;
  final String colorHex;
  final List<String> points;
  final double? x;
  final double? y;
  final String placed; // vision | legend

  MnemonicHotspot({
    required this.i,
    required this.heading,
    this.theme = '',
    this.colorHex = '',
    this.points = const [],
    this.x,
    this.y,
    this.placed = 'legend',
  });

  factory MnemonicHotspot.fromJson(Map<String, dynamic> j) => MnemonicHotspot(
        i: (j['i'] as num?)?.toInt() ?? 0,
        heading: j['heading']?.toString() ?? '',
        theme: j['theme']?.toString() ?? '',
        colorHex: j['color']?.toString() ?? '',
        points: ((j['points'] as List?) ?? []).map((p) => p.toString()).toList(),
        x: (j['x'] as num?)?.toDouble(),
        y: (j['y'] as num?)?.toDouble(),
        placed: j['placed']?.toString() ?? 'legend',
      );
}

/// A mnemonic scene row. List rows carry [imageChars] (a length) instead of
/// the image; the single-row fetch carries the full base64 [image].
class MnemonicScene {
  final dynamic id;
  final String sourceKind;
  final String sourceId;
  final String sourceTitle;
  final String boardKey;
  final String variant;
  final String? style;
  final String? styleName;
  final String? model;
  final int? width;
  final int? height;
  final String? sourceResolution;
  final List<MnemonicHotspot> hotspots;
  final String? createdAt;
  final int imageChars;
  final String? image; // data URL, only on the ?id= fetch

  MnemonicScene({
    this.id,
    required this.sourceKind,
    required this.sourceId,
    required this.sourceTitle,
    required this.boardKey,
    this.variant = 'clean',
    this.style,
    this.styleName,
    this.model,
    this.width,
    this.height,
    this.sourceResolution,
    this.hotspots = const [],
    this.createdAt,
    this.imageChars = 0,
    this.image,
  });

  factory MnemonicScene.fromJson(Map<String, dynamic> j) {
    final image = j['image']?.toString();
    return MnemonicScene(
      id: j['id'],
      sourceKind: j['source_kind']?.toString() ?? 'book',
      sourceId: j['source_id']?.toString() ?? '',
      sourceTitle: j['source_title']?.toString() ?? '(untitled source)',
      boardKey: j['board_key']?.toString() ?? '',
      variant: j['variant']?.toString() ?? 'clean',
      style: j['style']?.toString(),
      styleName: j['style_name']?.toString(),
      model: j['model']?.toString(),
      width: (j['width'] as num?)?.toInt(),
      height: (j['height'] as num?)?.toInt(),
      sourceResolution: j['source_resolution']?.toString(),
      hotspots: ((j['hotspots'] as List?) ?? [])
          .map((h) => MnemonicHotspot.fromJson(Map<String, dynamic>.from(h)))
          .toList(),
      createdAt: j['created_at']?.toString(),
      imageChars: (j['image_chars'] as num?)?.toInt() ?? image?.length ?? 0,
      image: image,
    );
  }
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
