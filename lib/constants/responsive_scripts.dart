class ResponsiveScripts {
  /// Inject mobile viewport meta tag at document start to force
  /// WhatsApp Web to render at the device's actual width (~360-420dp)
  /// instead of the default desktop width (~980px).
  static const String viewportInjectionScript = '''
    (function() {
      if (window.__whatsgo_viewport_injected) return;
      window.__whatsgo_viewport_injected = true;

      // Remove any existing viewport meta tags
      var existing = document.querySelectorAll('meta[name="viewport"]');
      existing.forEach(function(el) { el.remove(); });

      // Create and inject mobile viewport
      var meta = document.createElement('meta');
      meta.name = 'viewport';
      meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
      // Inject as early as possible
      if (document.head) {
        document.head.insertBefore(meta, document.head.firstChild);
      } else {
        // Document not ready yet, wait for it
        var observer = new MutationObserver(function(mutations, obs) {
          if (document.head) {
            document.head.insertBefore(meta, document.head.firstChild);
            obs.disconnect();
          }
        });
        observer.observe(document.documentElement || document, { childList: true, subtree: true });
      }
    })();
  ''';

  /// Comprehensive responsive CSS for mobile-first WhatsApp Web experience.
  /// Handles: login/QR page, chat list, room chat, secondary panels,
  /// emoji picker, media viewer, and all modal dialogs.
  static const String mobileCss = '''
    /* ============================================================
       WhatsGo Mobile-First Responsive Styles v2.0
       Target: Android screens 320-420dp width
       ============================================================ */

    /* --- 1. GLOBAL CONTAINER RESETS --- */
    body.whatsgo-mobile-mode,
    body.whatsgo-mobile-mode #app,
    body.whatsgo-mobile-mode #app > div,
    body.whatsgo-mobile-mode #app > div > div {
      width: 100vw !important;
      min-width: 0 !important;
      max-width: 100vw !important;
      overflow-x: hidden !important;
    }

    body.whatsgo-mobile-mode #app > div > div {
      display: flex !important;
      flex-direction: row !important;
      height: 100vh !important;
      height: 100dvh !important;
    }

    /* Force all direct children panels to respect viewport */
    body.whatsgo-mobile-mode #app > div > div > div {
      min-width: 0 !important;
    }

    /* --- 2. CHAT LIST PANEL (#side) --- */
    body.whatsgo-mobile-mode #side {
      width: 100vw !important;
      max-width: 100vw !important;
      min-width: 0 !important;
      flex: 0 0 100vw !important;
      height: 100% !important;
      border-right: none !important;
    }

    /* Chat list header - compact */
    body.whatsgo-mobile-mode #side header {
      min-height: 52px !important;
      padding: 0 8px !important;
    }

    /* Search bar optimization */
    body.whatsgo-mobile-mode #side [data-testid="chat-list-search"] {
      padding: 4px 8px !important;
    }

    /* Chat item rows - touch-friendly spacing */
    body.whatsgo-mobile-mode #side [data-testid="cell-frame-container"] {
      padding: 0 12px !important;
    }

    /* --- 3. CONVERSATION PANEL (#main) --- */
    body.whatsgo-mobile-mode #main {
      width: 100vw !important;
      max-width: 100vw !important;
      min-width: 0 !important;
      flex: 0 0 100vw !important;
      height: 100% !important;
      left: 0 !important;
      position: relative !important;
    }

    /* Chat header - compact height, good touch targets */
    body.whatsgo-mobile-mode #main header {
      min-height: 52px !important;
      padding: 0 8px !important;
    }

    /* Message bubbles - max width 85% for readability on small screens */
    body.whatsgo-mobile-mode .message-in .copyable-text,
    body.whatsgo-mobile-mode .message-out .copyable-text {
      max-width: 85vw !important;
    }

    body.whatsgo-mobile-mode .message-in,
    body.whatsgo-mobile-mode .message-out {
      max-width: 85% !important;
    }

    /* Input area (compose bar) - comfortable mobile spacing */
    body.whatsgo-mobile-mode [data-testid="conversation-compose-box-input"] {
      min-height: 40px !important;
    }

    body.whatsgo-mobile-mode footer {
      padding: 4px 4px !important;
    }

    /* --- 4. SINGLE-PANE VIEW SWITCHING (1-Column Layout) --- */
    /* In chat state: hide side chat list, show active conversation */
    body.whatsgo-mobile-mode.whatsgo-in-chat #side {
      display: none !important;
    }
    body.whatsgo-mobile-mode.whatsgo-in-chat #main {
      display: flex !important;
      flex-direction: column !important;
    }

    /* In list state: show chat list, hide conversation pane */
    body.whatsgo-mobile-mode.whatsgo-in-list #main {
      display: none !important;
    }
    body.whatsgo-mobile-mode.whatsgo-in-list #side {
      display: flex !important;
    }

    /* --- 5. LOGIN / QR CODE PAGE OPTIMIZATION --- */
    /* Target the landing/intro container */
    body.whatsgo-mobile-mode .landing-wrapper,
    body.whatsgo-mobile-mode ._1XJRN,
    body.whatsgo-mobile-mode [data-testid="intro-md"],
    body.whatsgo-mobile-mode .landing-window {
      width: 100vw !important;
      min-width: 0 !important;
      max-width: 100vw !important;
      padding: 16px !important;
      box-sizing: border-box !important;
    }

    /* QR code - centered and properly sized */
    body.whatsgo-mobile-mode [data-testid="qrcode"],
    body.whatsgo-mobile-mode canvas[aria-label],
    body.whatsgo-mobile-mode .landing-main {
      max-width: 90vw !important;
      margin: 0 auto !important;
    }

    /* Landing page inner content */
    body.whatsgo-mobile-mode .landing-main .landing-header,
    body.whatsgo-mobile-mode .landing-main > div {
      width: 100% !important;
      max-width: 100% !important;
      padding: 0 8px !important;
      box-sizing: border-box !important;
    }

    /* Hide desktop-only elements on login page */
    body.whatsgo-mobile-mode .landing-main .landing-headerTitle + div,
    body.whatsgo-mobile-mode [data-testid="intro-companion-action-cta"] {
      font-size: 14px !important;
    }

    /* Landing title text - readable on mobile */
    body.whatsgo-mobile-mode .landing-main h1,
    body.whatsgo-mobile-mode .landing-headerTitle {
      font-size: 20px !important;
      line-height: 1.3 !important;
    }

    /* Intro screen (no chat selected splash) */
    body.whatsgo-mobile-mode [data-testid="intro-md"] {
      padding: 20px !important;
    }

    body.whatsgo-mobile-mode [data-testid="intro-md"] h1 {
      font-size: 22px !important;
    }

    /* --- 6. SECONDARY PANELS - FULLSCREEN ON MOBILE --- */

    /* Contact Info / Group Info drawer (right panel / 3rd column) */
    body.whatsgo-mobile-mode [data-testid="contact-info-drawer"],
    body.whatsgo-mobile-mode [data-testid="group-info-drawer"],
    body.whatsgo-mobile-mode #app > div > div > span:last-child > div {
      position: fixed !important;
      top: 0 !important;
      left: 0 !important;
      width: 100vw !important;
      height: 100vh !important;
      height: 100dvh !important;
      min-width: 0 !important;
      max-width: 100vw !important;
      z-index: 1000 !important;
    }

    /* Status / Channels / Communities sliding panels over #side */
    body.whatsgo-mobile-mode [data-testid="status-v3-drawer"],
    body.whatsgo-mobile-mode [data-testid="channels-drawer"],
    body.whatsgo-mobile-mode [data-testid="communities-drawer"],
    body.whatsgo-mobile-mode #side > div[tabindex] > div[data-animate-drawer-enter="true"],
    body.whatsgo-mobile-mode #side span[data-testid] > div[tabindex] {
      width: 100vw !important;
      min-width: 0 !important;
      max-width: 100vw !important;
    }

    /* Settings panel (WhatsApp Web settings, not WhatsGo settings) */
    body.whatsgo-mobile-mode [data-testid="settings-drawer"] {
      width: 100vw !important;
      min-width: 0 !important;
      max-width: 100vw !important;
    }

    /* Search messages panel inside chat */
    body.whatsgo-mobile-mode [data-testid="search-in-chat-panel"] {
      width: 100vw !important;
      min-width: 0 !important;
    }

    /* --- 7. EMOJI / STICKER / GIF PICKER --- */
    body.whatsgo-mobile-mode [data-testid="emoji-picker"],
    body.whatsgo-mobile-mode [data-testid="sticker-picker"],
    body.whatsgo-mobile-mode [data-testid="gif-picker"],
    body.whatsgo-mobile-mode [data-testid="media-picker-panel"] {
      width: 100vw !important;
      min-width: 0 !important;
      max-width: 100vw !important;
      max-height: 50vh !important;
    }

    /* --- 8. MEDIA VIEWER / LIGHTBOX --- */
    body.whatsgo-mobile-mode [data-testid="media-viewer"],
    body.whatsgo-mobile-mode [data-testid="image-thumb-viewer"],
    body.whatsgo-mobile-mode .overlay,
    body.whatsgo-mobile-mode ._2ADRW {
      width: 100vw !important;
      height: 100vh !important;
      height: 100dvh !important;
      min-width: 0 !important;
    }

    /* --- 9. MODAL DIALOGS & POPUPS --- */
    body.whatsgo-mobile-mode [data-testid="popup"],
    body.whatsgo-mobile-mode [role="dialog"],
    body.whatsgo-mobile-mode ._3J6wB {
      max-width: 90vw !important;
      min-width: 0 !important;
      width: auto !important;
    }

    /* Context menu (right-click / long-press menu) */
    body.whatsgo-mobile-mode [data-testid="context-menu"],
    body.whatsgo-mobile-mode ul[role="menu"] {
      max-width: 85vw !important;
      min-width: 160px !important;
    }

    /* --- 10. HIDE DESKTOP-ONLY ELEMENTS --- */
    /* Desktop app download banner */
    [data-testid="banner-download-desktop-app"] {
      display: none !important;
    }

    /* "Try WhatsApp for Windows" and similar download prompts */
    body.whatsgo-mobile-mode [data-testid="intro-companion-action"],
    body.whatsgo-mobile-mode [data-testid="chatlist-banner-container"] [data-testid*="download"],
    body.whatsgo-mobile-mode .two._aigs {
      display: none !important;
    }

    /* Desktop tooltip hovers - not needed on touch */
    body.whatsgo-mobile-mode [data-testid="tooltip"] {
      display: none !important;
    }

    /* --- 11. TOUCH INTERACTION IMPROVEMENTS --- */
    /* Ensure minimum touch target sizes (44x44dp) */
    body.whatsgo-mobile-mode button,
    body.whatsgo-mobile-mode [role="button"] {
      min-width: 36px !important;
      min-height: 36px !important;
    }

    /* Prevent text selection on UI elements during touch */
    body.whatsgo-mobile-mode header,
    body.whatsgo-mobile-mode footer,
    body.whatsgo-mobile-mode nav {
      -webkit-user-select: none !important;
      user-select: none !important;
    }

    /* Smooth scrolling for chat panels */
    body.whatsgo-mobile-mode #side,
    body.whatsgo-mobile-mode #main,
    body.whatsgo-mobile-mode [data-testid="conversation-panel-body"] {
      -webkit-overflow-scrolling: touch !important;
    }

    /* --- 12. DARK MODE SUPPORT --- */
    /* All styles above use WhatsApp Web's own theming variables where possible.
       The body.dark selector is used by WhatsApp Web for dark mode.
       Our overrides use structural properties (width, display, flex, position)
       that are theme-independent, so they work correctly in both light and dark mode. */
  ''';

  /// JavaScript to observe DOM changes, toggle CSS classes, and bridge chat state to Flutter.
  /// v2.0: Throttled MutationObserver, accurate chat detection, no virtual back button injection.
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

        // Accurate chat detection: check for actual conversation content,
        // not just the presence of #main (which may contain the intro/splash screen)
        var main = document.querySelector('#main');
        var hasConversation = main && (
          main.querySelector('[data-testid="conversation-panel-body"]') ||
          main.querySelector('[data-testid="conversation-compose-box-input"]') ||
          main.querySelector('.copyable-area')
        );
        var inChat = !!hasConversation;

        if (inChat) {
          document.body.classList.add('whatsgo-in-chat');
          document.body.classList.remove('whatsgo-in-list');
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

      // Close active chat (used by Android Back button via PopScope)
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
        }, 150);
      };

      // Throttled MutationObserver using requestAnimationFrame
      // Limits updateChatState() to max once per animation frame (~60fps / 16ms)
      var pendingUpdate = false;
      var observer = new MutationObserver(function(mutations) {
        if (!pendingUpdate) {
          pendingUpdate = true;
          requestAnimationFrame(function() {
            updateChatState();
            pendingUpdate = false;
          });
        }
      });

      observer.observe(document.body, { childList: true, subtree: true });
      updateChatState();
    })();
  ''';

  /// Script to disable responsive mode (retained for potential future desktop mode)
  static const String disableMobileScript = '''
    (function() {
      document.body.classList.remove('whatsgo-mobile-mode');
      document.body.classList.remove('whatsgo-in-chat');
      document.body.classList.remove('whatsgo-in-list');
    })();
  ''';
}
