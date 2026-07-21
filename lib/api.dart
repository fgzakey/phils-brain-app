import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

/// Client for the Phils Library backend (the Hugging Face Space) — the graph,
/// synthesis-essay, praxis, model and scribe routes. Auth is the same
/// `book_auth=<password>` cookie the other two apps use.
class ApiClient {
  String baseUrl;
  String password;
  String apiKey;

  ApiClient({this.baseUrl = '', this.password = '', this.apiKey = ''});

  bool get configured => baseUrl.isNotEmpty;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (password.isNotEmpty) 'Cookie': 'book_auth=$password',
      };

  Never _fail(http.Response res) {
    String msg = 'HTTP ${res.statusCode}';
    try {
      final j = jsonDecode(res.body);
      if (j is Map && j['error'] != null) msg = j['error'].toString();
    } catch (_) {}
    throw ApiException(msg, res.statusCode);
  }

  Map<String, dynamic> _json(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) _fail(res);
    try {
      return Map<String, dynamic>.from(jsonDecode(res.body));
    } catch (_) {
      throw ApiException(
          'Server returned a non-JSON response (likely a gateway timeout on the Space). Try again.',
          res.statusCode);
    }
  }

  Future<void> login() async {
    final res = await http.post(
      _uri('/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password}),
    );
    if (res.statusCode != 200) _fail(res);
  }

  // ---- Essays ----

  Future<List<Essay>> listEssays() async {
    final res = await http.get(_uri('/api/essays'), headers: _headers);
    final j = _json(res);
    return ((j['essays'] as List?) ?? [])
        .map((e) => Essay.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ---- Knowledge graph ----

  Future<GraphStats> graphStats() async {
    final res = await http.get(_uri('/api/graph', {'stats': '1'}), headers: _headers);
    final j = _json(res);
    return GraphStats.fromJson(Map<String, dynamic>.from(j['stats'] ?? j));
  }

  Future<List<GraphNode>> listGraphNodes({String? type, String query = ''}) async {
    final res = await http.get(
        _uri('/api/graph', {
          if (type != null && type.isNotEmpty) 'type': type,
          if (query.isNotEmpty) 'q': query,
        }),
        headers: _headers);
    final j = _json(res);
    return ((j['nodes'] as List?) ?? [])
        .map((n) => GraphNode.fromJson(Map<String, dynamic>.from(n)))
        .toList();
  }

  Future<NodeDetail> getNode(dynamic nodeId) async {
    final res = await http
        .get(_uri('/api/graph', {'nodeId': '$nodeId'}), headers: _headers);
    final j = _json(res);
    return NodeDetail.fromJson(j);
  }

  // ---- Praxis ----

  Future<({List<PraxisNode> nodes, List<PraxisEdge> edges})> getPraxis() async {
    final res = await http.get(_uri('/api/graph/praxis'), headers: _headers);
    final j = _json(res);
    return (
      nodes: ((j['nodes'] as List?) ?? [])
          .map((n) => PraxisNode.fromJson(Map<String, dynamic>.from(n)))
          .toList(),
      edges: ((j['edges'] as List?) ?? [])
          .map((e) => PraxisEdge.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  /// Add a goal/project/task hung off an existing node (servesSlug).
  Future<void> addPraxis({
    required String type, // goal | project | task
    required String title,
    required String servesSlug,
    String? enactsSlug,
    String? body,
  }) async {
    final res = await http.post(_uri('/api/graph/praxis'),
        headers: _headers,
        body: jsonEncode({
          'type': type,
          'title': title,
          'servesSlug': servesSlug,
          if (enactsSlug != null) 'enactsSlug': enactsSlug,
          if (body != null) 'body': body,
        }));
    _json(res);
  }

  // ---- Models & chat (for Visual Scribe) ----

  Future<List<ModelInfo>> listModels() async {
    final res = await http.get(_uri('/api/models'), headers: _headers);
    final j = _json(res);
    return ((j['models'] as List?) ?? [])
        .map((m) => ModelInfo.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  // ---- Visual Scribe ----

  Future<Map<String, dynamic>> scribeSpec({
    required String booktext,
    required String title,
    String author = '',
    required String textModel,
    required String mode,
    required String artStyle,
    double temperature = 0.4,
  }) async {
    final res = await http
        .post(_uri('/api/scribe'),
            headers: _headers,
            body: jsonEncode({
              'booktext': booktext,
              'title': title,
              'author': author,
              'textModel': textModel,
              'generateImages': false,
              'mode': mode,
              'artStyle': artStyle,
              'temperature': temperature,
              if (apiKey.isNotEmpty) 'apiKey': apiKey,
            }))
        .timeout(const Duration(minutes: 6));
    return _json(res);
  }

  Future<String> scribeImage({
    required String imagePrompt,
    String imageContext = '',
    required String artStyle,
    String? imageModel,
  }) async {
    final res = await http
        .post(_uri('/api/scribe'),
            headers: _headers,
            body: jsonEncode({
              'imagePrompt': imagePrompt,
              'imageContext': imageContext,
              'artStyle': artStyle,
              if (imageModel != null && imageModel.isNotEmpty) 'imageModel': imageModel,
              if (apiKey.isNotEmpty) 'apiKey': apiKey,
            }))
        .timeout(const Duration(minutes: 4));
    final j = _json(res);
    final url = j['url'] as String?;
    if (url == null || url.isEmpty) throw ApiException('No image returned.', 502);
    return url;
  }
}

class ApiException implements Exception {
  final String message;
  final int status;
  ApiException(this.message, this.status);
  @override
  String toString() => message;
}
