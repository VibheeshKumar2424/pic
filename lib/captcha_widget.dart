import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CaptchaWidget extends StatefulWidget {
  final Function(String) onCaptchaCompleted;

  CaptchaWidget({required this.onCaptchaCompleted});

  @override
  _CaptchaWidgetState createState() => _CaptchaWidgetState();
}

class _CaptchaWidgetState extends State<CaptchaWidget> {
  late WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: WebView(
        initialUrl:
            'https://www.google.com/recaptcha/api2/anchor?ar=1&k=your_site_key', // Replace with your site key
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller = webViewController;
        },
        onPageFinished: (String url) async {
          if (url.contains('/recaptcha/api2/userverify')) {
            String? captchaResponse =
                await _controller.runJavascriptReturningResult(
                    "document.getElementById('g-recaptcha-response').value");
            if (captchaResponse != null && captchaResponse.isNotEmpty) {
              widget.onCaptchaCompleted(captchaResponse);
            }
          }
        },
      ),
    );
  }
}
