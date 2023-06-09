import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../extension.dart';
import '../../../providers/navigator_provider.dart';
import '../../../providers/personalized_playlist_provider.dart';
import '../../../repository.dart';
import '../../common/image.dart';
import '../../common/navigation_target.dart';
import '../../common/playlist/track_list_container.dart';
import '../widgets/track_tile.dart';

class MainPageDiscover extends StatefulWidget {
  const MainPageDiscover({super.key});

  @override
  State<StatefulWidget> createState() => CloudPageState();
}

class CloudPageState extends State<MainPageDiscover>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      children: <Widget>[
        _NavigationLine(),
        _Header('推荐歌单', () {}),
        _SectionPlaylist(),
        _Header('最新音乐', () {}),
        _SectionNewSongs(),
      ],
    );
  }
}

class _NavigationLine extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _ItemNavigator(
            Icons.radio,
            context.strings.personalFM,
            () => ref
                .read(navigatorProvider.notifier)
                .navigate(NavigationTargetFmPlaying()),
          ),
          _ItemNavigator(
            Icons.today,
            context.strings.dailyRecommend,
            () => ref
                .read(navigatorProvider.notifier)
                .navigate(NavigationTargetDailyRecommend()),
          ),
          _ItemNavigator(
            Icons.show_chart,
            context.strings.leaderboard,
            () => ref
                .read(navigatorProvider.notifier)
                .navigate(NavigationTargetLeaderboard()),
          ),
        ],
      ),
    );
  }
}

///common header for section
class _Header extends StatelessWidget {
  const _Header(this.text, this.onTap);

  final String text;
  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(padding: EdgeInsets.only(left: 8)),
          Text(
            text,
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(fontWeight: FontWeight.w800),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _ItemNavigator extends StatelessWidget {
  const _ItemNavigator(this.icon, this.text, this.onTap);

  final IconData icon;

  final String text;

  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          children: <Widget>[
            Material(
              shape: const CircleBorder(),
              elevation: 5,
              child: ClipOval(
                child: Container(
                  width: 40,
                  height: 40,
                  color: Theme.of(context).primaryColor,
                  child: Icon(
                    icon,
                    color: Theme.of(context).primaryIconTheme.color,
                  ),
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.only(top: 8)),
            Text(text),
          ],
        ),
      ),
    );
  }
}

class _SectionPlaylist extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(homePlaylistProvider.logErrorOnDebug());
    return snapshot.when(
      data: (list) {
        return LayoutBuilder(
          builder: (context, constraints) {
            assert(
              constraints.maxWidth.isFinite,
              'can not layout playlist item in infinite width container.',
            );
            final parentWidth = constraints.maxWidth - 8;
            const count = /* false ? 6 : */ 3;
            final width = (parentWidth / count).clamp(80.0, 200.0);
            final spacing = (parentWidth - width * count) / (count + 1);
            return Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 4 + spacing.roundToDouble()),
              child: Wrap(
                spacing: spacing,
                children: list.map<Widget>((p) {
                  return _PlayListItemView(playlist: p, width: width);
                }).toList(),
              ),
            );
          },
        );
      },
      error: (error, stacktrace) {
        return SizedBox(
          height: 200,
          child: Center(
            child: Text(context.formattedError(error)),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

class _PlayListItemView extends ConsumerWidget {
  const _PlayListItemView({
    super.key,
    required this.playlist,
    required this.width,
  });

  final RecommendedPlaylist playlist;

  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    GestureLongPressCallback? onLongPress;

    if (playlist.copywriter.isNotEmpty) {
      onLongPress = () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(
                playlist.copywriter,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          },
        );
      };
    }

    return InkWell(
      onTap: () => ref
          .read(navigatorProvider.notifier)
          .navigate(NavigationTargetPlaylist(playlist.id)),
      onLongPress: onLongPress,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: width,
              width: width,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(6)),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AppImage(url: playlist.picUrl),
                ),
              ),
            ),
            const Padding(padding: EdgeInsets.only(top: 4)),
            Text(
              playlist.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionNewSongs extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(personalizedNewSongProvider.logErrorOnDebug());
    return snapshot.when(
      data: (songs) {
        return TrackTileContainer.trackList(
          tracks: songs,
          id: 'playlist_main_newsong',
          child: Column(
            children: songs
                .mapIndexed(
                  (index, item) => TrackTile(
                    track: item,
                    index: index + 1,
                  ),
                )
                .toList(),
          ),
        );
      },
      error: (error, stacktrace) {
        return SizedBox(
          height: 200,
          child: Center(
            child: Text(context.formattedError(error)),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
