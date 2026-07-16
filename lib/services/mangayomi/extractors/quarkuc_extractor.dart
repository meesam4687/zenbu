import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';

enum CloudDriveType { quark, uc }

final _cookieStore = <String, String>{};

class QuarkUcExtractor {
  late CloudDriveType cloudDriveType;
  String apiUrl = '';
  String refererUrl = '';
  String ua = '';
  String host = '';
  Map<String, dynamic> shareTokenCache = {};
  String pr = '';
  final List<String> subtitleExts = ['.srt', '.ass', '.scc', '.stl', '.ttml'];
  Map<String, String> saveFileIdCaches = {};
  String? saveDirId;
  final String saveDirName = 'TV';
  String _lastCookieKey = '';

  InterceptedClient _buildClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    return InterceptedClient.build(
      client: IOClient(httpClient),
      interceptors: [],
    );
  }

  Future<void> initCloudDrive(String cookie, CloudDriveType type) async {
    cloudDriveType = type;
    if (type == CloudDriveType.quark) {
      apiUrl = 'https://drive-pc.quark.cn/1/clouddrive/';
      pr = 'pr=ucpro&fr=pc';
      ua =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) quark-cloud-drive/2.5.20 Chrome/100.0.4896.160 Electron/18.3.5.4-b478491100 Safari/537.36 Channel/pckk_other_ch';
      refererUrl = 'https://pan.quark.cn/';
      host = 'https://quark.cn';
      _lastCookieKey = 'quark_last_cookie';
    } else {
      apiUrl = 'https://pc-api.uc.cn/1/clouddrive/';
      pr = 'pr=UCBrowser&fr=pc';
      ua =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) uc-cloud-drive/2.5.20 Chrome/100.0.4896.160 Electron/18.3.5.4-b478491100 Safari/537.36 Channel/pckk_other_ch';
      refererUrl = 'https://drive.uc.cn/';
      host = 'https://uc.cn';
      _lastCookieKey = 'uc_last_cookie';
    }
    if (cookie.isNotEmpty && _cookieStore[_lastCookieKey] != cookie) {
      _cookieStore[host] = cookie;
      _cookieStore[_lastCookieKey] = cookie;
    }
  }

  String getCurrentCookie() => _cookieStore[host] ?? '';

  Map<String, String> getHeaders() => {
    'User-Agent': ua,
    'Referer': refererUrl,
    'Content-Type': 'application/json',
    'Cookie': getCurrentCookie(),
  };

  Future<Map<String, dynamic>> api(
    String url,
    dynamic data,
    String method,
  ) async {
    final client = _buildClient();
    try {
      late Response resp;
      if (method != 'get') {
        resp = await client.post(
          Uri.parse(apiUrl + url),
          body: jsonEncode(data),
          headers: getHeaders(),
        );
      } else {
        resp = await client.get(Uri.parse(apiUrl + url), headers: getHeaders());
      }
      final setCookie = resp.headers['set-cookie'];
      if (setCookie != null) {
        for (final cookie in setCookie.split(';;;')) {
          if (cookie.contains('__puus=')) {
            final newPuus = cookie.split(';')[0];
            var current = getCurrentCookie();
            if (current.contains('__puus=')) {
              current = current.replaceFirst(RegExp(r'__puus=[^;]+'), newPuus);
            } else {
              current = '$current; $newPuus';
            }
            _cookieStore[host] = current;
            break;
          }
        }
      }
      return jsonDecode(resp.body);
    } finally {
      client.close();
    }
  }

  Map<String, String>? getShareData(String url) {
    RegExp regex;
    if (cloudDriveType == CloudDriveType.quark) {
      regex = RegExp(r'https://pan\.quark\.cn/s/([^\\|#/]+)');
    } else {
      regex = RegExp(r'https://drive\.uc\.cn/s/([^?]+)');
    }
    final m = regex.firstMatch(url);
    if (m == null) return null;
    return {'shareId': m.group(1)!, 'folderId': '0'};
  }

  Future<void> getShareToken(Map<String, String> shareData) async {
    final shareId = shareData['shareId']!;
    if (!shareTokenCache.containsKey(shareId)) {
      final token = await api('share/sharepage/token?$pr', {
        'pwd_id': shareId,
        'passcode': shareData['sharePwd'] ?? '',
      }, 'post');
      if (token['data']?['stoken'] != null) {
        shareTokenCache[shareId] = token['data'];
      }
    }
  }

  Future<List<dynamic>> listFile(
    int shareIndex,
    Map<String, String> shareData,
    List<dynamic> videos,
    List<dynamic> subtitles,
    String shareId,
    String folderId, {
    int page = 1,
  }) async {
    const prePage = 200;
    final listData = await api(
      'share/sharepage/detail?$pr&pwd_id=$shareId&stoken=${Uri.encodeComponent(shareTokenCache[shareId]['stoken'])}&pdir_fid=$folderId&force=0&_page=$page&_size=$prePage&_sort=file_type:asc,file_name:desc',
      null,
      'get',
    );
    if (listData['data'] == null) return [];
    final items = listData['data']['list'] as List? ?? [];
    final subDir = [];
    for (final item in items) {
      if (item['dir'] == true) {
        subDir.add(item);
      } else if (item['file'] == true && item['obj_category'] == 'video') {
        if ((item['size'] as int) < 1024 * 1024 * 5) continue;
        item['stoken'] = shareTokenCache[shareData['shareId']!]['stoken'];
        videos.add(Item.fromJson(item, shareId, shareIndex, cloudDriveType));
      } else if (item['type'] == 'file' &&
          subtitleExts.any((x) => (item['file_name'] as String).endsWith(x))) {
        subtitles.add(Item.fromJson(item, shareId, shareIndex, cloudDriveType));
      }
    }
    final total = listData['metadata']['_total'] as int;
    if (page < (total / prePage).ceil()) {
      await listFile(
        shareIndex,
        shareData,
        videos,
        subtitles,
        shareId,
        folderId,
        page: page + 1,
      );
    }
    for (final dir in subDir) {
      await listFile(
        shareIndex,
        shareData,
        videos,
        subtitles,
        shareId,
        dir['fid'] as String,
      );
    }
    return items;
  }

  Future<void> getFilesByShareUrl(
    int shareIndex,
    dynamic shareInfo,
    List<dynamic> videos,
    List<dynamic> subtitles,
  ) async {
    final shareData = shareInfo is String
        ? getShareData(shareInfo)
        : shareInfo as Map<String, String>?;
    if (shareData == null) return;
    await getShareToken(shareData);
    if (!shareTokenCache.containsKey(shareData['shareId'])) return;
    await listFile(
      shareIndex,
      shareData,
      videos,
      subtitles,
      shareData['shareId']!,
      shareData['folderId']!,
    );
  }

  String? saveDirIdCached;

  Future<void> createSaveDir(bool clean) async {
    if (saveDirId != null) {
      if (clean) {
        await clearSaveDir();
      }
      return;
    }
    final listData = await api(
      'file/sort?$pr&pdir_fid=0&_page=1&_size=200&_sort=file_type:asc,updated_at:desc',
      {},
      'get',
    );
    if (listData['data']?['list'] != null) {
      for (final item in listData['data']['list']) {
        if (item['file_name'] == saveDirName) {
          saveDirId = item['fid'];
          await clearSaveDir();
          return;
        }
      }
    }
    final create = await api('file?$pr', {
      'pdir_fid': '0',
      'file_name': saveDirName,
      'dir_path': '',
      'dir_init_lock': false,
    }, 'post');
    if (create['data']?['fid'] != null) saveDirId = create['data']['fid'];
  }

  Future<void> clearSaveDir() async {
    final listData = await api(
      'file/sort?$pr&pdir_fid=$saveDirId&_page=1&_size=200&_sort=file_type:asc,updated_at:desc',
      {},
      'get',
    );
    if ((listData['data']?['list'] as List?)?.isNotEmpty == true) {
      await api('file/delete?$pr', {
        'action_type': 2,
        'filelist': (listData['data']['list'] as List)
            .map((v) => v['fid'])
            .toList(),
        'exclude_fids': [],
      }, 'post');
    }
  }

  Future<String?> save(
    String shareId,
    String stoken,
    String fileId,
    String fileToken,
    bool clean,
  ) async {
    await createSaveDir(clean);
    if (clean) saveFileIdCaches.clear();
    if (saveDirId == null) return null;
    if (stoken.isEmpty) {
      await getShareToken({'shareId': shareId});
      if (!shareTokenCache.containsKey(shareId)) return null;
    }
    final saveResult = await api('share/sharepage/save?$pr', {
      'fid_list': [fileId],
      'fid_token_list': [fileToken],
      'to_pdir_fid': saveDirId,
      'pwd_id': shareId,
      'stoken': stoken.isNotEmpty ? stoken : shareTokenCache[shareId]['stoken'],
      'pdir_fid': '0',
      'scene': 'link',
    }, 'post');
    if (saveResult['data']?['task_id'] != null) {
      for (int retry = 0; retry <= 2; retry++) {
        final task = await api(
          'task?$pr&task_id=${saveResult['data']['task_id']}&retry_index=$retry',
          {},
          'get',
        );
        final fids = task['data']?['save_as']?['save_as_top_fids'] as List?;
        if (fids != null && fids.isNotEmpty) return fids[0] as String;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    return null;
  }

  Future<List<Map<String, String>>?> getLiveTranscoding(
    String shareId,
    String stoken,
    String fileId,
    String fileToken,
  ) async {
    if (!saveFileIdCaches.containsKey(fileId)) {
      final saveFileId = await save(shareId, stoken, fileId, fileToken, true);
      if (saveFileId == null) return null;
      saveFileIdCaches[fileId] = saveFileId;
    }
    final transcoding = await api('file/v2/play?$pr', {
      'fid': saveFileIdCaches[fileId],
      'resolutions': 'normal,low,high,super,2k,4k',
      'supports': 'fmp4',
    }, 'post');
    if (transcoding['data']?['video_list'] != null) {
      return (transcoding['data']['video_list'] as List)
          .map<Map<String, String>>(
            (v) => {
              'url': v['video_info']['url'].toString(),
              'quality': v['resolution'].toString(),
            },
          )
          .toList();
    }
    return null;
  }

  Future<Map<String, dynamic>?> getDownload(
    String shareId,
    String stoken,
    String fileId,
    String fileToken,
    bool clean,
  ) async {
    if (!saveFileIdCaches.containsKey(fileId)) {
      final saveFileId = await save(shareId, stoken, fileId, fileToken, clean);
      if (saveFileId == null) return null;
      saveFileIdCaches[fileId] = saveFileId;
    }
    final down = await api('file/download?$pr&uc_param_str=', {
      'fids': [saveFileIdCaches[fileId]],
    }, 'post');
    return down['data'] != null
        ? (down['data'] as List).first as Map<String, dynamic>
        : null;
  }

  Future<List<Video>> videosFromUrl(String url) async {
    final parts = url.split('++');
    if (parts.length < 5) return [];
    final fileId = parts[1];
    final fileToken = parts[2];
    final shareId = parts[3];
    final stoken = parts[4];
    final subtitleParts = parts.length > 5 ? parts[5].split('+') : <String>[];
    final qualityOptions = await getLiveTranscoding(
      shareId,
      stoken,
      fileId,
      fileToken,
    );
    if (qualityOptions == null) return [];
    final headers = Map<String, String>.from(getHeaders())
      ..remove('Content-Type');
    final originalUrl = qualityOptions.first['url'] ?? '';
    final videos = qualityOptions
        .map(
          (q) => Video(q['url']!, q['quality']!, originalUrl, headers: headers),
        )
        .toList();
    final subs = <Track>[];
    for (final subInfo in subtitleParts) {
      if (subInfo.isEmpty) continue;
      final subParts = subInfo.split('@@@');
      if (subParts.length == 3) {
        final subName = subParts[0];
        final subFileId = subParts[2];
        final subDownload = await getDownload(
          shareId,
          stoken,
          subFileId,
          '',
          false,
        );
        final subUrl = subDownload?['download_url']?.toString();
        if (subUrl != null) subs.add(Track(file: subUrl, label: subName));
      }
    }
    for (var v in videos) {
      v.subtitles = subs;
    }
    return videos;
  }

  Future<List<Map<String, String>>> videoFilesFromUrl(
    List<String> shareUrlList,
  ) async {
    final videoItems = <dynamic>[];
    final subItems = <dynamic>[];
    for (int i = 0; i < shareUrlList.length; i++) {
      await getFilesByShareUrl(i + 1, shareUrlList[i], videoItems, subItems);
    }
    return _getVodFile(videoItems, subItems);
  }

  List<Map<String, String>> _getVodFile(
    List<dynamic> videoItemList,
    List<dynamic> subItemList,
  ) {
    if (videoItemList.isEmpty) return [];
    return videoItemList.map<Map<String, String>>((item) {
      final episodeUrl = (item as Item).getEpisodeUrl('电影');
      final parts = episodeUrl.split(r'$');
      return {
        'name': parts[0].trim(),
        'url': parts.length > 1 ? parts[1] : episodeUrl,
      };
    }).toList();
  }
}

class Item {
  String fileId = '';
  String shareId = '';
  String shareToken = '';
  String shareFileToken = '';
  String name = '';
  int shareIndex = 0;
  late CloudDriveType cloudDriveType;

  static Item fromJson(
    Map<String, dynamic> json,
    String shareId,
    int shareIndex,
    CloudDriveType type,
  ) {
    return Item()
      ..fileId = json['fid']?.toString() ?? ''
      ..shareId = shareId
      ..shareToken = json['stoken']?.toString() ?? ''
      ..shareFileToken = json['share_fid_token']?.toString() ?? ''
      ..name = json['file_name']?.toString() ?? ''
      ..shareIndex = shareIndex
      ..cloudDriveType = type;
  }

  String getName() => name;
  String getFileId() => fileId;
  String getFileExtension() => name.contains('.') ? name.split('.').last : '';
  String getSize() => '';

  String getDisplayName(String typeName) {
    final prefix = cloudDriveType == CloudDriveType.quark ? '[quark]' : '[uc]';
    return '$prefix $name';
  }

  String getEpisodeUrl(String typeName) {
    final type = cloudDriveType == CloudDriveType.quark ? 'quark' : 'uc';
    return '${getDisplayName(typeName)}\$$type++$fileId++$shareFileToken++$shareId++$shareToken';
  }
}
