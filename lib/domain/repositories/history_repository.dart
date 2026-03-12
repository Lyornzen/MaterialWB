import 'package:material_weibo/domain/entities/weibo_post.dart';

/// 浏览历史仓库接口
abstract class HistoryRepository {
  /// 添加浏览记录
  Future<void> addHistory(WeiboPost post);

  /// 获取浏览历史列表
  Future<List<WeiboPost>> getHistory({int page = 1, int count = 20});

  /// 清除所有历史记录
  Future<void> clearHistory();

  /// 删除单条历史记录
  Future<void> removeHistory(String postId);

  /// 获取历史记录总数
  Future<int> getHistoryCount();
}
