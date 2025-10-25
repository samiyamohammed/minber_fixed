// lib/widgets/embedded_web_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EmbeddedWebScreen extends StatefulWidget {
  final String url;
  final String appName;

  const EmbeddedWebScreen(
      {super.key, required this.url, required this.appName});

  @override
  State<EmbeddedWebScreen> createState() => _EmbeddedWebScreenState();
}

class _EmbeddedWebScreenState extends State<EmbeddedWebScreen> {
  late final WebViewController _controller;
  double _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100.0;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appName),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: _loadingProgress > 0 && _loadingProgress < 1
              ? LinearProgressIndicator(value: _loadingProgress)
              : const SizedBox.shrink(),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
