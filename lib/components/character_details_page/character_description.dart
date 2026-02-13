import 'package:flutter/cupertino.dart';

String _stripMarkdown(String s) {
  var out = s.replaceAll(RegExp(r'__|\*\*|`'), '');
  out = out.replaceAll(RegExp(r'~!|!~'), '');
  out = out.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\((.*?)\)', dotAll: true),
    (m) => m.group(1) ?? '',
  );

  return out;
}

class CharacterDescription extends StatelessWidget {
  const CharacterDescription({
    super.key,
    required this.characterGender,
    required this.characterDescription,
  });

  final String characterGender;
  final String characterDescription;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Gender: ",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              Text(characterGender, style: TextStyle(fontSize: 17)),
            ],
          ),
          SizedBox(height: 5),
          Text(
            _stripMarkdown(characterDescription),
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
