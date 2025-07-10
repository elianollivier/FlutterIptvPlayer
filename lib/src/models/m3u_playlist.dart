class M3uPlaylist {
  final String id;
  final String name;
  final String path;
  final String? logoPath;
  final String? url;
  final DateTime? lastDownload;

  M3uPlaylist({
    required this.id,
    required this.name,
    required this.path,
    this.logoPath,
    this.url,
    this.lastDownload,
  });

  factory M3uPlaylist.fromJson(Map<String, dynamic> json) => M3uPlaylist(
        id: json['id'] as String,
        name: json['name'] as String,
        path: json['path'] as String,
        logoPath: json['logoPath'] as String?,
        url: json['url'] as String?,
        lastDownload: json['lastDownload'] != null
            ? DateTime.parse(json['lastDownload'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'logoPath': logoPath,
        'url': url,
        'lastDownload': lastDownload?.toIso8601String(),
      };
}
