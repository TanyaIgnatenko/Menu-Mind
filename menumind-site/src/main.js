/* MenuMind landing — tiny progressive enhancement.
   Everything works without JS; this only adds nicety. */
(function () {
  'use strict';

  var isAndroid = /android/i.test(navigator.userAgent);
  var isMobile = isAndroid || /iphone|ipad|ipod|mobile/i.test(navigator.userAgent);

  // Non-Android desktop visitors: nudge them toward the QR.
  if (!isMobile) {
    var hint = document.getElementById('android-hint');
    if (hint) hint.hidden = false;
  }

  // Smooth-scroll in-page anchors (respects reduced-motion via CSS scroll-behavior).
  document.querySelectorAll('a[href^="#"]').forEach(function (a) {
    a.addEventListener('click', function (e) {
      var id = a.getAttribute('href');
      if (id.length < 2) return;
      var target = document.querySelector(id);
      if (!target) return;
      e.preventDefault();
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      // move focus for keyboard users
      target.setAttribute('tabindex', '-1');
      target.focus({ preventScroll: true });
    });
  });

  // Download buttons: let the native <a download> do the work, but if a
  // non-Android visitor clicks, surface the hint instead of nagging.
  // (The href is the real download target — see TODO in the HTML.)
  document.querySelectorAll('.js-download').forEach(function (btn) {
    btn.addEventListener('click', function () {
      if (!isAndroid) {
        var hint = document.getElementById('android-hint');
        if (hint) {
          hint.hidden = false;
          hint.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
      }
      // TODO: fire analytics event here (e.g. plausible('apk_download')).
    });
  });
})();
