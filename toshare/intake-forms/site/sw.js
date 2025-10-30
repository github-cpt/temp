/* SW stable v1 — basic offline; HTML network-first, assets cache-first */
const CACHE_NAME = 'intake-cache-v1';
const CORE_ASSETS = [
  '/',
  '/index.html',
  '/thanks.html',
  '/assets/css/styles.css',
  '/assets/js/main.js',
  '/assets/icons/pwa-192.png',
  '/assets/icons/pwa-512.png',
  '/assets/icons/pwa-ios-180.png',
  '/assets/icons/dolphin.svg'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(CORE_ASSETS)).then(self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => Promise.all(keys.map((k) => (k === CACHE_NAME ? null : caches.delete(k)))))
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const { request } = event;
  const accept = request.headers.get('accept') || '';
  // HTML: network-first
  if (request.mode === 'navigate' || accept.includes('text/html')) {
    event.respondWith(
      fetch(request)
        .then((resp) => {
          const clone = resp.clone();
          caches.open(CACHE_NAME).then((c) => c.put(request, clone));
          return resp;
        })
        .catch(() => caches.match(request))
    );
    return;
  }
  // Assets: cache-first
  event.respondWith(
    caches.match(request).then((cached) => cached || fetch(request).then((resp) => {
      const clone = resp.clone();
      caches.open(CACHE_NAME).then((c) => c.put(request, clone));
      return resp;
    }))
  );
});
