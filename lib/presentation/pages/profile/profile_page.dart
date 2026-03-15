import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_weibo/core/di/injection.dart';
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

  @override
  void initState() {
    super.initState();
    _profileCubit = sl<ProfileCubit>();
    _profileCubit.loadProfile(widget.userId);
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
              _isFollowing ??= state.user.following;
              return CustomScrollView(
                slivers: [
                  SliverAppBar.large(
                    title: Text(state.user.screenName),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _isFollowing == true
                            ? OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('已关注')),
                                  );
                                },
                                icon: const Icon(Icons.check, size: 18),
                                label: const Text('已关注'),
                              )
                            : FilledButton.icon(
                                onPressed: () {
                                  setState(() => _isFollowing = true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('关注成功（本地预览）'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.person_add_alt_1),
                                label: const Text('关注'),
                              ),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        elevation: 0,
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor:
                                        colorScheme.primaryContainer,
                                    backgroundImage:
                                        state.user.profileImageUrl.isNotEmpty
                                        ? NetworkImage(state.user.profileImageUrl)
                                        : null,
                                    child: state.user.profileImageUrl.isEmpty
                                        ? Icon(
                                            Icons.person,
                                            color:
                                                colorScheme.onPrimaryContainer,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Wrap(
                                      spacing: 20,
                                      runSpacing: 8,
                                      children: [
                                        _StatColumn(
                                          label: '微博',
                                          count: state.user.statusesCount,
                                        ),
                                        _StatColumn(
                                          label: '关注',
                                          count: state.user.friendsCount,
                                        ),
                                        _StatColumn(
                                          label: '粉丝',
                                          count: state.user.followersCount,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (state.user.description != null &&
                                  state.user.description!.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  state.user.description!,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                              if (state.user.location != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on_outlined,
                                      size: 16,
                                      color: colorScheme.outline,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      state.user.location!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: colorScheme.outline,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
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
