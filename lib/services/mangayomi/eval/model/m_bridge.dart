import 'dart:convert';
import 'dart:math';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:js_packer/js_packer.dart';
import 'package:zenbu/services/crypto_utils.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';
import 'package:zenbu/services/mangayomi/eval/model/document.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_manga.dart';
import 'package:zenbu/services/mangayomi/eval/model/m_video.dart';
import 'package:zenbu/services/mangayomi/extractors/dood_extractor.dart';
import 'package:zenbu/services/mangayomi/extractors/streamtape_extractor.dart';
import 'package:zenbu/services/mangayomi/extractors/gogocdn_extractor.dart';
import 'package:zenbu/services/mangayomi/extractors/voe_extractor.dart';
import 'package:zenbu/services/mangayomi/extractors/sibnet_extractor.dart';
import 'package:zenbu/services/mangayomi/extractors/sendvid_extractor.dart';
import 'package:zenbu/services/mangayomi/extractors/your_upload_extractor.dart';
import 'package:zenbu/services/mangayomi/extractors/vidbom_extractor.dart';
import 'package:zenbu/services/mangayomi/extractors/streamlare_extractor.dart';
import 'package:zenbu/services/mangayomi/extractors/streamwish_extractor.dart';
import 'package:zenbu/services/mangayomi/extractors/filemoon_extractor.dart';
import 'package:zenbu/services/mangayomi/extractors/mp4upload_extractor.dart';
import 'package:zenbu/services/mangayomi/extractors/mytv_extractor.dart';
import 'package:zenbu/services/mangayomi/extractors/okru_extractor.dart';
import 'package:zenbu/services/mangayomi/extractors/quarkuc_extractor.dart';

class WordSet {
  final List<String> words;

  WordSet(this.words);

  bool anyWordIn(String dateString) {
    return words.any(
      (word) => dateString.toLowerCase().contains(word.toLowerCase()),
    );
  }

  bool startsWith(String dateString) {
    return words.any(
      (word) => dateString.toLowerCase().startsWith(word.toLowerCase()),
    );
  }

  bool endsWith(String dateString) {
    return words.any(
      (word) => dateString.toLowerCase().endsWith(word.toLowerCase()),
    );
  }
}

class MBridge {
  static String? unpackJs(String code) {
    try {
      final jsPacker = JSPacker(code);
      return jsPacker.unpack() ?? "";
    } catch (_) {
      return "";
    }
  }

  static String? unpackJsAndCombine(String code) {
    try {
      return JsUnpacker.unpackAndCombine(code) ?? "";
    } catch (_) {
      return "";
    }
  }

  static String getMapValue(String source, String attr, bool encode) {
    try {
      var map = json.decode(source) as Map<String, dynamic>;
      if (!encode) {
        return map[attr] != null ? map[attr].toString() : "";
      }
      return map[attr] != null ? jsonEncode(map[attr]) : "";
    } catch (_) {
      return "";
    }
  }

  static List parseDates(
    List value,
    String dateFormat,
    String dateFormatLocale,
  ) {
    List<dynamic> val = [];
    for (var element in value) {
      element = element.toString().trim();
      if (element.isNotEmpty) {
        val.add(element);
      }
    }
    bool error = false;
    List<dynamic> valD = [];
    for (var date in val) {
      String dateStr = "";
      if (error) {
        dateStr = DateTime.now().millisecondsSinceEpoch.toString();
      } else {
        dateStr = parseChapterDate(date, dateFormat, dateFormatLocale, (val) {
          dateFormat = val.$1;
          dateFormatLocale = val.$2;
          error = val.$3;
        });
      }
      valD.add(dateStr);
    }
    return valD;
  }

  static List sortMapList(List list, String value, int type) {
    if (type == 0) {
      list.sort((a, b) => a[value].compareTo(b[value]));
    } else if (type == 1) {
      list.sort((a, b) => b[value].compareTo(a[value]));
    }

    return list;
  }

  static String regExp(
    String expression,
    String source,
    String replace,
    int type,
    int group,
  ) {
    if (type == 0) {
      return expression.replaceAll(RegExp(source), replace);
    }
    try {
      final matches = RegExp(source).allMatches(expression);
      if (matches.isNotEmpty && matches.first.groupCount >= group) {
        return matches.first.group(group) ?? '';
      }
    } catch (_) {}
    return '';
  }

