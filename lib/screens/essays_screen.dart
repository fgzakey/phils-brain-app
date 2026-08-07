import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';
import '../main.dart';
import '../md_toc.dart';
import '../md_toc_view.dart';
import '../models.dart';

/// Syntopical synthesis essays and everything for consolidating them:
///
///   Essays    — the living Adlerian essays themselves, read-only.
///   Insights  — every QUESTION 4 insight in the library as flash cards.
///   Sections  — every movement of every practical/theoretical essay as cards.
///   Review    — those movements as a due queue, intervals doubling per pass.
///
/// Insights used to sit under Praxis. It moved here (2026-08-07) to match the
/// web dashboards: the insights are the raw material the essays open with, so
/// they belong beside them rather than on the goals board.
class EssaysScreen extends StatefulWidget {
  const EssaysScreen({super.key});

  @override
  State<EssaysScreen> createState() => _EssaysScreenState();
}

class _EssaysScreenState extends State<EssaysScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() => setState(() {})); // the refresh button follows the tab
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _refreshCurrent(AppState state) {
    switch (_tabs.index) {
      case 1:
        state.refreshInsights();
        break;
      case 2:
      case 3:
        state.refreshSections();
        break;
      default:
        state.refreshEssays();
    }
  }

  bool _busy(AppState state) => switch (_tabs.index) {
        1 => state.loadingInsights,
        2 || 3 => state.loadingSections,
        _ => state.loadingEssays,
      };

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final due = state.sections?.dueCount ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Syntopical essays'),
        actions: [
          const TextSizeButtons(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _busy(state) ? null : () => _refreshCurrent(state),
          ),
          // Canon review — the reading and essay review dashboard on the server.
          // Opens in the device browser rather than a webview: commenting depends
          // on selecting a passage, and selection works far better outside one.
          IconButton(
            tooltip: 'Canon review — read, comment and approve',
            icon: const Icon(Icons.rate_review_outlined),
            onPressed: () async {
              final base = context.read<AppState>().api.baseUrl;
              if (base.isEmpty) {
                showSnack(context, 'Set the server URL in Settings first');
                return;
              }
              final uri = Uri.parse('$base/canon');
              if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                if (context.mounted) showSnack(context, 'Could not open $uri');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            const Tab(text: 'Essays'),
            const Tab(text: 'Insights'),
            const Tab(text: 'Sections'),
            Tab(text: due > 0 ? 'Review ($due)' : 'Review'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _EssayList(),
          InsightsTab(),
          SectionsTab(),
          SectionReviewTab(),
        ],
      ),
    );
  }
}

class _EssayList extends StatelessWidget {
  const _EssayList();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
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
        separatorBuilder: (_, _) => const Divider(height: 1),
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
          IconButton(
            tooltip: 'Export .md',
            icon: const Icon(Icons.ios_share),
            onPressed: () => _exportMd(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: essay.body.trim().isEmpty
          ? const Center(child: Text('This essay has no text yet.'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: MdWithToc(data: essay.body),
            ),
    );
  }

  Future<void> _exportMd(BuildContext context) async {
    // Read the render box BEFORE any await: it is the iPad share-sheet anchor,
    // and touching the BuildContext after an async gap throws if the widget
    // was disposed while the file was being written.
    final box = context.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    // Same packaging as the dashboard's essay download: canonical title,
    // provenance comment and a bidirectional Table of Contents.
    final md = packageMd(
      essay.body,
      title: essay.title,
      kind: 'Syntopical synthesis essay',
      processed: DateTime.tryParse(essay.updatedAt ?? ''),
    );
    final name = downloadName(
      title: essay.title,
      kind: 'Synthesis Essay',
      date: DateTime.tryParse(essay.updatedAt ?? ''),
      ext: 'md',
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(md);
    // share_plus 13 removed the static Share.shareXFiles() in favour of
    // SharePlus.instance.share(ShareParams(...)).
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'text/markdown')],
      subject: essay.title,
      sharePositionOrigin: origin,
    ));
  }
}

