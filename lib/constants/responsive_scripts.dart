class ResponsiveScripts {
  /// Responsive CSS to force 1-column single pane layout on smartphone screens
  static const String mobileCss = '''
    /* WhatsGo Responsive Mobile Styles */
    body.whatsgo-mobile-mode #app > div {
      min-width: 100% !important;
      width: 100% !important;
    }

    body.whatsgo-mobile-mode #side {
      width: 100% !important;
      max-width: 100% !important;
      min-width: 100% !important;
      flex: 1 1 100% !important;
      height: 100% !important;
    }

    body.whatsgo-mobile-mode #main {
      width: 100% !important;
      max-width: 100% !important;
      min-width: 100% !important;
      flex: 1 1 100% !important;
      height: 100% !important;
      left: 0 !important;
    }

    /* In chat state: hide side chat list, show active conversation */
    body.whatsgo-mobile-mode.whatsgo-in-chat #side {
      display: none !important;
    }
    body.whatsgo-mobile-mode.whatsgo-in-chat #main {
      display: flex !important;
    }

    /* In list state: show chat list, hide conversation pane */
    body.whatsgo-mobile-mode.whatsgo-in-list #main {
      display: none !important;
    }
    body.whatsgo-mobile-mode.whatsgo-in-list #side {
      display: flex !important;
    }

    /* Custom Virtual Back Button in #main header */
    .whatsgo-back-btn {
      display: inline-flex !important;
      align-items: center !important;
      justify-content: center !important;
      width: 40px !important;
      height: 40px !important;
      margin-right: 6px !important;
      margin-left: 2px !important;
      cursor: pointer !important;
      border-radius: 50% !important;
      color: #54656f !important;
      user-select: none !important;
      -webkit-tap-highlight-color: transparent !important;
      flex-shrink: 0 !important;
    }

    .whatsgo-back-btn:active {
      background-color: rgba(0, 0, 0, 0.1) !important;
    }

    body.dark .whatsgo-back-btn {
      color: #aebac1 !important;
    }

    body.dark .whatsgo-back-btn:active {
      background-color: rgba(255, 255, 255, 0.15) !important;
    }

    /* Hide unnecessary desktop download promotional banners if any */
    [data-testid="banner-download-desktop-app"] {
      display: none !important;
    }
  ''';

  /// JavaScript to observe DOM changes, toggle CSS classes, and bridge chat state to Flutter
  static const String mobileJs = '''
    (function() {
      if (window.__whatsgo_responsive_initialized) {
        document.body.classList.add('whatsgo-mobile-mode');
        if (window.__whatsgo_update_state) window.__whatsgo_update_state();
        return;
      }
      window.__whatsgo_responsive_initialized = true;

      document.body.classList.add('whatsgo-mobile-mode');

      var lastInChat = null;

      function updateChatState() {
        if (!document.body.classList.contains('whatsgo-mobile-mode')) {
          return;
        }

        var main = document.querySelector('#main');
        var inChat = !!main;

        if (inChat) {
          document.body.classList.add('whatsgo-in-chat');
          document.body.classList.remove('whatsgo-in-list');
          injectBackButton(main);
        } else {
          document.body.classList.remove('whatsgo-in-chat');
          document.body.classList.add('whatsgo-in-list');
        }

        if (lastInChat !== inChat) {
          lastInChat = inChat;
          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            window.flutter_inappwebview.callHandler('onChatStateChanged', inChat);
          }
        }
      }
      window.__whatsgo_update_state = updateChatState;

      function injectBackButton(mainElem) {
        if (!mainElem) return;
        var header = mainElem.querySelector('header');
        if (!header) return;

        if (header.querySelector('.whatsgo-back-btn')) return;

        var btn = document.createElement('div');
        btn.className = 'whatsgo-back-btn';
        btn.setAttribute('role', 'button');
        btn.setAttribute('aria-label', 'Kembali ke daftar pesan');
        btn.innerHTML = '<svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor"><path d="M20 11H7.83l5.59-5.59L12 4l-8 8 8 8 1.41-1.41L7.83 13H20v-2z"></path></svg>';
        btn.addEventListener('click', function(e) {
          e.stopPropagation();
          e.preventDefault();
          window.whatsGoCloseChat();
        });

        if (header.firstChild) {
          header.insertBefore(btn, header.firstChild);
        } else {
          header.appendChild(btn);
        }
      }

      window.whatsGoCloseChat = function() {
        // Dispatch Escape key to simulate pressing ESC on desktop
        var escEvent = new KeyboardEvent('keydown', {
          bubbles: true,
          cancelable: true,
          key: 'Escape',
          code: 'Escape',
          keyCode: 27,
          which: 27
        });
        document.dispatchEvent(escEvent);
        document.body.dispatchEvent(escEvent);

        setTimeout(function() {
          updateChatState();
        }, 120);
      };

      var observer = new MutationObserver(function(mutations) {
        updateChatState();
      });

      observer.observe(document.body, { childList: true, subtree: true });
      updateChatState();
    })();
  ''';

  /// Script to disable responsive mode (for Desktop Mode)
  static const String disableMobileScript = '''
    (function() {
      document.body.classList.remove('whatsgo-mobile-mode');
      document.body.classList.remove('whatsgo-in-chat');
      document.body.classList.remove('whatsgo-in-list');
      var backBtns = document.querySelectorAll('.whatsgo-back-btn');
      backBtns.forEach(function(b) { b.remove(); });
    })();
  ''';
}

