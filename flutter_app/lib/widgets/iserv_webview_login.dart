import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class IServWebViewLogin extends StatefulWidget {
  final String iservUrl;
  final Function(List<Cookie> cookies, String username) onLoginSuccess;
  final VoidCallback onCancel;

  const IServWebViewLogin({
    super.key,
    required this.iservUrl,
    required this.onLoginSuccess,
    required this.onCancel,
  });

  @override
  State<IServWebViewLogin> createState() => _IServWebViewLoginState();
}

class _IServWebViewLoginState extends State<IServWebViewLogin> {
  InAppWebViewController? _webViewController;
  final CookieManager _cookieManager = CookieManager.instance();
  bool _isLoading = true;
  double _progress = 0;

  String get _normalizedUrl {
    String url = widget.iservUrl
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/+$'), '');
    return 'https://$url';
  }

  @override
  void initState() {
    super.initState();
    _clearCookies();
  }

  Future<void> _clearCookies() async {
    await _cookieManager.deleteAllCookies();
  }

  Future<void> _checkLoginSuccess(String url) async {
    final isLoginPage = url.contains('/login') ||
                        url.contains('login_check') ||
                        url.contains('/auth/');

    final isDashboard = url.contains('/iserv/') && !isLoginPage;

    if (isDashboard && _webViewController != null) {
      final html = await _webViewController!.evaluateJavascript(
        source: 'document.documentElement.outerHTML'
      );

      final htmlStr = html?.toString() ?? '';

      final isLoggedIn = htmlStr.contains('Abmelden') ||
                         htmlStr.contains('logout') ||
                         htmlStr.contains('iserv-nav') ||
                         htmlStr.contains('iserv-menu') ||
                         htmlStr.contains('IServ-Dashboard') ||
                         htmlStr.contains('Mein IServ');

      if (isLoggedIn) {
        await _extractCookiesAndComplete();
      }
    }
  }

  Future<void> _extractCookiesAndComplete() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final List<Cookie> allCookies = [];

      final urlWithoutProtocol = _normalizedUrl.replaceAll('https://', '');
      final domain = urlWithoutProtocol.split('/').first;

      final pathsToTry = [
        _normalizedUrl,
        '$_normalizedUrl/',
        '$_normalizedUrl/iserv/',
        '$_normalizedUrl/iserv/login',
        '$_normalizedUrl/iserv/app',
        'https://$domain',
        'https://$domain/',
        'https://$domain/iserv/',
      ];

      for (final path in pathsToTry) {
        try {
          final uri = WebUri(path);
          final cookies = await _cookieManager.getCookies(url: uri);
          for (final cookie in cookies) {
            if (!allCookies.any((c) => c.name == cookie.name)) {
              allCookies.add(cookie);
            }
          }
        } catch (e) {
          if (kDebugMode) print('IServ WebView: Failed to get cookies from $path: $e');
        }
      }

      try {
        final domainCookies = await _cookieManager.getCookies(url: WebUri('https://$domain'));
        for (final cookie in domainCookies) {
          if (!allCookies.any((c) => c.name == cookie.name)) {
            allCookies.add(cookie);
          }
        }
      } catch (e) {
        if (kDebugMode) print('IServ WebView: Failed to get cookies for domain $domain: $e');
      }

      if (_webViewController != null) {
        try {
          final jsCookies = await _webViewController!.evaluateJavascript(
            source: 'document.cookie'
          );
          if (jsCookies != null && jsCookies.toString().isNotEmpty) {
            final cookieStr = jsCookies.toString();
            final pairs = cookieStr.split(';');
            for (final pair in pairs) {
              final parts = pair.trim().split('=');
              if (parts.length >= 2) {
                final name = parts[0].trim();
                final value = parts.sublist(1).join('=').trim();
                if (name.isNotEmpty && !allCookies.any((c) => c.name == name)) {
                  allCookies.add(Cookie(name: name, value: value));
                }
              }
            }
          }
        } catch (e) {
          if (kDebugMode) print('IServ WebView: Failed to get cookies via JavaScript: $e');
        }
      }

      if (kDebugMode) print('IServ WebView: Extracted ${allCookies.length} cookies');
      for (final c in allCookies) {
        if (kDebugMode) print('  Cookie: ${c.name}');
      }

      String username = '';
      if (_webViewController != null) {
        final result = await _webViewController!.evaluateJavascript(
          source: '''
            (function() {
              var username = '';

              var userElement = document.querySelector('.iserv-user-name, .user-name, [data-username], .nav-username, .username');
              if (userElement) {
                username = userElement.textContent || userElement.getAttribute('data-username') || '';
              }

              if (!username) {
                var match = document.body.innerHTML.match(/Angemeldet als[:\\s]+([^<]+)/i);
                if (match) username = match[1];
              }

              if (!username) {
                var iservUser = document.querySelector('[data-user], .iserv-header-user, #iserv-user');
                if (iservUser) {
                  username = iservUser.textContent || iservUser.getAttribute('data-user') || '';
                }
              }

              return username.trim();
            })()
          '''
        );
        username = result?.toString() ?? '';
      }

      if (kDebugMode) print('IServ WebView: Login complete with ${allCookies.length} cookies, username: $username');

      if (_webViewController != null) {
        try {
          await InAppWebViewController.clearAllCache();
          await WebStorageManager.instance().deleteAllData();
        } catch (_) {}
      }

      widget.onLoginSuccess(allCookies, username);
    } catch (e) {
      if (kDebugMode) print('IServ WebView: Cookie extraction failed: $e - proceeding with empty cookies');
      widget.onLoginSuccess([], '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IServ Anmeldung'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
        actions: [
          if (_webViewController != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _webViewController?.reload(),
            ),
        ],
        bottom: _isLoading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(value: _progress),
              )
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri('$_normalizedUrl/iserv/login'),
                ),
                initialSettings: InAppWebViewSettings(
                  useShouldOverrideUrlLoading: true,
                  mediaPlaybackRequiresUserGesture: false,
                  javaScriptEnabled: true,
                  domStorageEnabled: false,
                  databaseEnabled: false,
                  clearCache: true,
                  cacheEnabled: false,
                  supportZoom: false,
                  builtInZoomControls: false,
                  displayZoomControls: false,
                  userAgent: 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    _isLoading = true;
                  });
                },
                onLoadStop: (controller, url) async {
                  setState(() {
                    _isLoading = false;
                  });

                  if (url != null) {
                    await _checkLoginSuccess(url.toString());
                  }
                },
                onProgressChanged: (controller, progress) {
                  setState(() {
                    _progress = progress / 100;
                  });
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url?.toString() ?? '';
                  final scheme = navigationAction.request.url?.scheme ?? '';

                  if (scheme == 'javascript' || scheme == 'data' || scheme == 'blob') {
                    return NavigationActionPolicy.CANCEL;
                  }

                  final iservDomain = widget.iservUrl.replaceAll(RegExp(r'^https?://'), '').split('/').first;
                  if (url.contains(iservDomain)) {
                    return NavigationActionPolicy.ALLOW;
                  }

                  return NavigationActionPolicy.CANCEL;
                },
              ),
                if (_isLoading && _progress < 0.1)
                  Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Lade IServ...'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
