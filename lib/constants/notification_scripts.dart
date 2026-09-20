class NotificationScripts {
  /// Injected JavaScript to override window.Notification and forward message alerts to Flutter
  static const String notificationInterceptionScript = '''
    (function() {
      if (window.__whatsgo_notification_bridge_installed) return;
      window.__whatsgo_notification_bridge_installed = true;

      function CustomNotification(title, options) {
        options = options || {};
        var body = options.body || '';
        var icon = options.icon || '';
        var tag = options.tag || '';

        // Forward to Flutter native notification channel
        try {
          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            window.flutter_inappwebview.callHandler('onIncomingWebNotification', {
              title: title,
              body: body,
              icon: icon,
              tag: tag
            });
          }
        } catch (e) {
          console.error('WhatsGo: Error forwarding notification to Flutter', e);
        }

        this.title = title;
        this.body = body;
        this.icon = icon;
        this.tag = tag;
        this.onclick = null;
        this.onclose = null;
        this.onerror = null;
        this.onshow = null;

        this.close = function() {
          if (this.onclose) this.onclose();
        };

        this.addEventListener = function(type, listener) {
          if (type === 'click') this.onclick = listener;
          if (type === 'close') this.onclose = listener;
        };

        this.removeEventListener = function() {};
        this.dispatchEvent = function() { return true; };
      }

      // Automatically mock permission as granted
      CustomNotification.permission = 'granted';
      CustomNotification.maxActions = 2;
      CustomNotification.requestPermission = function(callback) {
        var perm = 'granted';
        if (typeof callback === 'function') {
          callback(perm);
        }
        return Promise.resolve(perm);
      };

      try {
        Object.defineProperty(window, 'Notification', {
          value: CustomNotification,
          writable: true,
          configurable: true
        });
      } catch (e) {
        window.Notification = CustomNotification;
      }

      console.log('WhatsGo: Web Notification Bridge successfully installed.');
    })();
  ''';
}
