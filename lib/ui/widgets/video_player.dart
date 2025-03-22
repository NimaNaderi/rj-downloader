import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:skeletons/skeletons.dart';
import 'package:video_player/video_player.dart';

class VidePlayer extends StatefulWidget {
  final String url;

  const VidePlayer({super.key, required this.url});

  @override
  State<VidePlayer> createState() => _VidePlayerState();
}

class _VidePlayerState extends State<VidePlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _videoPlayerController =
        VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _chewieController = ChewieController(
        autoInitialize: true,
        autoPlay: true,
        allowMuting: true,
        allowedScreenSleep: false,
        videoPlayerController: _videoPlayerController!,
        aspectRatio: 16 / 9);

    _videoPlayerController!.addListener(() {
      if (_videoPlayerController!.value.isInitialized && !isPlaying) {
        setState(() {
          isPlaying = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _videoPlayerController!.dispose();
    _chewieController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: isPlaying
          ? Chewie(
        controller: _chewieController!,
      )
          : Stack(
        fit: StackFit.expand,
        children: [
          SkeletonAvatar(
            style: SkeletonAvatarStyle(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const Center(
            child: Text(
              'Loading...',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}