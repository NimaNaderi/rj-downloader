import 'dart:convert';

import 'package:rj_downloader/data/models/media.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioPlayerConfig {
  static SharedPreferences? sharedPrefs;

  static Future<void> initSharedPrefs() async {
    sharedPrefs = await SharedPreferences.getInstance();
  }

  static Future<void> setIsLoop(bool isLoop) async {
    await sharedPrefs!.setBool('isLoop', isLoop);
  }

  static bool? getIsLoop() {
    return sharedPrefs!.getBool('isLoop');
  }

  static Future<void> setLatestMedia(Media media) async {
    Map<String, dynamic> mediaToSave = {
      'id': media.id,
      'audioLink': media.audioLink,
      'videoLink': media.videoLink,
      'artist': media.artist,
      'song': media.song,
      'photo': media.photo,
      'duration': media.duration,
    };

    await sharedPrefs!.setString('latestMedia', jsonEncode(mediaToSave));
  }

  static Media? getLatestMedia() {
    String? latestMediaString = sharedPrefs!.getString('latestMedia');

    Map<String, dynamic> latestMediaMap;

    if (latestMediaString != null) {
      latestMediaMap =
      jsonDecode(latestMediaString) as Map<String, dynamic>;
      return Media(
        audioLink: latestMediaMap['audioLink'],
        artist: latestMediaMap['artist'],
        song: latestMediaMap['song'],
        photo: latestMediaMap['photo'],
        duration: latestMediaMap['duration'],
        id: latestMediaMap['id'],
      );
    }

    return null;


  }
}
