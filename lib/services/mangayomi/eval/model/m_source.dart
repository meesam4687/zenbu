class Source {
  int? id;
  String? name;
  String? baseUrl;
  String? lang;
  bool? isActive;
  bool? isAdded;
  bool? isPinned;
  bool? isNsfw;
  String? sourceCode;
  String? sourceCodeUrl;
  String? typeSource;
  String? iconUrl;
  bool? isFullData;
  bool? hasCloudflare;
  bool? lastUsed;
  String? dateFormat;
  String? dateFormatLocale;
  String? apiUrl;
  String? version;
  String? versionLast;
  String? headers;
  bool? supportLatest;
  String? filterList;
  String? preferenceList;
  bool? isManga;
  String? appMinVerReq;
  String? additionalParams;
  bool? isLocal;
  bool? isObsolete;
  String? notes;
  int? updatedAt;
  SourceCodeLanguage? sourceCodeLanguage;

  Source({
    this.id,
    this.name,
    this.baseUrl,
    this.lang,
    this.sourceCodeLanguage,
    this.isActive = true,
    this.isAdded = false,
    this.isPinned = false,
    this.isNsfw = false,
    this.sourceCode,
    this.sourceCodeUrl,
    this.typeSource,
    this.iconUrl,
    this.isFullData = false,
    this.hasCloudflare = false,
    this.lastUsed = false,
    this.dateFormat,
    this.dateFormatLocale,
    this.apiUrl,
    this.version,
    this.versionLast,
    this.headers,
    this.supportLatest = false,
    this.filterList,
    this.preferenceList,
    this.isManga = true,
    this.appMinVerReq,
    this.additionalParams,
    this.isLocal = false,
    this.isObsolete = false,
    this.notes,
    this.updatedAt,
  });

  MSource toMSource() {
    return MSource(
      id: id,
      name: name,
      baseUrl: baseUrl,
      lang: lang,
      isFullData: isFullData,
      hasCloudflare: hasCloudflare,
      dateFormat: dateFormat,
      dateFormatLocale: dateFormatLocale,
      apiUrl: apiUrl,
      additionalParams: additionalParams,
      notes: notes,
    );
  }
}

class MSource {
  int? id;
  String? name;
  String? baseUrl;
  String? lang;
  bool? isFullData;
  bool? hasCloudflare;
  String? dateFormat;
  String? dateFormatLocale;
  String? apiUrl;
  String? additionalParams;
  String? notes;

  MSource({
    this.id,
    this.name,
    this.baseUrl,
    this.lang,
    this.isFullData,
    this.hasCloudflare,
    this.dateFormat,
    this.dateFormatLocale,
    this.apiUrl,
    this.additionalParams,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'apiUrl': apiUrl,
    'baseUrl': baseUrl,
    'dateFormat': dateFormat,
    'dateFormatLocale': dateFormatLocale,
    'hasCloudflare': hasCloudflare,
    'id': id,
    'isFullData': isFullData,
    'lang': lang,
    'name': name,
    'additionalParams': additionalParams,
    'notes': notes,
  };
}

enum SourceCodeLanguage { dart, javascript, mihon, lnreader }
