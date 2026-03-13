import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:material_weibo/core/di/injection.dart';
import 'package:material_weibo/data/datasources/remote/weibo_web_api.dart';
import 'package:material_weibo/data/models/weibo_post_model.dart';
import 'package:material_weibo/domain/entities/user.dart';
import 'package:material_weibo/domain/entities/weibo_post.dart';
import 'package:material_weibo/domain/repositories/auth_repository.dart';
import 'package:material_weibo/domain/repositories/user_repository.dart';
import 'package:material_weibo/domain/repositories/timeline_repository.dart';

// State
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final WeiboUser user;
  final List<WeiboPost> posts;
  const ProfileLoaded({required this.user, this.posts = const []});
  @override
  List<Object?> get props => [user, posts];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError({required this.message});
  @override
  List<Object?> get props => [message];
}

// Cubit
class ProfileCubit extends Cubit<ProfileState> {
  final UserRepository userRepository;

  ProfileCubit({required this.userRepository}) : super(const ProfileInitial());

  Future<void> loadProfile(String userId) async {
    emit(const ProfileLoading());
    try {
      final authRepo = sl<AuthRepository>();
      final token = await authRepo.getSavedToken();
      if (token == null) {
        emit(const ProfileError(message: '请先登录'));
        return;
      }

      // 获取用户信息（UserRepositoryImpl 内部已根据登录方式路由）
      final user = await userRepository.getUserInfo(
        token: token,
        userId: userId,
      );

      // 获取用户微博列表
      List<WeiboPost> posts = [];
      final method = authRepo.getLoginMethod();
      if (method == 'oauth') {
        posts = await sl<TimelineRepository>().getUserTimeline(
          token: token,
          userId: userId,
        );
      } else {
        // Cookie 登录 — 优先使用 PC web API，回退到 m.weibo.cn
        try {
          final webApi = sl<WeiboWebApi>();
          final data = await webApi.getUserTimelinePcWeb(userId);
          // PC web 格式: { "ok": 1, "data": { "list": [...] } }
          final list = (data['data']?['list'] as List?) ?? [];
          posts = list
              .where(
                (item) =>
                    item is Map<String, dynamic> &&
                    !WeiboPostModel.isAdPost(item),
              )
              .map(
                (item) => WeiboPostModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();
        } catch (e) {
          debugPrint(
            'PC web user timeline failed, falling back to m.weibo.cn: $e',
          );
          // 回退到 m.weibo.cn 的用户时间线
          posts = await sl<TimelineRepository>().getUserTimeline(
            token: token,
            userId: userId,
          );
        }
      }

      emit(ProfileLoaded(user: user, posts: posts));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }
}
