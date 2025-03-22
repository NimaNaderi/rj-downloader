import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_cache/just_audio_cache.dart';
import 'package:provider/provider.dart';
import 'package:rj_downloader/config/global/constants/app_constants.dart';
import 'package:rj_downloader/config/services/local/audio_player_config.dart';
import 'package:rj_downloader/data/models/media.dart';
import 'package:rj_downloader/ui/screens/saved_media_screen.dart';
import 'package:rj_downloader/ui/widgets/music_item.dart';
import 'package:skeletons/skeletons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/services/remote/api_service.dart';
import '../../data/providers/music_list_provider.dart';
import 'music_screen.dart';

class RotatingCircle extends StatefulWidget {
  final Widget child;
  final AudioPlayer audioPlayer;

  const RotatingCircle(
      {super.key, required this.child, required this.audioPlayer});

  @override
  _RotatingCircleState createState() => _RotatingCircleState();
}

class _RotatingCircleState extends State<RotatingCircle>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.audioPlayer.audioSource == null || !widget.audioPlayer.playing) {
      _animationController!.stop();
    } else {
      _animationController!.repeat();
    }
    return RotationTransition(
      turns: _animationController!,
      child: ClipOval(
        child: widget.child,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  TextEditingController textEditingController = TextEditingController();
  FocusNode searchFocusNode = FocusNode();
  AudioPlayer audioPlayer = AudioPlayer();
  Media? latestMedia;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    audioPlayer.setLoopMode(
        AudioPlayerConfig.getIsLoop() ?? false ? LoopMode.one : LoopMode.off);

    searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.detached:
        Get.to(
          () => MusicScreen(
            onMusicChanged: () {},
            isAudioDownloaded: true,
            isVideoDownloaded: true,
            audioPlayer: audioPlayer,
            media: latestMedia!,
            onDownloadComplete: () {},
          ),
          transition: Transition.fade,
          fullscreenDialog: true,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeIn,
        );
        break;
    }
  }

  @override
  void dispose() {
    searchFocusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  List popUpChoices = [
    CustomPopupMenu(title: 'Clear Cache', icon: Iconsax.trash),
    CustomPopupMenu(title: 'Developer Github', icon: Iconsax.user),
  ];

  @override
  Widget build(BuildContext context) {
    final MusicListProvider musicListProvider =
        Provider.of<MusicListProvider>(context, listen: true);
    latestMedia = AudioPlayerConfig.getLatestMedia();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        actions: [
          if (latestMedia != null) ...{
            InkResponse(
              onTap: () {
                Get.to(
                  () => MusicScreen(
                    onMusicChanged: () {},
                    isAudioDownloaded: true,
                    isVideoDownloaded: true,
                    audioPlayer: audioPlayer,
                    media: latestMedia!,
                    onDownloadComplete: () {},
                  ),
                  transition: Transition.fade,
                  fullscreenDialog: true,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeIn,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: RotatingCircle(
                  audioPlayer: audioPlayer,
                  child: CachedNetworkImage(
                    imageUrl: latestMedia!.photo,
                  ),
                ),
              ),
            )
          },
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SavedMediaScreen(audioPlayer: audioPlayer),
                ),
              );
            },
            icon: const Icon(Iconsax.save_2),
          ),
          PopupMenuButton(
            onSelected: (value) async {
              var selectedItem = value as CustomPopupMenu;
              if (selectedItem.title == 'Developer Github') {
                await launchUrl(Uri.parse(AppConstants.myGithubLink),
                    mode: LaunchMode.externalApplication);
              } else {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(
                      'Clear All Cache',
                      style: TextStyle(color: AppConstants.primaryColor),
                    ),
                    content: const Text(
                        'Do You Really Want To Clear All Media Cache ?'),
                    actions: [
                      TextButton(
                        onPressed: () async {
                          AudioPlayer().clearCache();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Yes',
                          style: TextStyle(
                              fontFamily: 'pm',
                              color: AppConstants.primaryColor),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('No',
                            style: TextStyle(
                                fontFamily: 'pm', color: Colors.black)),
                      )
                    ],
                  ),
                );
              }
            },
            icon: const Icon(Iconsax.menu),
            itemBuilder: (context) => popUpChoices
                .map(
                  (choice) => PopupMenuItem(
                    value: choice,
                    child: Row(
                      children: [
                        Text(
                          choice.title,
                          maxLines: 1,
                          style: const TextStyle(
                              fontSize: 14, overflow: TextOverflow.ellipsis),
                        ),
                        const Spacer(),
                        Icon(
                          choice.icon,
                          color: AppConstants.primaryColor,
                          size: 20,
                        )
                      ],
                    ),
                  ),
                )
                .toList(),
          )
        ],
        title: const Text(
          'RJ Downloader',
          style: TextStyle(fontSize: 18, fontFamily: 'pm'),
        ),
      ),
      backgroundColor: const Color(0xffEEEEEE),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              width: double.infinity,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 10,
                      child: AnimatedContainer(
                        height: 54,
                        duration: const Duration(milliseconds: 500),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: searchFocusNode.hasFocus
                                ? AppConstants.primaryColor
                                : Colors.white,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        child: TextField(
                          onSubmitted: (value) =>
                              makeRequestUiChanges(musicListProvider),
                          focusNode: searchFocusNode,
                          controller: textEditingController,
                          decoration: const InputDecoration(
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintStyle: TextStyle(fontSize: 14),
                              hintText: 'Enter music or artist name'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  GestureDetector(
                    onTap: () => makeRequestUiChanges(musicListProvider),
                    child: Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: musicListProvider.isLoading
                          ? const Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : const Icon(
                              Iconsax.search_normal,
                              color: Colors.white,
                              size: 26,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (musicListProvider.getMusicList.isNotEmpty) ...[
              Expanded(
                child: FlipInX(
                  duration: const Duration(milliseconds: 1500),
                  child: ListView.builder(
                      itemCount: musicListProvider.getMusicList.length,
                      itemBuilder: (context, index) {
                        return MusicItem(
                          key: UniqueKey(),
                          onMusicChanged: () {
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              () {
                                musicListProvider.rebuildWidgets();
                              },
                            );
                          },
                          audioPlayer: audioPlayer,
                          media: musicListProvider.getMusicList[index],
                          showSavedStatus: true,
                        );
                      }),
                ),
              )
            ],
            Visibility(
              visible: musicListProvider.isLoading,
              child: Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SkeletonListView(
                        scrollable: false,
                        itemCount: 9,
                        itemBuilder: (p0, p1) {
                          return const SkeletonAvatar(
                            style: SkeletonAvatarStyle(
                              // height: 100,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          );
                        },
                        // item: const SkeletonAvatar(),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  makeRequestUiChanges(MusicListProvider musicListProvider) async {
    if (textEditingController.text.isEmpty) {
      return;
    }

    searchFocusNode.unfocus();
    musicListProvider.musicList = [];
    musicListProvider.isLoading = true;

    musicListProvider.musicList =
        await ApiService.getMusicFromServer(textEditingController.text);

    musicListProvider.isLoading = false;
  }
}

class CustomPopupMenu {
  CustomPopupMenu({required this.title, required this.icon});

  String title;
  IconData icon;
}
