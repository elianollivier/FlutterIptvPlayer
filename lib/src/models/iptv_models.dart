import 'dart:convert';

enum IptvItemType { folder, media }

class Note {
  final String text;
  final DateTime date;

  Note({
    required this.text,
    required this.date,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        text: json['text'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'date': date.toIso8601String(),
      };
}

class ChannelLink {
  final String name;
  final String url;
  final String logo;
  final String resolution;
  final String fps;
  final List<Note> notes;

  ChannelLink({
    required this.name,
    required this.url,
    this.logo = '',
    required this.resolution,
    required this.fps,
    this.notes = const [],
  });

  factory ChannelLink.fromJson(Map<String, dynamic> json) {
    final rawNotes = json['notes'];
    List<Note> notes = [];
    if (rawNotes is List) {
      notes = rawNotes
          .map((e) {
            if (e is Map<String, dynamic>) {
              return Note.fromJson(e);
            } else if (e is String) {
              return Note(text: e, date: DateTime.now());
            } else {
              return Note(text: e.toString(), date: DateTime.now());
            }
          })
          .toList();
    } else if (rawNotes is String && rawNotes.isNotEmpty) {
      notes = [Note(text: rawNotes, date: DateTime.now())];
    }

    return ChannelLink(
      name: json['name'] as String,
      url: json['url'] as String,
      logo: json['logo'] as String? ?? '',
      resolution: json['resolution'] as String? ?? '',
      fps: json['fps'] as String? ?? '',
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'logo': logo,
        'resolution': resolution,
        'fps': fps,
        'notes': notes.map((e) => e.toJson()).toList(),
      };
}

extension ChannelLinkFormatting on ChannelLink {
  String get formattedName {
    final details = [resolution, fps].where((e) => e.isNotEmpty).join(' ');
    return details.isEmpty ? name : '$name [$details]';
  }
}

class IptvItem {
  final String id;
  final IptvItemType type;
  final String name;
  final String? logoPath;
  final String? logoUrl;
  final List<ChannelLink> links;
  final String? parentId;
  final bool viewed;
  final int position;

  IptvItem({
    required this.id,
    required this.type,
    required this.name,
    this.logoPath,
    this.logoUrl,
    this.links = const [],
    this.parentId,
    this.viewed = false,
    this.position = 0,
  });

  factory IptvItem.fromJson(Map<String, dynamic> json) => IptvItem(
        id: json['id'] as String,
        type: IptvItemType.values[json['type'] as int],
        name: json['name'] as String,
        logoPath: json['logoPath'] as String?,
        logoUrl: json['logoUrl'] as String?,
        links: (json['links'] as List<dynamic>? ?? [])
            .map((e) => ChannelLink.fromJson(e as Map<String, dynamic>))
            .toList(),
        parentId: json['parentId'] as String?,
        viewed: json['viewed'] as bool? ?? false,
        position: json['position'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'name': name,
        'logoPath': logoPath,
        'logoUrl': logoUrl,
        'links': links.map((e) => e.toJson()).toList(),
        'parentId': parentId,
        'viewed': viewed,
        'position': position,
      };

  @override
  String toString() => jsonEncode(toJson());
}
