class Video {
  String url;
  String quality;
  String originalUrl;
  Map<String, String>? headers;
  List<Track>? subtitles;
  List<Track>? audios;

  Video(
    this.url,
    this.quality,
    this.originalUrl, {
    this.headers,
    this.subtitles,
    this.audios,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      json['url']?.toString().trim() ?? '',
      json['quality']?.toString().trim() ?? 'Auto',
      json['originalUrl']?.toString().trim() ?? '',
      headers: json['headers'] != null
          ? (json['headers'] as Map).map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            )
          : null,
      subtitles: json['subtitles'] != null
          ? (json['subtitles'] as List)
                .map((e) => Track.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : [],
      audios: json['audios'] != null
          ? (json['audios'] as List)
                .map((e) => Track.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'quality': quality,
    'originalUrl': originalUrl,
    'headers': headers,
    'subtitles': subtitles?.map((e) => e.toJson()).toList(),
    'audios': audios?.map((e) => e.toJson()).toList(),
  };
}

class Track {
  String? file;
  String? label;

  Track({this.file, this.label});

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      file: json['file']?.toString().trim(),
      label: json['label']?.toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {'file': file, 'label': label};
}
