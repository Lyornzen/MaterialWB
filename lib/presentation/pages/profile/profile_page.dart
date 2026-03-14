import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_weibo/core/di/injection.dart';
import 'package:material_weibo/core/l10n/app_localizations.dart';
import 'package:material_weibo/data/datasources/remote/weibo_web_api.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_bloc.dart';
import 'package:material_weibo/presentation/blocs/auth/auth_state.dart';
import 'package:material_weibo/presentation/blocs/profile/profile_cubit.dart';
import 'package:material_weibo/presentation/widgets/weibo_card.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileCubit _profileCubit;
  bool? _isFollowing;
  bool _followLoading = false;

  @override
  void initState() {
    super.initState();
    _profileCubit = sl<ProfileCubit>();
    _profileCubit.loadProfile(widget.userId);
  }

  /// 当前查看的是否是自己的主页
  bool _isSelf(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated && authState.user != null) {
      return authState.user!.id == widget.userId;
    }
    return false;
  }

  /// 当前用户是否已登录（非游客）
  bool _isLoggedIn(BuildContext context) {
    return context.read<AuthBloc>().state.isLoggedIn;
  }

  Future<void> _toggleFollow(BuildContext context) async {
    if (_followLoading) return;
    if (!_isLoggedIn(context)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(S.get('login_to_follow'))));
      return;
    }

    setState(() => _followLoading = true);
    try {
      final webApi = sl<WeiboWebApi>();
      if (_isFollowing == true) {
        await webApi.unfollowUser(widget.userId);
        setState(() => _isFollowing = false);
      } else {
        await webApi.followUser(widget.userId);
        setState(() => _isFollowing = true);
      }
    } catch (e) {
      debugPrint('Follow/unfollow error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${S.get('follow_failed')}：$e')));
      }
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider.value(
      value: _profileCubit,
      child: Scaffold(
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProfileError) {
              return Center(child: Text(state.message));
            }
            if (state is ProfileLoaded) {
              // 初始化关注状态
              _isFollowing ??= state.user.following;

              return CustomScrollView(
                slivers: [
                  SliverAppBar.large(title: Text(state.user.screenName)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: colorScheme.primaryContainer,
                                backgroundImage:
                                    state.user.profileImageUrl.isNotEmpty
                                    ? NetworkImage(state.user.profileImageUrl)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _StatColumn(
                                      label: S.get('posts_count'),
                                      count: state.user.statusesCount,
                                    ),
                                    _StatColumn(
                                      label: S.get('following_count'),
                                      count: state.user.friendsCount,
                                    ),
                                    _StatColumn(
                                      label: S.get('followers_count'),
                                      count: state.user.followersCount,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // 关注按钮（不在自己的主页显示）
                          if (!_isSelf(context))
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: SizedBox(
                                width: double.infinity,
                                child: _isFollowing == true
                                    ? OutlinedButton(
                                        onPressed: _followLoading
                                            ? null
                                            : () => _toggleFollow(context),
                                        child: _followLoading
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Text(S.get('following')),
                                      )
                                    : FilledButton.icon(
                                        onPressed: _followLoading
                                            ? null
                                            : () => _toggleFollow(context),
                                        icon: _followLoading
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.person_add_outlined,
                                                size: 18,
                                              ),
                                        label: Text(S.get('follow')),
                                      ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          if (state.user.description != null &&
                              state.user.description!.isNotEmpty)
                            Text(
                              state.user.description!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          if (state.user.location != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: colorScheme.outline,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    state.user.location!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: colorScheme.outline),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: Divider()),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => WeiboCard(post: state.posts[index]),
                      childCount: state.posts.length,
                    ),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int count;

  const _StatColumn({required this.label, required this.count});

  String _formatCount(int count) {
    if (count >= 10000) {
      return '${(count / 10000).toStringAsFixed(1)}万';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          _formatCount(count),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
