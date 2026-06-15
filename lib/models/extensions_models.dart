class ExtRepo {
  final String name;
  final String website;
  final String jsonUrl;

  ExtRepo({required this.name, required this.website, required this.jsonUrl});

  factory ExtRepo.fromJson(Map<String, dynamic> json) {
    return ExtRepo(
      name: json['meta']?['name'] ?? json['name'] ?? 'Unknown Repo',
      website: json['meta']?['website'] ?? json['website'] ?? '',
      jsonUrl: json['jsonUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'website': website,
    'jsonUrl': jsonUrl,
  };

  @override
  bool operator ==(Object other) {
    return other is ExtRepo && jsonUrl == other.jsonUrl;
  }

  @override
  int get hashCode => jsonUrl.hashCode;
}

class ExtSource {
  final String name;
  final int id;
  final String baseUrl;
  final String lang;
  final String version;
  final String sourceCodeUrl;
  String? sourceCode;
  final String iconUrl;
  final bool isManga;
  final bool isNsfw;
  final String apiUrl;
  final String dateFormat;
  final String dateFormatLocale;

  ExtSource({
    required this.name,
    required this.id,
    required this.baseUrl,
    required this.lang,
    required this.version,
    required this.sourceCodeUrl,
    this.sourceCode,
    this.iconUrl = '',
    this.isManga = true,
    this.isNsfw = false,
    this.apiUrl = '',
    this.dateFormat = '',
    this.dateFormatLocale = '',
  });

  factory ExtSource.fromJson(Map<String, dynamic> json) {
    return ExtSource(
      name: json['name'] ?? '',
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      baseUrl: json['baseUrl'] ?? '',
      lang: json['lang'] ?? '',
      version: json['version'] ?? '',
      sourceCodeUrl: json['sourceCodeUrl'] ?? '',
      sourceCode: json['sourceCode'],
      iconUrl: json['iconUrl'] ?? json['icon'] ?? '',
      isManga: json['isManga'] ?? true,
      isNsfw: json['isNsfw'] ?? false,
      apiUrl: json['apiUrl'] ?? '',
      dateFormat: json['dateFormat'] ?? '',
      dateFormatLocale: json['dateFormatLocale'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'id': id,
    'baseUrl': baseUrl,
    'lang': lang,
    'version': version,
    'sourceCodeUrl': sourceCodeUrl,
    'sourceCode': sourceCode,
    'iconUrl': iconUrl,
    'isManga': isManga,
    'isNsfw': isNsfw,
    'apiUrl': apiUrl,
    'dateFormat': dateFormat,
    'dateFormatLocale': dateFormatLocale,
  };
}

class ExtEpisode {
  final String name;
  final String url;
  final String? thumbnailUrl;
  final String? description;

  ExtEpisode({
    required this.name,
    required this.url,
    this.thumbnailUrl,
    this.description,
  });

  factory ExtEpisode.fromJson(Map<String, dynamic> json) {
    return ExtEpisode(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'url': url,
    'thumbnailUrl': thumbnailUrl,
    'description': description,
  };
}

class ExtSubtitle {
  final String file;
  final String label;

  ExtSubtitle({required this.file, required this.label});

  factory ExtSubtitle.fromJson(Map<String, dynamic> json) {
    return ExtSubtitle(
      file: json['file'] ?? '',
      label: json['label'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() => {'file': file, 'label': label};
}

class ExtVideo {
  final String url;
  final String originalUrl;
  final String quality;
  final Map<String, String> headers;
  final List<ExtSubtitle> subtitles;

  ExtVideo({
    required this.url,
    required this.originalUrl,
    required this.quality,
    required this.headers,
    required this.subtitles,
  });

  factory ExtVideo.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['headers'] ?? {};
    final Map<String, String> parsedHeaders = {};
    rawHeaders.forEach((key, val) {
      parsedHeaders[key.toString()] = val.toString();
    });

    final rawSubs = json['subtitles'] as List? ?? [];
    final parsedSubs = rawSubs
        .map((e) => ExtSubtitle.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return ExtVideo(
      url: json['url'] ?? '',
      originalUrl: json['originalUrl'] ?? '',
      quality: json['quality'] ?? 'Auto',
      headers: parsedHeaders,
      subtitles: parsedSubs,
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'originalUrl': originalUrl,
    'quality': quality,
    'headers': headers,
    'subtitles': subtitles.map((e) => e.toJson()).toList(),
  };
}
