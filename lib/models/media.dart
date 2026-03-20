import 'package:hive/hive.dart';

part 'media.g.dart';

@HiveType(typeId: 0)
class Media extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String filePath;

  @HiveField(2)
  late String mediaType; // 'image' or 'video'

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  double? latitude;

  @HiveField(5)
  double? longitude;

  @HiveField(6)
  String? location;

  @HiveField(7)
  String? fileName;

  @HiveField(8)
  int? duration; // Duration in milliseconds for videos

  Media({
    required this.id,
    required this.filePath,
    required this.mediaType,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.location,
    this.fileName,
    this.duration,
  });
}
