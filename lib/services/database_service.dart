import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_meadia_app/models/media.dart';
import 'package:flutter_meadia_app/models/music.dart';

class DatabaseService {
  static const String mediaBoxName = 'mediaBox';
  static const String musicBoxName = 'musicBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MediaAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MusicAdapter());
    }

    await Hive.openBox<Media>(mediaBoxName);
    await Hive.openBox<Music>(musicBoxName);
  }

  static Future<void> addMedia(Media media) async {
    final box = Hive.box<Media>(mediaBoxName);
    await box.put(media.id, media);
  }

  static Future<void> deleteMedia(String id) async {
    final box = Hive.box<Media>(mediaBoxName);
    await box.delete(id);
  }

  static Media? getMedia(String id) {
    final box = Hive.box<Media>(mediaBoxName);
    return box.get(id);
  }

  static List<Media> getAllMedia() {
    final box = Hive.box<Media>(mediaBoxName);
    final mediaList = box.values.toList();
    mediaList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mediaList;
  }

  static Future<void> updateMedia(String id, Media media) async {
    final box = Hive.box<Media>(mediaBoxName);
    await box.put(id, media);
  }

  static Future<void> addMusic(Music music) async {
    final box = Hive.box<Music>(musicBoxName);
    await box.put(music.id, music);
  }

  static Future<void> deleteMusic(String id) async {
    final box = Hive.box<Music>(musicBoxName);
    await box.delete(id);
  }

  static Music? getMusic(String id) {
    final box = Hive.box<Music>(musicBoxName);
    return box.get(id);
  }

  static List<Music> getAllMusic() {
    final box = Hive.box<Music>(musicBoxName);
    final musicList = box.values.toList();
    musicList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return musicList;
  }

  static Future<void> updateMusic(String id, Music music) async {
    final box = Hive.box<Music>(musicBoxName);
    await box.put(id, music);
  }

  static Future<void> clearAllData() async {
    await Hive.box<Media>(mediaBoxName).clear();
    await Hive.box<Music>(musicBoxName).clear();
  }

  static Future<void> deleteAllMedia() async {
    await Hive.box<Media>(mediaBoxName).clear();
  }

  static Future<void> deleteAllMusic() async {
    await Hive.box<Music>(musicBoxName).clear();
  }
}
