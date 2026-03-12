import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:material_weibo/core/di/injection.dart';
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
      final token = await sl<AuthRepository>().getSavedToken();
      if (token == null) {
        emit(const ProfileError(message: '请先登录'));
        return;
      }
      final user = await userRepository.getUserInfo(
        token: token,
        userId: userId,
      );
      // 加载用户微博
      final posts = await sl<TimelineRepository>().getUserTimeline(
        token: token,
        userId: userId,
      );
      emit(ProfileLoaded(user: user, posts: posts));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }
}
