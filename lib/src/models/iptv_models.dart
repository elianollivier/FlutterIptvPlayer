import 'dart:convert';

enum IptvItemType { folder, channel }

class ChannelLink {
  final String name;
  final String url;
  final String resolution;
  final String fps;
  final String notes;

  ChannelLink({
    required this.name,
    required this.url,
    required this.resolution,
    required this.fps,
    required this.notes,
  });

  factory ChannelLink.fromJson(Map<String, dynamic> json) => ChannelLink(
        name: json['name'] as String,
        url: json['url'] as String,
        resolution: json['resolution'] as String? ?? '',
        fps: json['fps'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        'resolution': resolution,
        'fps': fps,
        'notes': notes,
      };

  ChannelLink copyWith({
    String? name,
    String? url,
    String? resolution,
    String? fps,
    String? notes,
  }) {
    return ChannelLink(
      name: name ?? this.name,
      url: url ?? this.url,
      resolution: resolution ?? this.resolution,
      fps: fps ?? this.fps,
      notes: notes ?? this.notes,
    );
  }
}

class IptvItem {
  final String id;
  final IptvItemType type;
  final String name;
  final String? logoPath;
  final List<ChannelLink> links;
  final String? parentId;

  IptvItem({
    required this.id,
    required this.type,
    required this.name,
    this.logoPath,
    this.links = const [],
    this.parentId,
  });

  factory IptvItem.fromJson(Map<String, dynamic> json) => IptvItem(
        id: json['id'] as String,
        type: IptvItemType.values[json['type'] as int],
        name: json['name'] as String,
        logoPath: json['logoPath'] as String?,
        links: (json['links'] as List<dynamic>? ?? [])
            .map((e) => ChannelLink.fromJson(e as Map<String, dynamic>))
            .toList(),
        parentId: json['parentId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.index,
        'name': name,
        'logoPath': logoPath,
        'links': links.map((e) => e.toJson()).toList(),
        'parentId': parentId,
      };

  @override
  String toString() => jsonEncode(toJson());

  IptvItem copyWith({
    String? id,
    IptvItemType? type,
    String? name,
    String? logoPath,
    List<ChannelLink>? links,
    String? parentId,
  }) {
    return IptvItem(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      logoPath: logoPath ?? this.logoPath,
      links: links ?? this.links,
      parentId: parentId ?? this.parentId,
    );
  }
}
