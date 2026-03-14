import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:material_weibo/core/di/injection.dart';
import 'package:material_weibo/data/datasources/remote/weibo_web_api.dart';
import 'package:material_weibo/data/models/user_model.dart';
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
      final method = authRepo.getLoginMethod();
      final token = await authRepo.getSavedToken();

      WeiboUser user;
      List<WeiboPost> posts = [];

      if (method == 'oauth' && token != null) {
        // OAuth 登录 — 使用官方 API
        user = await userRepository.getUserInfo(token: token, userId: userId);
        posts = await sl<TimelineRepository>().getUserTimeline(
          token: token,
          userId: userId,
        );
      } else {
        // Cookie 登录或游客模式 — 使用 PC web API（自带 visitor cookie）
        final webApi = sl<WeiboWebApi>();

        // 获取用户信息
        try {
          final profileData = await webApi.getUserProfile(userId);
          final userData =
              profileData['data']?['user'] as Map<String, dynamic>?;
          if (userData != null) {
            user = UserModel.fromJson(userData);
          } else {
            final directData = profileData['data'] as Map<String, dynamic>?;
            if (directData != null && directData.containsKey('screen_name')) {
              user = UserModel.fromJson(directData);
            } else {
              throw Exception('用户信息格式异常');
            }
          }
        } catch (e) {
          debugPrint('PC web getUserProfile failed: $e');
          throw Exception('无法获取用户信息: $e');
        }

        // 获取用户微博列表
        try {
          final data = await webApi.getUserTimelinePcWeb(userId);
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
          try {
            final webData = await webApi.getUserTimeline(userId);
            final cards = (webData['data']?['cards'] as List?) ?? [];
            posts = cards
                .where(
                  (card) =>
                      card is Map<String, dynamic> &&
                      card['card_type'] == 9 &&
                      card['mblog'] != null,
                )
                .map(
                  (card) => WeiboPostModel.fromJson(
                    card['mblog'] as Map<String, dynamic>,
                  ),
                )
                .toList();
          } catch (e2) {
            debugPrint('m.weibo.cn user timeline also failed: $e2');
            // 微博列表加载失败不应阻止用户信息展示，保持 posts 为空
          }
        }
      }

      emit(ProfileLoaded(user: user, posts: posts));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }
}
