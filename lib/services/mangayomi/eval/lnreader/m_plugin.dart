class ChapterItem {
  String name;
  String path;
  String? releaseTime;
  int? chapterNumber;
  String? page;
  String? scanlator;

  ChapterItem({
    required this.name,
    required this.path,
    this.releaseTime,
    this.chapterNumber,
    this.page,
    this.scanlator,
  });

  factory ChapterItem.fromJson(Map<String, dynamic> json) {
    return ChapterItem(
      name: json['name']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      releaseTime: json['releaseTime']?.toString(),
      chapterNumber: json['chapterNumber'] != null
          ? int.tryParse(json['chapterNumber'].toString())
          : null,
      page: json['page']?.toString(),
      scanlator: json['scanlator'] is List
          ? (json['scanlator'] as List).join(', ')
          : json['scanlator']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'releaseTime': releaseTime,
      'chapterNumber': chapterNumber,
      'page': page,
      'scanlator': scanlator,
    };
  }
}

class NovelItem {
  String name;
  String path;
  String? cover;

  NovelItem({required this.name, required this.path, this.cover});

  factory NovelItem.fromJson(Map<String, dynamic> json) {
    return NovelItem(
      name: json['name']?.toString() ?? '',
      path: json['path']?.toString() ?? '',
      cover: json['cover']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'path': path, 'cover': cover};
  }
}

class SourceNovel {
  String name;
  String path;
  String? cover;
  String? genres;
  String? summary;
  String? author;
  String? artist;
  String? status;
  double? rating;
  List<ChapterItem>? chapters;
  int? totalPages;

  SourceNovel({
    required this.name,
    required this.path,
    this.cover,
    this.genres,
    this.summary,
    this.author,
    this.artist,
    this.status,
    this.rating,
    this.chapters,
    this.totalPages,
  });

  factory SourceNovel.fromJson(Map<String, dynamic> json) {
    if (json['path'] == null) {
      throw Exception(
        'The source returned a novel with no path, so it cannot be opened. '
        'This is the extension rather than Zenbu'
        '${json['name'] is String ? ' (while reading "${json['name']}")' : ''}.',
      );
    }
    return SourceNovel(
      name: json['name']?.toString() ?? '',
      path: json['path'].toString(),
      cover: json['cover']?.toString(),
      genres: json['genres']?.toString(),
      summary: json['summary']?.toString(),
      author: json['author']?.toString(),
      artist: json['artist']?.toString(),
      status: json['status']?.toString(),
      rating: json['rating'] is double
          ? json['rating']
          : double.tryParse(json['rating']?.toString() ?? ''),
      chapters: (json['chapters'] as List<dynamic>?)
          ?.map(
            (item) =>
                ChapterItem.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      totalPages: json['totalPages'] is int
          ? json['totalPages'] as int
          : int.tryParse(json['totalPages']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'path': path,
      'cover': cover,
      'genres': genres,
      'summary': summary,
      'author': author,
      'artist': artist,
      'status': status,
      'rating': rating,
      'chapters': chapters?.map((item) => item.toJson()).toList(),
      'totalPages': totalPages,
    };
  }
}

class SourcePage {
  List<ChapterItem> chapters;

  SourcePage({required this.chapters});

  factory SourcePage.fromJson(Map<String, dynamic> json) {
    return SourcePage(
      chapters:
          (json['chapters'] as List<dynamic>?)
              ?.map(
                (item) => ChapterItem.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'chapters': chapters.map((item) => item.toJson()).toList()};
  }
}
