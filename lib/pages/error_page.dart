import 'package:flutter/cupertino.dart';

class Error extends StatelessWidget {
  final VoidCallback reload;
  const Error({super.key, required this.reload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.exclamationmark_triangle, size: 60),
          Text(
            "\nFailed to Load\nYour Internet might not be working\n",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(
            width: 120,
            height: 50,
            child: CupertinoButton.filled(
              onPressed: reload,
              padding: EdgeInsets.zero,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.refresh, color: CupertinoColors.white),
                  Text("  Reload")
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorPage extends StatelessWidget {
  final VoidCallback onReload;
  final bool scaffold;

  const ErrorPage({super.key, required this.onReload, required this.scaffold});
  @override
  Widget build(BuildContext context) {
    return scaffold
        ? CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(),
            child: Error(reload: onReload),
          )
        : Error(reload: onReload);
  }
}
