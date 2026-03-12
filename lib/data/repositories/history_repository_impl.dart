import 'package:material_weibo/data/datasources/local/weibo_local_db.dart';
import 'package:material_weibo/data/models/weibo_post_model.dart';
import 'package:material_weibo/domain/entities/weibo_post.dart';
import 'package:material_weibo/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final WeiboLocalDb localDb;

  HistoryRepositoryImpl({required this.localDb});

  @override
  Future<void> addHistory(WeiboPost post) async {
    final model = post as WeiboPostModel;
    await localDb.addHistory(model.toJson());
  }

  @override
  Future<List<WeiboPost>> getHistory({int page = 1, int count = 20}) async {
    final all = await localDb.getHistory();
    final start = (page - 1) * count;
    if (start >= all.length) return [];
    final end = (start + count).clamp(0, all.length);
    return all
        .sublist(start, end)
        .map((json) => WeiboPostModel.fromJson(json))
        .toList();
  }

  @override
  Future<void> clearHistory() => localDb.clearHistory();

  @override
  Future<void> removeHistory(String postId) => localDb.removeHistory(postId);

  @override
  Future<int> getHistoryCount() => localDb.getHistoryCount();
}