  static Map<String, String> decodeHeaders(String? headers) => headers == null
      ? {}
      : (jsonDecode(headers) as Map).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        );

  static final Set<String> _initializedLocales = {};

  static String substringAfter(String text, String pattern) {
    final index = text.indexOf(pattern);
    return index == -1 ? text : text.substring(index + pattern.length);
  }

  static String substringBefore(String text, String pattern) {
    final index = text.indexOf(pattern);
    return index == -1 ? text : text.substring(0, index);
  }

  static String substringBeforeLast(String text, String pattern) {
    final index = text.lastIndexOf(pattern);
    return index == -1 ? text : text.substring(0, index);
  }

  static String substringAfterLast(String text, String pattern) {
    return text.split(pattern).last;
  }

  static String parseChapterDate(
    String date,
    String dateFormat,
    String dateFormatLocale,
    Function((String, String, bool)) newLocale,
  ) {
    try {
      if (!_initializedLocales.contains(dateFormatLocale)) {
        initializeDateFormatting(dateFormatLocale);
        _initializedLocales.add(dateFormatLocale);
      }
    } catch (_) {}

    int parseRelativeDate(String date) {
      final number = int.tryParse(RegExp(r"(\d+)").firstMatch(date)!.group(0)!);
      if (number == null) return 0;
      final cal = DateTime.now();

      if (WordSet([
        "hari",
        "gün",
        "jour",
        "día",
        "dia",
        "day",
        "วัน",
        "ngày",
        "giorni",
        "أيام",
        "天",
      ]).anyWordIn(date)) {
        return cal.subtract(Duration(days: number)).millisecondsSinceEpoch;
      } else if (WordSet([
        "jam",
        "saat",
        "heure",
        "hora",
        "hour",
        "ชั่วโมง",
        "giờ",
        "ore",
        "ساعة",
        "小时",
      ]).anyWordIn(date)) {
        return cal.subtract(Duration(hours: number)).millisecondsSinceEpoch;
      } else if (WordSet([
        "menit",
        "dakika",
        "min",
        "minute",
        "minuto",
        "นาที",
        "دقائق",
      ]).anyWordIn(date)) {
        return cal.subtract(Duration(minutes: number)).millisecondsSinceEpoch;
      } else if (WordSet([
        "detik",
        "segundo",
        "second",
        "วินาที",
        "sec",
      ]).anyWordIn(date)) {
        return cal.subtract(Duration(seconds: number)).millisecondsSinceEpoch;
      } else if (WordSet(["week", "semana"]).anyWordIn(date)) {
        return cal.subtract(Duration(days: number * 7)).millisecondsSinceEpoch;
      } else if (WordSet(["month", "mes"]).anyWordIn(date)) {
        return cal.subtract(Duration(days: number * 30)).millisecondsSinceEpoch;
      } else if (WordSet(["year", "año"]).anyWordIn(date)) {
        return cal
            .subtract(Duration(days: number * 365))
            .millisecondsSinceEpoch;
      } else {
        return 0;
      }
    }

    try {
      if (WordSet(["yesterday", "يوم واحد"]).startsWith(date)) {
        DateTime cal = DateTime.now().subtract(const Duration(days: 1));
        cal = DateTime(cal.year, cal.month, cal.day);
        return cal.millisecondsSinceEpoch.toString();
      } else if (WordSet(["today"]).startsWith(date)) {
        DateTime cal = DateTime.now();
        cal = DateTime(cal.year, cal.month, cal.day);
        return cal.millisecondsSinceEpoch.toString();
      } else if (WordSet(["يومين"]).startsWith(date)) {
        DateTime cal = DateTime.now().subtract(const Duration(days: 2));
        cal = DateTime(cal.year, cal.month, cal.day);
        return cal.millisecondsSinceEpoch.toString();
      } else if (WordSet(["ago", "atrás", "önce", "قبل"]).endsWith(date)) {
        return parseRelativeDate(date).toString();
      } else if (WordSet(["hace"]).startsWith(date)) {
        return parseRelativeDate(date).toString();
      } else if (date.contains(RegExp(r"\d(st|nd|rd|th)"))) {
        final cleanedDate = date
            .split(" ")
            .map(
              (it) => it.contains(RegExp(r"\d\D\D"))
                  ? it.replaceAll(RegExp(r"\D"), "")
                  : it,
            )
            .join(" ");
        return DateFormat(
          dateFormat,
          dateFormatLocale,
        ).parse(cleanedDate).millisecondsSinceEpoch.toString();
      } else {
        return DateFormat(
          dateFormat,
          dateFormatLocale,
        ).parse(date).millisecondsSinceEpoch.toString();
      }
    } catch (e) {
      final supportedLocales = DateFormat.allLocalesWithSymbols();

      for (var locale in supportedLocales) {
        for (var dateFormat in _dateFormats) {
          newLocale((dateFormat, locale, false));
          try {
            if (!_initializedLocales.contains(locale)) {
              initializeDateFormatting(locale);
              _initializedLocales.add(locale);
            }
            if (WordSet(["yesterday", "يوم واحد"]).startsWith(date)) {
              DateTime cal = DateTime.now().subtract(const Duration(days: 1));
              cal = DateTime(cal.year, cal.month, cal.day);
              return cal.millisecondsSinceEpoch.toString();
            } else if (WordSet(["today"]).startsWith(date)) {
              DateTime cal = DateTime.now();
              cal = DateTime(cal.year, cal.month, cal.day);
              return cal.millisecondsSinceEpoch.toString();
            } else if (WordSet(["يومين"]).startsWith(date)) {
              DateTime cal = DateTime.now().subtract(const Duration(days: 2));
              cal = DateTime(cal.year, cal.month, cal.day);
              return cal.millisecondsSinceEpoch.toString();
            } else if (WordSet([
              "ago",
              "atrás",
              "önce",
              "قبل",
            ]).endsWith(date)) {
              return parseRelativeDate(date).toString();
            } else if (WordSet(["hace"]).startsWith(date)) {
              return parseRelativeDate(date).toString();
            } else if (date.contains(RegExp(r"\d(st|nd|rd|th)"))) {
              final cleanedDate = date
                  .split(" ")
                  .map(
                    (it) => it.contains(RegExp(r"\d\D\D"))
                        ? it.replaceAll(RegExp(r"\D"), "")
                        : it,
                  )
                  .join(" ");
              return DateFormat(
                dateFormat,
                locale,
              ).parse(cleanedDate).millisecondsSinceEpoch.toString();
            } else {
              return DateFormat(
                dateFormat,
                locale,
              ).parse(date).millisecondsSinceEpoch.toString();
            }
          } catch (_) {}
        }
      }
      newLocale((dateFormat, dateFormatLocale, true));
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  static String deobfuscateJsPassword(String inputString) {
    return Deobfuscator.deobfuscateJsPassword(inputString);
  }

  static String encryptAESCryptoJS(String plainText, String passphrase) {
    return CryptoAES.encryptAESCryptoJS(plainText, passphrase);
  }

  static String decryptAESCryptoJS(String encrypted, String passphrase) {
    return CryptoAES.decryptAESCryptoJS(encrypted, passphrase);
  }

  static String cryptoHandler(
    String text,
    String iv,
    String secretKeyString,
    bool encrypt,
  ) {
    return CryptoAES.cryptoHandler(text, iv, secretKeyString, encrypt);
  }

  static MDocument parsHtml(String html) {
    return MDocument(html_dom.Document.html(html));
  }

  static List<String>? xpath(String html, String xpath) {
    List<String> attrs = [];
    try {
      final htmlXPath = HtmlXPath.html(html);
      final query = htmlXPath.query(xpath);
      if (query.nodes.length > 1) {
        for (var element in query.attrs) {
          attrs.add(element!.trim());
        }
      } else if (query.nodes.length == 1) {
        final attr = query.attr != null ? query.attr!.trim() : '';
        if (attr.isNotEmpty) attrs = [attr];
      }
      return attrs;
    } catch (_) {
      return [];
    }
  }

  static Status parseStatus(String status, List statusList) {
    for (var element in statusList) {
      Map statusMap = {};
      statusMap = element as Map;
      for (var entry in statusMap.entries) {
        if (entry.key.toString().toLowerCase().contains(
          status.toLowerCase().trim(),
        )) {
          return switch (entry.value as int) {
            0 => Status.ongoing,
            1 => Status.completed,
            2 => Status.onHiatus,
            3 => Status.canceled,
            4 => Status.publishingFinished,
            _ => Status.unknown,
          };
        }
      }
    }
    return Status.unknown;
  }

  static Future<List<Video>> gogoCdnExtractor(String url) =>
      GogoCdnExtractor().videosFromUrl(url);

  static Future<List<Video>> doodExtractor(String url, String? quality) =>
      DoodExtractor().videosFromUrl(url, quality: quality);

  static Future<List<Video>> streamWishExtractor(String url, String prefix) =>
      StreamWishExtractor().videosFromUrl(url, prefix);

  static Future<List<Video>> filemoonExtractor(
    String url,
    String prefix,
    String suffix,
  ) => FilemoonExtractor().videosFromUrl(url, prefix, suffix);

  static Future<List<Video>> mp4UploadExtractor(
    String url,
    String? headers,
    String prefix,
    String suffix,
  ) => Mp4uploadExtractor().videosFromUrl(
    url,
    decodeHeaders(headers),
    prefix: prefix,
    suffix: suffix,
  );

  static Future<List<Map<String, String>>> quarkFilesExtractor(
    List<String> urls,
    String cookie,
  ) async {
    final extractor = QuarkUcExtractor();
    await extractor.initCloudDrive(cookie, CloudDriveType.quark);
    return extractor.videoFilesFromUrl(urls);
  }

  static Future<List<Video>> quarkVideosExtractor(
    String url,
    String cookie,
  ) async {
    final extractor = QuarkUcExtractor();
    await extractor.initCloudDrive(cookie, CloudDriveType.quark);
    return extractor.videosFromUrl(url);
  }

  static Future<List<Map<String, String>>> ucFilesExtractor(
    List<String> urls,
    String cookie,
  ) async {
    final extractor = QuarkUcExtractor();
    await extractor.initCloudDrive(cookie, CloudDriveType.uc);
    return extractor.videoFilesFromUrl(urls);
  }

  static Future<List<Video>> ucVideosExtractor(
    String url,
    String cookie,
  ) async {
    final extractor = QuarkUcExtractor();
    await extractor.initCloudDrive(cookie, CloudDriveType.uc);
    return extractor.videosFromUrl(url);
  }

  static Future<List<Video>> streamTapeExtractor(String url, String? quality) =>
      StreamTapeExtractor().videosFromUrl(url, quality: quality);

  static Future<List<Video>> sibnetExtractor(String url, String prefix) =>
      SibnetExtractor().videosFromUrl(url, prefix: prefix);

  static Future<List<Video>> sendVidExtractor(
    String url,
    String? headers,
    String prefix,
  ) => SendvidExtractor(
    decodeHeaders(headers),
  ).videosFromUrl(url, prefix: prefix);

  static Future<List<Video>> myTvExtractor(String url) =>
      MytvExtractor().videosFromUrl(url);

  static Future<List<Video>> okruExtractor(String url) =>
      OkruExtractor().videosFromUrl(url);

  static Future<List<Video>> yourUploadExtractor(
    String url,
    String? headers,
    String? name,
    String prefix,
  ) => YourUploadExtractor().videosFromUrl(
    url,
    decodeHeaders(headers),
    name: name ?? 'YourUpload',
    prefix: prefix,
  );

  static Future<List<Video>> voeExtractor(String url, String? quality) =>
      VoeExtractor().videosFromUrl(url, quality);

  static Future<List<Video>> vidBomExtractor(String url) =>
      VidBomExtractor().videosFromUrl(url);

  static Future<List<Video>> streamlareExtractor(
    String url,
    String prefix,
    String suffix,
  ) => StreamlareExtractor().videosFromUrl(url, prefix: prefix, suffix: suffix);

  static Video toVideo(
    String url,
    String quality,
    String originalUrl,
    String? headers,
    List? subtitles,
    List? audios,
  ) {
    return Video(
      url,
      quality,
      originalUrl,
      headers: decodeHeaders(headers),
      subtitles: subtitles?.cast<Track>() ?? [],
      audios: audios?.cast<Track>() ?? [],
    );
  }
}

final List<String> _dateFormats = [
  'dd/MM/yyyy',
  'MM/dd/yyyy',
  'yyyy/MM/dd',
  'dd-MM-yyyy',
  'MM-dd-yyyy',
  'yyyy-MM-dd',
  'dd.MM.yyyy',
  'MM.dd.yyyy',
  'yyyy.MM.dd',
  'dd MMMM yyyy',
  'MMMM dd, yyyy',
  'yyyy MMMM dd',
  'dd MMM yyyy',
  'MMM dd yyyy',
  'yyyy MMM dd',
  'dd MMMM, yyyy',
  'yyyy, MMMM dd',
  'MMMM dd yyyy',
  'MMM dd, yyyy',
  'dd LLLL yyyy',
  'LLLL dd, yyyy',
  'yyyy LLLL dd',
  'LLLL dd yyyy',
  "MMMMM dd, yyyy",
  "MMM d, yyy",
  "MMM d, yyyy",
  "dd/mm/yyyy",
  "d MMMM yyyy",
  "dd 'de' MMMM 'de' yyyy",
  "d MMMM'،' yyyy",
  "yyyy'年'M'月'd",
  "d MMMM, yyyy",
  "dd 'de' MMMMM 'de' yyyy",
  "dd MMMMM, yyyy",
  "MMMM d, yyyy",
  "MMM dd,yyyy",
];

class Deobfuscator {
  static String deobfuscateJsPassword(String inputString) {
    int idx = 0;
    final brackets = ['[', '('];
    final evaluatedString = StringBuffer();

    while (idx < inputString.length) {
      final chr = inputString[idx];

      if (!brackets.contains(chr)) {
        idx++;
        continue;
      }

      final closingIndex = getMatchingBracketIndex(idx, inputString);

      if (chr == '[') {
        final digit = calculateDigit(inputString.substring(idx, closingIndex));
        evaluatedString.write(digit);
      } else {
        evaluatedString.write('.');

        if (inputString[closingIndex + 1] == '[') {
          final skippingIndex = getMatchingBracketIndex(
            closingIndex + 1,
            inputString,
          );
          idx = skippingIndex + 1;
          continue;
        }
      }

      idx = closingIndex + 1;
    }

    return evaluatedString.toString();
  }

  static int getMatchingBracketIndex(int openingIndex, String inputString) {
    final openingBracket = inputString[openingIndex];
    final closingBracket = openingBracket == '[' ? ']' : ')';
    var counter = 0;

    for (var idx = openingIndex; idx < inputString.length; idx++) {
      if (inputString[idx] == openingBracket) counter++;
      if (inputString[idx] == closingBracket) counter--;

      if (counter == 0) return idx;
      if (counter < 0) return -1;
    }

    return -1;
  }

  static String calculateDigit(String inputSubString) {
    final digit = RegExp(r"\!\+\[\]").allMatches(inputSubString).length;

    if (digit == 0) {
      if (RegExp(r"\+\[\]").allMatches(inputSubString).length == 1) {
        return '0';
      }
    } else if (digit >= 1 && digit <= 9) {
      return digit.toString();
    }

    return '-';
  }
}

class JsUnpacker {
  static final RegExp _packedRegex = RegExp(
    r"eval[(]function[(]p,a,c,k,e,[r|d]?",
    caseSensitive: false,
    multiLine: true,
  );

  static final RegExp _packedExtractRegex = RegExp(
    r"[}][(]'(.*)', *(\d+), *(\d+), *'(.*?)'[.]split[(]'[|]'[)]",
    caseSensitive: false,
    multiLine: true,
  );

  static final RegExp _unpackReplaceRegex = RegExp(
    r"\b\w+\b",
    caseSensitive: false,
    multiLine: true,
  );

  static bool detect(String scriptBlock) {
    return _packedRegex.hasMatch(scriptBlock);
  }

  static List<String> unpack(String scriptBlock) {
    return detect(scriptBlock) ? _unpacking(scriptBlock).toList() : <String>[];
  }

  static String? unpackAndCombine(String scriptBlock) {
    final unpacked = unpack(scriptBlock);
    return unpacked.isEmpty ? null : unpacked.join(' ');
  }

  static Iterable<String> _unpacking(String scriptBlock) sync* {
    final matches = _packedExtractRegex.allMatches(scriptBlock);
    for (final match in matches) {
      final payload = match.group(1);
      final symtab = match.group(4)?.split('|');
      final radix = int.tryParse(match.group(2)!) ?? 10;
      final count = int.tryParse(match.group(3)!) ?? 0;
      final unbaser = Unbaser(radix);

      if (symtab != null && symtab.length == count) {
        final unpackedPayload = payload!.replaceAllMapped(_unpackReplaceRegex, (
          match,
        ) {
          final word = match.group(0)!;
          final unbased = symtab[unbaser.unbase(word)];
          return unbased.isEmpty ? word : unbased;
        });
        yield unpackedPayload;
      }
    }
  }
}

class Unbaser {
  final int base;
  static const Map<int, String> _alphabet = {
    52: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOP",
    54: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQR",
    62: "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
    95: " !\"#\$%&\\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~",
  };

  Unbaser(this.base);

  int unbase(String value) {
    if (base >= 2 && base <= 36) {
      return int.tryParse(value, radix: base) ?? 0;
    } else {
      final dict = _alphabet[base]
          ?.split('')
          .asMap()
          .map((index, c) => MapEntry(c, index));
      var returnVal = 0;

      final valArray = value.runes.toList().reversed.toList();
      for (var i = 0; i < valArray.length; i++) {
        final cipher = String.fromCharCode(valArray[i]);
        returnVal += pow(base, i).toInt() * (dict?[cipher] ?? 0).toInt();
      }
      return returnVal;
    }
  }
}
