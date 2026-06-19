import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zenbu/authentication_token_controller.dart';

const String _anilistApiUrl = 'https://graphql.anilist.co';

Future<Map<String, dynamic>> executeQuery(
  String query, {
  Map<String, dynamic>? variables,
  bool requireAuth = true,
}) async {
  try {
    Map<String, String> headers = {"Content-Type": "application/json"};

    if (requireAuth) {
      String? token = await TokenStorage.getAccessToken();
      if (token == null) throw 'No authentication token';
      headers["Authorization"] = 'Bearer $token';
    }

    final res = await http.post(
      Uri.parse(_anilistApiUrl),
      headers: headers,
      body: jsonEncode({"query": query, "variables": variables}),
    );

    if (res.statusCode == 429) {
      Fluttertoast.showToast(
        msg: "Rate limited, try again later",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 16.0,
      );
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data;
  } catch (e) {
    throw e.toString();
  }
}

const List<String> _seasonArray = ["WINTER", "SPRING", "SUMMER", "FALL"];

const Map<int, String> seasonMapping = {
  1: "WINTER",
  2: "WINTER",
  3: "WINTER",
  4: "SPRING",
  5: "SPRING",
  6: "SPRING",
  7: "SUMMER",
  8: "SUMMER",
  9: "SUMMER",
  10: "FALL",
  11: "FALL",
  12: "FALL",
};

String getNextSeason(String currentSeason) {
  int index = _seasonArray.indexOf(currentSeason);
  return _seasonArray[(index != -1 && index != 3) ? index + 1 : 0];
}
