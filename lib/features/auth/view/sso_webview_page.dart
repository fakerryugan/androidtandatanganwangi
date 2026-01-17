import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class SsoWebViewPage extends StatefulWidget {
  final Function(String u, String p, String n, String nim, String cookies) onLoginSuccess;
  const SsoWebViewPage({super.key, required this.onLoginSuccess});

  @override
  State<SsoWebViewPage> createState() => _SsoWebViewPageState();
}

class _SsoWebViewPageState extends State<SsoWebViewPage> {
  InAppWebViewController? webViewController;
  String? savedUser, savedPass;
  bool _isScraping = false;
  int _retryCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isScraping ? "Sinkronisasi..." : "Login SSO Poliwangi"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialSettings: InAppWebViewSettings(
              // User Agent Desktop agar tampilan dashboard lengkap/standar
              userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
              cacheEnabled: true,
              javaScriptEnabled: true,
              domStorageEnabled: true,
            ),
            initialUrlRequest: URLRequest(
              url: WebUri("https://sit.poliwangi.ac.id/"),
            ),
            onReceivedServerTrustAuthRequest: (controller, challenge) async {
              return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.PROCEED,
              );
            },
            onLoadStop: (controller, url) async {
              String currentUrl = url.toString();
              
              // 1. Intersepsi Login (Tangkap Username/Pass saat user mengetik)
              if (currentUrl.contains("sso.poliwangi.ac.id/login")) {
                await controller.evaluateJavascript(
                  source: """
                  var form = document.querySelector('form');
                  if(form) {
                    form.addEventListener('submit', function() {
                      var u = document.querySelector('input[name="username"]').value;
                      var p = document.querySelector('input[name="password"]').value;
                      window.flutter_inappwebview.callHandler('saveLogin', u, p);
                    });
                  }
                  document.addEventListener('click', function(e) {
                    if(e.target.type == 'submit' || e.target.id == 'btn-login' || e.target.innerText.includes('Login')) {
                      var u = document.querySelector('input[name="username"]').value;
                      var p = document.querySelector('input[name="password"]').value;
                      window.flutter_inappwebview.callHandler('saveLogin', u, p);
                    }
                  });
                """,
                );
              }

              // 2. Deteksi Dashboard -> Mulai Scraping
              // URL indikator dashboard user
              if (currentUrl.contains("mahasiswa/dashboard") ||
                  currentUrl.contains("dosen/dashboard") ||
                  currentUrl.contains("dosen/profile/edit")) {
                if (!_isScraping) {
                   setState(() {
                     _isScraping = true;
                     _retryCount = 0; 
                   });
                   _startScrapingTask(controller);
                }
              }
            },
            onWebViewCreated: (controller) {
              webViewController = controller;
              controller.addJavaScriptHandler(
                handlerName: 'saveLogin',
                callback: (args) {
                  savedUser = args[0];
                  savedPass = args[1];
                },
              );
            },
          ),
          if (_isScraping)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.blueAccent),
                    const SizedBox(height: 25),
                    const Text(
                      "Login Berhasil!",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text("Sedang mengambil data identitas... ($_retryCount)"),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => setState(() => _isScraping = false),
                      child: const Text("Batalkan"),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _startScrapingTask(InAppWebViewController controller) async {
    // REGEX SCRAPING: Ambil seluruh teks halaman body
    var bodyText = await controller.evaluateJavascript(source: "document.body.innerText");
    
    if (bodyText != null && bodyText is String) {
       // Regex cari NIM/NIP dan Nama
       RegExp nimRegex = RegExp(r"(?:NIM|NIP|NIDN)\s*[:]\s*(\d+)", caseSensitive: false);
       RegExp namaRegex = RegExp(r"Nama\s*[:]\s*([^\n\r]+)", caseSensitive: false);
       
       String? nimFound = nimRegex.firstMatch(bodyText)?.group(1)?.trim();
       String? namaFound = namaRegex.firstMatch(bodyText)?.group(1)?.trim();
       
       if (nimFound != null && namaFound != null) {
          print("SCRAPED DATA: $nimFound - $namaFound");
          
          if (mounted) {
            // Strategi Shared Token: Tidak butuh Cookie!
            // Kita percaya penuh bahwa jika webview sampai sini, user valid.
            // Kirim data ke repository, nanti repo menyisipkan 'app_token' rahasia.
            widget.onLoginSuccess(
              savedUser ?? nimFound, 
              savedPass ?? "",       
              namaFound,
              nimFound,
              "", // Cookie string kosong, tidak dipakai backend shared token
            );
          }
          return; 
       }
    }

    // Retry Logic
    if (_retryCount < 8) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _retryCount++);
        _startScrapingTask(controller);
      }
    } else {
      // Timeout
      if (mounted) {
          setState(() => _isScraping = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Gagal membaca data identitas. Coba reload."),
              action: SnackBarAction(label: "Reload", onPressed: () => controller.reload()),
              backgroundColor: Colors.red,
            ),
          );
      }
    }
  }
}
