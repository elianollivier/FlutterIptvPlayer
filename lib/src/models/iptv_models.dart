import 'dart:convert';

enum IptvItemType { folder, media }

class ChannelLink {
  final String name;
  final String url;
  final String logo;
  final String resolution;
  final String fps;
  final String notes;

  ChannelLink({
    required this.name,
    required this.url,
    this.logo = '',
    required this.resolution,
    required this.fps,
    required this.notes,
  });

  factory ChannelLink.fromJson(Map<String, dynamic> json) => ChannelLink(
        name: json['name'] as String,
        url: json['url'] as String,
        logo: json['logo'] as String? ?? '',
        resolution: json['resolution'] as String? ?? '',
        fps: json['fps'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'logo': logo,
        'resolution': resolution,
        'fps': fps,
        'notes': notes,
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
