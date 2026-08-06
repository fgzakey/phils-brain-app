import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'models.dart';

/// Prefilled server address — the shared Phils Library Space (same backend and
/// database as the Book and YT apps). Only the app password is needed on first
/// run; override the URL in Settings to point elsewhere.
const String kDefaultServerUrl = 'https://fgza-book-dashboard.hf.space';

class AppState extends ChangeNotifier {
  final ApiClient api = ApiClient();

  bool loadedPrefs = false;
  String model = 'google/gemini-2.5-flash';
  String scribeImageModel = 'google/gemini-2.5-flash-image';
  double temperature = 0.4;

  /// Global text scale — applies to all text incl. Markdown (pinch or A−/A+).
  double mdScale = 1.0;

  List<Essay> essays = [];
  GraphStats? stats;
  List<GraphNode> nodes = [];
  List<PraxisNode> praxisNodes = [];
  List<PraxisEdge> praxisEdges = [];
  List<ModelInfo> models = [];
  InsightsResponse? insights;
  List<MnemonicSource> mnemonicSources = [];

  bool loadingEssays = false;
  String? essaysError;
  bool loadingGraph = false;
  String? graphError;
  bool loadingPraxis = false;
  String? praxisError;
  bool loadingInsights = false;
  String? insightsError;
  bool loadingMnemonicSources = false;
  String? mnemonicSourcesError;

  Future<void> loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    final savedUrl = p.getString('baseUrl');
    api.baseUrl = (savedUrl == null || savedUrl.isEmpty) ? kDefaultServerUrl : savedUrl;
    api.password = p.getString('password') ?? '';
    api.apiKey = p.getString('apiKey') ?? '';
    model = p.getString('model') ?? model;
    scribeImageModel = p.getString('scribeImageModel') ?? scribeImageModel;
    temperature = p.getDouble('temperature') ?? 0.4;
    mdScale = p.getDouble('mdScale') ?? 1.0;
    loadedPrefs = true;
    notifyListeners();
  }

  Future<void> saveSettings({
    required String baseUrl,
    required String password,
    String? newApiKey,
    String? newModel,
    double? newTemperature,
  }) async {
    var url = baseUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    api.baseUrl = url;
    api.password = password.trim();
    if (newApiKey != null) api.apiKey = newApiKey.trim();
    if (newModel != null) model = newModel;
    if (newTemperature != null) temperature = newTemperature;

    final p = await SharedPreferences.getInstance();
    await p.setString('baseUrl', api.baseUrl);
    await p.setString('password', api.password);
    await p.setString('apiKey', api.apiKey);
    await p.setString('model', model);
    await p.setDouble('temperature', temperature);
    notifyListeners();
  }

  Future<void> setModel(String id) async {
    model = id;
    final p = await SharedPreferences.getInstance();
    await p.setString('model', id);
    notifyListeners();
  }

  Future<void> bumpMdScale(double delta) async {
    mdScale = double.parse((mdScale + delta).clamp(0.6, 3.0).toStringAsFixed(2));
    notifyListeners();
    await saveMdScale();
  }

  /// Live update during a pinch gesture (used by ZoomMd).
  void previewMdScale(double v) {
    mdScale = v;
    notifyListeners();
  }

  Future<void> saveMdScale() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('mdScale', mdScale);
  }

  // ---- Essays ----

  Future<void> refreshEssays() async {
    loadingEssays = true;
    essaysError = null;
    notifyListeners();
    try {
      essays = await api.listEssays();
    } catch (e) {
      essaysError = e.toString();
    }
    loadingEssays = false;
    notifyListeners();
  }

  // ---- Graph ----

  Future<void> refreshGraph({String? type, String query = ''}) async {
    loadingGraph = true;
    graphError = null;
    notifyListeners();
    try {
      // Stats only on the first/unfiltered load; node list always.
      stats ??= await api.graphStats();
      nodes = await api.listGraphNodes(type: type, query: query);
    } catch (e) {
      graphError = e.toString();
    }
    loadingGraph = false;
    notifyListeners();
  }

  Future<void> reloadStats() async {
    try {
      stats = await api.graphStats();
      notifyListeners();
    } catch (_) {}
  }

  // ---- Praxis ----

  Future<void> refreshPraxis() async {
    loadingPraxis = true;
    praxisError = null;
    notifyListeners();
    try {
      final p = await api.getPraxis();
      praxisNodes = p.nodes;
      praxisEdges = p.edges;
    } catch (e) {
      praxisError = e.toString();
    }
    loadingPraxis = false;
    notifyListeners();
  }

  // ---- Praxis Insights ----

  Future<void> refreshInsights() async {
    loadingInsights = true;
    insightsError = null;
    notifyListeners();
    try {
      insights = await api.getInsights();
    } catch (e) {
      insightsError = e.toString();
    }
    loadingInsights = false;
    notifyListeners();
  }

  // ---- Mnemonic scenes ----

  Future<void> refreshMnemonicSources() async {
    loadingMnemonicSources = true;
    mnemonicSourcesError = null;
    notifyListeners();
    try {
      mnemonicSources = await api.listMnemonicSources();
    } catch (e) {
      mnemonicSourcesError = e.toString();
    }
    loadingMnemonicSources = false;
    notifyListeners();
  }

  // ---- Models ----

  Future<void> refreshModels() async {
    try {
      models = await api.listModels();
      notifyListeners();
    } catch (_) {}
  }
}
