import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:rj_downloader/config/global/constants/app_constants.dart';
import 'package:rj_downloader/config/services/local/hive_service.dart';
import 'package:rj_downloader/data/models/media.dart';
import 'package:skeletons/skeletons.dart';

import '../../config/global/utils/utils.dart';
import '../../data/providers/music_list_provider.dart';
import '../../data/providers/saved_media_provider.dart';
import '../screens/music_screen.dart';

class MusicItem extends StatefulWidget {
  final Media media;
  final AudioPlayer audioPlayer;
  final bool showSavedStatus;
  final Function() onMusicChanged;

  const MusicItem({
    super.key,
    required this.media,
    required this.audioPlayer,
    required this.showSavedStatus,
    required this.onMusicChanged,
  });

  @override
  State<MusicItem> createState() => _MusicItemState();
}

class _MusicItemState extends State<MusicItem> {
  bool isAudioDownloaded = false;
  bool isVideoDownloaded = false;
  ProgressiveAudioSource? audioSource;

  @override
  void initState() {
    if (widget.audioPlayer.audioSource != null) {
      audioSource = widget.audioPlayer.audioSource as ProgressiveAudioSource;
    }

    Utils.checkIfFileExistsAlready(widget.media, '.mp3').then((result) {
      setState(() {
        if (result) {
          isAudioDownloaded = true;
        }
      });
    });

    Utils.checkIfFileExistsAlready(widget.media, '.mp4').then((result) {
      setState(() {
        if (result) {
          isVideoDownloaded = true;
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final savedMediaProvider = Provider.of<SavedMediaProvider>(context);
    final musicListProvider = Provider.of<MusicListProvider>(context);
    return GestureDetector(
      onTap: () {
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }

        Get.to(
          () => MusicScreen(
            onMusicChanged: () {
              widget.onMusicChanged();
            },
            isAudioDownloaded: isAudioDownloaded,
            isVideoDownloaded: isVideoDownloaded,
            audioPlayer: widget.audioPlayer,
            media: widget.media,
            onDownloadComplete: () {
              savedMediaProvider.setMedia();
              musicListProvider.rebuildWidgets();
            },
          ),
          transition: Transition.fade,
          fullscreenDialog: true,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeIn,
        );
      },
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            height: 100,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
                side: BorderSide(
                  width: 2,
                  color: AppConstants.primaryColor,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Card(
                      elevation: 14,
                      color: Colors.transparent,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const SkeletonAvatar(),
                          imageUrl: widget.media.photo,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      width: 160,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 16,
                          ),
                          Text(
                            widget.media.song,
                            maxLines: 1,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            widget.media.artist,
                            maxLines: 1,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (audioSource?.tag.id.toString() ==
                        widget.media.id.toString()) ...{
                      Lottie.asset(
                        'assets/animations/wave-anim.json',
                        animate: widget.audioPlayer.playing,
                        height: 36,
                        addRepaintBoundary: true,
                        reverse: true,
                        frameRate: FrameRate(144),
                        filterQuality: FilterQuality.high,
                      ),
                    } else ...{
                      const Icon(Iconsax.arrow_right),
                    },
                    const SizedBox(
                      width: 8,
                    )
                  ],
                ),
              ),
            ),
          ),
          if (widget.media.audioLink.isNotEmpty) ...{
            Positioned(
              right: 24,
              child: Card(
                elevation: 10,
                color: isAudioDownloaded ? Colors.green : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(
                    Iconsax.music,
                    size: 20,
                    color: isAudioDownloaded ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          },
          if (widget.media.videoLink != null) ...{
            Positioned(
              right: 68,
              child: Card(
                elevation: 10,
                color: isVideoDownloaded ? Colors.green : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(
                    Iconsax.video,
                    size: 22,
                    color: isVideoDownloaded ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          },
          Visibility(
            visible: widget.showSavedStatus,
            child: Positioned(
              right: widget.media.videoLink != null ? 110 : 68,
              child: Card(
                elevation: 10,
                color: HiveService.isMediaAlreadySaved(widget.media)
                    ? Colors.amber
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(
                    Iconsax.save_2,
                    size: 20,
                    color: isVideoDownloaded ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
