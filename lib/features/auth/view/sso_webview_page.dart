import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class SsoWebViewPage extends StatefulWidget {
  final Function(String u, String p, String n, String nim) onLoginSuccess;
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

              // 1. Intersepsi Login (Support Click & Enter/Submit)
              if (currentUrl.contains("sso.poliwangi.ac.id/login")) {
                await controller.evaluateJavascript(
                  source: """
                  // Tangkap event saat form disubmit (misal via Enter)
                  var form = document.querySelector('form');
                  if(form) {
                    form.addEventListener('submit', function() {
                      var u = document.querySelector('input[name="username"]').value;
                      var p = document.querySelector('input[name="password"]').value;
                      window.flutter_inappwebview.callHandler('saveLogin', u, p);
                    });
                  }

                  // Tangkap klik tombol manual (backup)
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

              // 2. Deteksi Dashboard (MHS/Dosen)
              // Menambahkan 'dosen/profile/edit' sebagai tanda login berhasil untuk dosen
              if (currentUrl.contains("mahasiswa/dashboard") ||
                  currentUrl.contains("dosen/dashboard") ||
                  currentUrl.contains("dosen/profile/edit")) {
                setState(() => _isScraping = true);
                _startScrapingTask(controller);
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
                    Text(
                      _retryCount > 0
                          ? "Mencoba mengambil data... ($_retryCount)"
                          : "Sedang menyinkronkan identitas...",
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _startScrapingTask(InAppWebViewController controller) async {
    // Logic Scraping yang lebih pintar: Cari berdasarkan Label "Nama" / "NIM" / "NIP"
    var result = await controller.evaluateJavascript(
      source: """
      (function() {
        var data = {};
        
        // Coba selector dashboard mahasiswa & dosen
        // Mencari elemen dengan class .data-title (Label) dan .data-value (Isi)
        // Biasanya ada di dalam container .data
        
        // Ambil semua container baris data (biasanya d-flex)
        var rows = document.querySelectorAll('.data .d-flex');
        
        if(rows.length > 0) {
           rows.forEach(function(row) {
              var titleEl = row.querySelector('.data-title');
              var valueEl = row.querySelector('.data-value');
              
              if (titleEl && valueEl) {
                var rawKey = titleEl.innerText || "";
                var val = valueEl.innerText || "";
                
                // Bersihkan titik dua dan spasi
                var key = rawKey.replace(':', '').trim();
                val = val.trim();
                
                // Mapping Key
                if (key === 'NIM' || key === 'NIP' || key === 'NIDN') {
                  data.id_val = val;
                } else if (key === 'Nama') {
                  data.nama = val;
                }
              }
           });
        }
        
        // Fallback scan manual jika struktur .d-flex berubah tapi class .data-value masih ada
        // Ini kurang akurat tapi bisa jadi backup
        if (!data.id_val || !data.nama) {
           var d = document.querySelectorAll('.data-value');
           if(d.length >= 2 && !data.id_val) {
             // Asumsi index 0 = NIM/ID, index 1 = Nama (Logic lama)
             // Hanya pakai ini jika logic label di atas gagal total
             return { "id_val": d[0].innerText.trim(), "nama": d[1].innerText.trim() };
           }
        }

        if (data.id_val && data.nama) {
          return data;
        }
        
        return null;
      })()
    """,
    );

    if (result != null) {
      widget.onLoginSuccess(
        savedUser ?? result['id_val'],
        savedPass ?? "",
        result['nama'],
        result['id_val'],
      );
    } else {
      if (_retryCount < 10) {
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() => _retryCount++);
          _startScrapingTask(controller);
        }
      } else {
        if (mounted) setState(() => _isScraping = false);
      }
    }
  }
}
