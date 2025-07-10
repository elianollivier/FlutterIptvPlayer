class M3uPlaylist {
  final String id;
  final String name;
  final String path;
  final String? logoPath;

  M3uPlaylist({
    required this.id,
    required this.name,
    required this.path,
    this.logoPath,
  });

  factory M3uPlaylist.fromJson(Map<String, dynamic> json) => M3uPlaylist(
        id: json['id'] as String,
        name: json['name'] as String,
        path: json['path'] as String,
        logoPath: json['logoPath'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'logoPath': logoPath,
      };
}
