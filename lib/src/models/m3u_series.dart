class M3uEpisode {
  final String name;
  final String url;
  final int season;
  final int episode;
  final String logo;

  M3uEpisode({
    required this.name,
    required this.url,
    required this.season,
    required this.episode,
    required this.logo,
  });
}

class M3uSeries {
  final String name;
  final String logo;
  final List<M3uEpisode> episodes;

  M3uSeries({required this.name, required this.logo, required this.episodes});
}
