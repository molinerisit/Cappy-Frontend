import 'package:flutter/foundation.dart';
import '../data/path_repository.dart';
import '../domain/models/path_model.dart';
import '../domain/models/path_node.dart';
import '../domain/models/path_group.dart';

class PathController extends ChangeNotifier {
  final PathRepository _repository;
  final int _pageSize;

  PathModel? _pathModel;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  DateTime? _lastLoadMoreAt;
  static const Duration _loadMoreCooldown = Duration(milliseconds: 450);

  PathController({required PathRepository repository, int pageSize = 40})
    : _repository = repository,
      _pageSize = pageSize;

  PathModel? get pathModel => _pathModel;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _pathModel?.hasMore ?? false;
  String? get errorMessage => _errorMessage;
  List<PathNode> get nodes => _pathModel?.nodes ?? [];
  List<PathGroup> get groups => _pathModel?.groups ?? [];
  int get completedCount => _pathModel?.completedCount ?? 0;
  int get totalCount => _pathModel?.totalCount ?? 0;
  int get currentLevel => _pathModel?.currentLevel ?? 1;

  Map<String, String> get groupTitles {
    final map = <String, String>{};
    for (final group in groups) {
      if (group.title.isNotEmpty) {
        map[group.id] = group.title;
      }
    }
    for (final node in nodes) {
      if (node.groupId != null &&
          node.groupTitle != null &&
          node.groupTitle!.isNotEmpty) {
        map.putIfAbsent(node.groupId!, () => node.groupTitle!);
      }
    }
    return map;
  }

  Future<void> loadInitial() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _fetchPage(page: 1, append: false);
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore || _isLoading) return;

    final now = DateTime.now();
    if (_lastLoadMoreAt != null &&
        now.difference(_lastLoadMoreAt!) < _loadMoreCooldown) {
      return;
    }
    _lastLoadMoreAt = now;

    _isLoadingMore = true;
    notifyListeners();

    final nextPage = (_pathModel?.currentPage ?? 0) + 1;
    await _fetchPage(page: nextPage, append: true);

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<void> _fetchPage({required int page, required bool append}) async {
    final stopwatch = Stopwatch()..start();
    int fetchedCount = 0;
    String status = 'ok';

    try {
      final fetchedModel = await _repository.fetchPath(
        page: page,
        limit: _pageSize,
      );

      fetchedCount = fetchedModel.nodes.length;

      if (append && _pathModel != null) {
        final existingIds = _pathModel!.nodes.map((n) => n.id).toSet();
        final newNodes = fetchedModel.nodes
            .where((n) => !existingIds.contains(n.id))
            .toList();

        _pathModel = _pathModel!.copyWith(
          nodes: [..._pathModel!.nodes, ...newNodes],
          hasMore: fetchedModel.hasMore,
          currentPage: page,
        );
      } else {
        _pathModel = fetchedModel;
      }

      _errorMessage = null;
    } catch (e) {
      status = 'error';
      if (!append) {
        _errorMessage = e.toString();
      }
    } finally {
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint(
          '[PathController] page=$page append=$append fetched=$fetchedCount hasMore=$hasMore status=$status ms=${stopwatch.elapsedMilliseconds}',
        );
      }

      _isLoading = false;
      notifyListeners();
    }
  }
}
