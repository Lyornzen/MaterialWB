import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_weibo/core/i18n/app_i18n.dart';
import 'package:material_weibo/presentation/blocs/favorite/favorite_cubit.dart';
import 'package:material_weibo/presentation/widgets/empty_state.dart';
import 'package:material_weibo/presentation/widgets/weibo_card.dart';
import 'package:material_weibo/presentation/widgets/loading_indicator.dart';
import 'package:material_weibo/presentation/widgets/error_widget.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    context.read<FavoriteCubit>().loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = context.i18n;
    return Scaffold(
      appBar: AppBar(title: Text(i18n.tr('我的收藏', 'My Favorites'))),
      body: BlocBuilder<FavoriteCubit, FavoriteState>(
        builder: (context, state) {
          if (state is FavoriteLoading) return const LoadingIndicator();
          if (state is FavoriteUnavailable) {
            return AppEmptyState(
              icon: Icons.lock_outline,
              title: state.message,
              subtitle: i18n.tr(
                '登录后即可同步微博收藏内容',
                'Sign in to sync your favorite posts',
              ),
            );
          }
          if (state is FavoriteError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<FavoriteCubit>().loadFavorites(),
            );
          }
          if (state is FavoriteLoaded) {
            if (state.favorites.isEmpty) {
              return AppEmptyState(
                icon: Icons.star_outline,
                title: i18n.tr('暂无收藏', 'No favorites yet'),
                subtitle: i18n.tr(
                  '你收藏的微博会显示在这里',
                  'Posts you favorite will appear here',
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<FavoriteCubit>().loadFavorites(),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.favorites.length,
                separatorBuilder: (_, _) => const SizedBox(height: 2),
                itemBuilder: (context, index) =>
                    WeiboCard(post: state.favorites[index].post),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
