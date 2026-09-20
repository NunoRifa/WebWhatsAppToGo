class DownloadScripts {
  /// Injected JavaScript to intercept blob: and standard download anchor clicks in WhatsApp Web
  static const String blobInterceptorScript = '''
    (function() {
      if (window.__whatsgo_download_interceptor_installed) return;
      window.__whatsgo_download_interceptor_installed = true;

      var originalClick = HTMLAnchorElement.prototype.click;

      HTMLAnchorElement.prototype.click = function() {
        var href = this.href || '';
        var downloadAttr = this.getAttribute('download') || this.download || '';

        // If it is a blob URL (standard for WhatsApp Web encrypted media downloads)
        if (href.indexOf('blob:') === 0) {
          var filename = downloadAttr || ('whatsgo_media_' + Date.now());

          fetch(href)
            .then(function(response) {
              return response.blob();
            })
            .then(function(blob) {
              var reader = new FileReader();
              reader.onloadend = function() {
                var result = reader.result || '';
                var base64Data = '';
                if (result.indexOf(',') !== -1) {
                  base64Data = result.split(',')[1];
                }

                if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                  window.flutter_inappwebview.callHandler('onBlobDownloadRequest', {
                    filename: filename,
                    mimeType: blob.type || 'application/octet-stream',
                    base64Data: base64Data
                  });
                }
              };
              reader.readAsDataURL(blob);
            })
            .catch(function(err) {
              console.error('WhatsGo: Error intercepting blob download:', err);
              // Fallback to original click
              originalClick.apply(this);
            });

          return;
        }

        // Standard click for other URLs
        originalClick.apply(this);
      };

      console.log('WhatsGo: Blob Download Interceptor successfully installed.');
    })();
  ''';
}
