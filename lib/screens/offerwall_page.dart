import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';

class OfferwallPage extends StatefulWidget {
  final String title;
  final String offerType;

  const OfferwallPage({
    Key? key,
    required this.title,
    required this.offerType,
  }) : super(key: key);

  @override
  State<OfferwallPage> createState() => _OfferwallPageState();
}

class _OfferwallPageState extends State<OfferwallPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';

    String targetUrl = 'https://www.google.com';

    if (widget.offerType == 'surveys') {
      targetUrl = 'https://web.bitlabs.ai/?uid=$userId';
    } else if (widget.offerType == 'games' || widget.offerType == 'apps') {
      targetUrl = 'https://www.cpagrip.com/show.php?l=0&u=$userId';
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(targetUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
