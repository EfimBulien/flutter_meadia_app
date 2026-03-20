import 'package:hive/hive.dart';

part 'music.g.dart';

@HiveType(typeId: 1)
class Music extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String filePath; // Local path or URL

  @HiveField(3)
  late bool isUrl; // true if filePath is a URL, false if local file

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  String? artist;

  @HiveField(6)
  String? album;

  @HiveField(7)
  int? duration; // Duration in milliseconds

  @HiveField(8)
  String? thumbnailPath;

  Music({
    required this.id,
    required this.title,
    required this.filePath,
    required this.isUrl,
    required this.createdAt,
    this.artist,
    this.album,
    this.duration,
    this.thumbnailPath,
  });
}
