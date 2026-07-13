import 'package:flutter/material.dart';

class Error extends StatelessWidget {
  final VoidCallback reload;
  final String? message;
  const Error({super.key, required this.reload, this.message});

  @override
  Widget build(BuildContext context) {
    String displayMessage = "Your Internet might not be working";
    if (message != null && message!.trim().isNotEmpty) {
      displayMessage = message!.replaceFirst(
        RegExp(
          r'^(Exception|HttpException|SocketException|ClientException):\s*',
        ),
        '',
      );
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Text(
              "Failed to Load\n\n$displayMessage",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 120,
            height: 50,
            child: FilledButton(
              onPressed: reload,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [Icon(Icons.refresh), Text("  Reload")],
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
  final String? message;

  const ErrorPage({
    super.key,
    required this.onReload,
    required this.scaffold,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return scaffold
        ? Scaffold(
            appBar: AppBar(),
            body: Error(reload: onReload, message: message),
          )
        : Error(reload: onReload, message: message);
  }
}
