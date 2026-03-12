import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_weibo/presentation/blocs/favorite/favorite_cubit.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('我的收藏')),
      body: BlocBuilder<FavoriteCubit, FavoriteState>(
        builder: (context, state) {
          if (state is FavoriteLoading) return const LoadingIndicator();
          if (state is FavoriteError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<FavoriteCubit>().loadFavorites(),
            );
          }
          if (state is FavoriteLoaded) {
            if (state.favorites.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text('暂无收藏', style: Theme.of(context).textTheme.bodyLarge),
                  ],
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