/// Flash-card review of every Q4 flourishing insight across the library
/// (/api/graph/insights). Filter by theme and source, swipe through the deck.
///
/// The insight is NEVER hidden — it is the front of the card, in full. Tapping
/// flips to the BACK: every other insight the same source contributed to the
/// same theme, which is what tells you whether the line is a one-off remark or
/// part of a sustained argument. (It used to hide the source behind a "tap to
/// reveal"; that was a quiz mechanic on a deck nobody quizzes with.)
class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key});

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  bool _loadedOnce = false;
  String? _theme; // slug, null = all
  String? _source; // source title, null = all
  final Set<int> _flipped = {};
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

  void _setFilter(
      {String? theme,
      bool themeSet = false,
      String? source,
      bool sourceSet = false}) {
    setState(() {
      if (themeSet) _theme = theme;
      if (sourceSet) _source = source;
      _flipped.clear();
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
      return _ErrorBox(
          message: 'Could not load insights:\n${state.insightsError}',
          onRetry: () => state.refreshInsights());
    }
    if (ins == null || ins.cards.isEmpty) {
      return const _EmptyBox(
        text:
            'No insights yet.\nRun the Adler prompts on a book or video and its Question 4 insights will land here.',
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
                  onPressed: () => _setFilter(
                      theme: null,
                      themeSet: true,
                      source: null,
                      sourceSet: true),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: ChoiceChip(
                    label: Text('${b.source} (${b.count})'),
                    selected: _source == b.source,
                    onSelected: (sel) => _setFilter(
                        source: sel ? b.source : null, sourceSet: true),
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
                  itemBuilder: (context, i) => _card(context, ins, cards, i),
                ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, InsightsResponse ins,
      List<InsightCard> cards, int i) {
    final c = cards[i];
    final flipped = _flipped.contains(i);
    final theme = Theme.of(context);
    final run = ins.sources[c.sourceKey];
    final siblings = flipped ? ins.siblingsOf(c) : const <String>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() {
            flipped ? _flipped.remove(i) : _flipped.add(i);
          }),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${i + 1} / ${cards.length}',
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                if (!flipped) ...[
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(c.text, style: theme.textTheme.titleMedium),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  ),
                ] else ...[
                  Text(c.themeTitle, style: theme.textTheme.titleSmall),
                  Text(
                    '${c.source} · insight ${c.pos} of ${run?.bulletCount ?? '?'}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text('Also from this source on this theme (${siblings.length})',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Expanded(
                    child: siblings.isEmpty
                        ? Text('Nothing else — this source touches the theme once.',
                            style: theme.textTheme.bodySmall)
                        : ListView.builder(
                            itemCount: siblings.length,
                            itemBuilder: (_, k) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('• ${siblings[k]}',
                                  style: theme.textTheme.bodyMedium),
                            ),
                          ),
                  ),
                  Text('Tap to flip back',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared filter state for Sections and Review: the two tabs are the same deck
/// seen two ways, so they read the same language/kind selection.
class _SectionFilters {
  static String lang = ''; // '' = every language
  static String kind = ''; // '' | practical | theoretical
  static bool initialized = false;
}

/// Every movement of every synthesis essay as cards. Front = the movement,
/// back (tap) = the rest of its essay.
class SectionsTab extends StatefulWidget {
  const SectionsTab({super.key});

  @override
  State<SectionsTab> createState() => _SectionsTabState();
}

class _SectionsTabState extends State<SectionsTab> {
  bool _loadedOnce = false;
  final Set<String> _flipped = {};
  final PageController _pager = PageController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      Future.microtask(() {
        if (!mounted) return;
        final s = context.read<AppState>();
        if (s.sections == null) s.refreshSections();
      });
    }
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _setFilter({String? lang, String? kind}) {
    setState(() {
      setSectionFilter(lang: lang, kind: kind);
      _flipped.clear();
    });
    if (_pager.hasClients) _pager.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final data = state.sections;

    if (state.loadingSections && data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.sectionsError != null && data == null) {
      return _ErrorBox(
          message: 'Could not load essay sections:\n${state.sectionsError}',
          onRetry: () => state.refreshSections());
    }
    if (data == null || data.cards.isEmpty) {
      return const _EmptyBox(
        text:
            'No essays yet.\nSynthesize a theme or a Great Idea in the web dashboard and its movements become review cards.',
      );
    }
    initSectionLang(data);

    final cards = filterSections(data);
    return Column(
      children: [
        SectionFilterBar(data: data, onChanged: _setFilter),
        Expanded(
          child: cards.isEmpty
              ? const Center(child: Text('No movements match these filters.'))
              : PageView.builder(
                  controller: _pager,
                  itemCount: cards.length,
                  itemBuilder: (context, i) => _card(context, data, cards, i),
                ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, SectionsResponse data,
      List<SectionCard> cards, int i) {
    final c = cards[i];
    final id = '${c.essaySlug}#${c.key}';
    final flipped = _flipped.contains(id);
    final theme = Theme.of(context);
    final essay = data.essayOf(c.essaySlug);
    final siblings = flipped ? data.siblingsOf(c) : const <String>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => setState(() {
            flipped ? _flipped.remove(id) : _flipped.add(id);
          }),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text('${i + 1} / ${cards.length}',
                        style: theme.textTheme.bodySmall),
                    const Spacer(),
                    Text(kindLabel(c.kind), style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(c.heading, style: theme.textTheme.titleMedium),
                Text(c.essayTitle, style: theme.textTheme.bodySmall),
                const Divider(height: 20),
                if (!flipped) ...[
                  Expanded(
                    child: SingleChildScrollView(
                      child: MarkdownBody(data: c.text, selectable: true),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.lastReviewed == null
                              ? 'never reviewed'
                              : 'last reviewed ${c.lastReviewed!.split('T').first}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.read<AppState>().reviewSection(c),
                        child: const Text('Got it'),
                      ),
                      TextButton(
                        onPressed: () => context
                            .read<AppState>()
                            .reviewSection(c, again: true),
                        child: const Text('Again'),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    '${kindLabel(c.kind)} · movement ${c.pos} of ${c.sectionCount} · ${c.words} words'
                    '${essay?.updatedAt != null ? ' · updated ${essay!.updatedAt!.split('T').first}' : ''}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Text('The rest of this essay (${siblings.length})',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Expanded(
                    child: siblings.isEmpty
                        ? Text('Nothing else — this essay has one movement.',
                            style: theme.textTheme.bodySmall)
                        : ListView.builder(
                            itemCount: siblings.length,
                            itemBuilder: (_, k) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text('${k + 1}. ${siblings[k]}',
                                  style: theme.textTheme.bodyMedium),
                            ),
                          ),
                  ),
                  Text('Tap to flip back',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The movements due for review, oldest interval first.
class SectionReviewTab extends StatefulWidget {
  const SectionReviewTab({super.key});

  @override
  State<SectionReviewTab> createState() => _SectionReviewTabState();
}

class _SectionReviewTabState extends State<SectionReviewTab> {
  bool _loadedOnce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedOnce) {
      _loadedOnce = true;
      Future.microtask(() {
        if (!mounted) return;
        final s = context.read<AppState>();
        if (s.sections == null) s.refreshSections();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final data = state.sections;

    if (state.loadingSections && data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.sectionsError != null && data == null) {
      return _ErrorBox(
          message: 'Could not load the review queue:\n${state.sectionsError}',
          onRetry: () => state.refreshSections());
    }
    if (data == null || data.cards.isEmpty) {
      return const _EmptyBox(
          text:
              'No essays yet.\nSynthesize a theme or a Great Idea in the web dashboard first.');
    }
    initSectionLang(data);

    final inScope = filterSections(data);
    final due = inScope.where((c) => c.due).toList();

    return Column(
      children: [
        SectionFilterBar(
          data: data,
          onChanged: ({String? lang, String? kind}) =>
              setState(() => setSectionFilter(lang: lang, kind: kind)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${due.length} of ${inScope.length} movements due — intervals double with each pass.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Reset review progress?'),
                      content: const Text(
                          'Forgets every review date for every essay movement. The essays themselves are untouched.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel')),
                        FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Reset')),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    context.read<AppState>().resetSectionReviews();
                  }
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
        Expanded(
          child: due.isEmpty
              ? const _EmptyBox(text: 'Nothing due — the essays are holding.')
              : RefreshIndicator(
                  onRefresh: () => state.refreshSections(),
                  child: ListView.builder(
                    itemCount: due.length,
                    itemBuilder: (context, i) {
                      final c = due[i];
                      return Card(
                        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.heading,
                                  style: Theme.of(context).textTheme.titleSmall),
                              Text(
                                '${kindLabel(c.kind)} · ${c.essayTitle}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 8),
                              MarkdownBody(data: c.text, selectable: true),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => context
                                        .read<AppState>()
                                        .reviewSection(c, again: true),
                                    child: const Text('Again'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: () => context
                                        .read<AppState>()
                                        .reviewSection(c),
                                    child: const Text('Got it'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ---- Shared section helpers ----

String kindLabel(String kind) => switch (kind) {
      'practical' => 'Practical',
      'theoretical' => 'Theoretical',
      _ => 'Other',
    };

/// Spanish essays are separate note nodes with their own slugs, so an
/// unfiltered deck deals the same movement twice, once per language. Default to
/// English whenever English essays exist — same rule as the web dashboard.
void initSectionLang(SectionsResponse data) {
  if (_SectionFilters.initialized) return;
  _SectionFilters.initialized = true;
  _SectionFilters.lang =
      data.essays.any((e) => e.lang == 'English') ? 'English' : '';
}

/// Mutate the shared filter. Both tabs go through this so Sections and Review
/// can never drift out of step with each other.
void setSectionFilter({String? lang, String? kind}) {
  if (lang != null) _SectionFilters.lang = lang;
  if (kind != null) _SectionFilters.kind = kind;
}

List<SectionCard> filterSections(SectionsResponse data) => data.cards
    .where((c) =>
        (_SectionFilters.lang.isEmpty || c.lang == _SectionFilters.lang) &&
        (_SectionFilters.kind.isEmpty || c.kind == _SectionFilters.kind))
    .toList();

/// Language and practical/theoretical toggles, shared by Sections and Review.
class SectionFilterBar extends StatelessWidget {
  final SectionsResponse data;
  final void Function({String? lang, String? kind}) onChanged;
  const SectionFilterBar({super.key, required this.data, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final langs = data.languages;
    final here = data.essays
        .where((e) =>
            _SectionFilters.lang.isEmpty || e.lang == _SectionFilters.lang)
        .toList();
    final practical = here.where((e) => e.kind == 'practical').length;
    final theoretical = here.where((e) => e.kind == 'theoretical').length;

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _chip(context, 'Both (${here.length})', _SectionFilters.kind.isEmpty,
              () => onChanged(kind: '')),
          _chip(context, 'Practical ($practical)',
              _SectionFilters.kind == 'practical', () => onChanged(kind: 'practical')),
          _chip(context, 'Theoretical ($theoretical)',
              _SectionFilters.kind == 'theoretical',
              () => onChanged(kind: 'theoretical')),
          // Only worth showing once a translation actually exists.
          if (langs.length > 1) ...[
            const VerticalDivider(width: 16),
            for (final l in langs)
              _chip(context, l, _SectionFilters.lang == l,
                  () => onChanged(lang: l)),
            _chip(context, 'Both languages', _SectionFilters.lang.isEmpty,
                () => onChanged(lang: '')),
          ],
        ],
      ),
    );
  }

  Widget _chip(
          BuildContext context, String label, bool selected, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );
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
