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
  final int itemType;
  final bool isNsfw;
  final String apiUrl;
  final String dateFormat;
  final String dateFormatLocale;
  final int sourceCodeLanguage;

  ExtSource({
    required this.name,
    required this.id,
    required this.baseUrl,
    required this.lang,
    required this.version,
    required this.sourceCodeUrl,
    this.sourceCode,
    this.iconUrl = '',
    int? itemType,
    bool? isManga,
    this.isNsfw = false,
    this.apiUrl = '',
    this.dateFormat = '',
    this.dateFormatLocale = '',
    this.sourceCodeLanguage = 1,
  }) : itemType = itemType ?? (isManga == false ? 1 : 0);

  bool get isNovel => itemType == 2 || sourceCodeLanguage == 3;
  bool get isAnime => itemType == 1;
  bool get isManga => itemType == 0;

  factory ExtSource.fromJson(Map<String, dynamic> json) {
    final int sourceLang = json['sourceCodeLanguage'] is int
        ? json['sourceCodeLanguage'] as int
        : (json['sourceCodeLanguage'] != null
              ? int.tryParse(json['sourceCodeLanguage'].toString()) ?? 1
              : 1);

    int parsedItemType;
    if (json['itemType'] is int) {
      parsedItemType = json['itemType'] as int;
    } else if (json['itemType'] != null &&
        int.tryParse(json['itemType'].toString()) != null) {
      parsedItemType = int.parse(json['itemType'].toString());
    } else if (sourceLang == 3) {
      parsedItemType = 2;
    } else if (json['isNovel'] == true) {
      parsedItemType = 2;
    } else if (json['isAnime'] == true) {
      parsedItemType = 1;
    } else if (json['isManga'] == true) {
      parsedItemType = 0;
    } else if (json['isManga'] == false) {
      parsedItemType = 1;
    } else {
      parsedItemType = 0;
    }

    return ExtSource(
      name: json['name'] ?? '',
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      baseUrl: json['baseUrl'] ?? '',
      lang: json['lang'] ?? '',
      version: json['version'] ?? '',
      sourceCodeUrl: json['sourceCodeUrl'] ?? '',
      sourceCode: json['sourceCode'],
      iconUrl: json['iconUrl'] ?? json['icon'] ?? '',
      itemType: parsedItemType,
      isManga: parsedItemType == 0,
      isNsfw: json['isNsfw'] ?? false,
      apiUrl: json['apiUrl'] ?? '',
      dateFormat: json['dateFormat'] ?? '',
      dateFormatLocale: json['dateFormatLocale'] ?? '',
      sourceCodeLanguage: sourceLang,
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
    'itemType': itemType,
    'isManga': isManga,
    'isNsfw': isNsfw,
    'apiUrl': apiUrl,
    'dateFormat': dateFormat,
    'dateFormatLocale': dateFormatLocale,
    'sourceCodeLanguage': sourceCodeLanguage,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtSource && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
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
      thumbnailUrl: json['thumbnailUrl'] ??
          json['thumbnail'] ??
          json['coverUrl'] ??
          json['cover'],
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
