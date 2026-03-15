// ═══════════════════════════════════════════════════════════════════════════
//  Bosco Terminal — PWA Service Worker
//
//  역할:
//    1. PWA 설치 가능성 (installability) 보장
//    2. Web Push Notification 표시
//    3. 알림 클릭 시 앱으로 이동
//    4. 스마트 캐싱: 무거운 정적 파일은 캐시, 앱 코드는 항상 최신
//
//  캐싱 전략:
//    - index.html, main.dart.js, flutter_bootstrap.js → Network-first
//      (배포마다 바뀜 → 네트워크 우선, 실패 시 캐시 폴백)
//    - canvaskit WASM/JS, 폰트, 아이콘 → Cache-first
//      (수 MB 짜리 파일, Flutter 버전 안 바뀌면 동일)
//    - 외부 API (raw.githubusercontent 등) → Network-only
//      (실시간 미션 데이터)
//
//  버전이 바뀌면 → activate에서 이전 캐시 전체 삭제 → 깨끗한 업데이트
// ═══════════════════════════════════════════════════════════════════════════

// CI에서 빌드 시 자동으로 교체됨 (deploy_web.yml 참고)
const SW_VERSION = '20260315222316';
const CACHE_NAME = `bosco-v${SW_VERSION}`;

// ── Cache-first 대상: 무거운 정적 파일 패턴 ──────────────────────────────
const CACHE_FIRST_PATTERNS = [
  /\/canvaskit\//,       // canvaskit.wasm, canvaskit.js 등 (~7MB)
  /\/assets\//,          // Flutter 에셋 (폰트, 이미지 등)
  /\/icons\//,           // PWA 아이콘
  /\.woff2?$/,           // 웹 폰트
];

// ── Network-only 대상: 절대 캐시하면 안 되는 패턴 ─────────────────────────
const NETWORK_ONLY_PATTERNS = [
  /raw\.githubusercontent\.com/,  // 미션 데이터 API
  /\.json$/,                       // manifest.json 등 동적 JSON
];

function matchesAny(url, patterns) {
  return patterns.some((p) => p.test(url));
}

// ── 설치: 즉시 활성화 ─────────────────────────────────────────────────────
self.addEventListener('install', (event) => {
  console.log(`[SW ${SW_VERSION}] install`);
  self.skipWaiting();
});

// ── 활성화: 이전 버전 캐시 삭제 + 즉시 컨트롤 ────────────────────────────
self.addEventListener('activate', (event) => {
  console.log(`[SW ${SW_VERSION}] activate — purging old caches`);
  event.waitUntil(
    caches.keys().then((names) =>
      Promise.all(
        names
          .filter((name) => name !== CACHE_NAME)
          .map((name) => {
            console.log(`[SW] deleting old cache: ${name}`);
            return caches.delete(name);
          })
      )
    ).then(() => self.clients.claim())
  );
});

// ── Fetch: 파일 종류별 분기 ───────────────────────────────────────────────
self.addEventListener('fetch', (event) => {
  const url = event.request.url;

  // 1) Network-only: API 데이터, JSON
  if (matchesAny(url, NETWORK_ONLY_PATTERNS)) {
    return; // SW가 가로채지 않음 → 브라우저 기본 네트워크 요청
  }

  // 2) Cache-first: CanvasKit, 에셋, 폰트 (무겁고 잘 안 바뀜)
  if (matchesAny(url, CACHE_FIRST_PATTERNS)) {
    event.respondWith(
      caches.open(CACHE_NAME).then((cache) =>
        cache.match(event.request).then((cached) => {
          if (cached) return cached;
          return fetch(event.request).then((response) => {
            if (response.ok) {
              cache.put(event.request, response.clone());
            }
            return response;
          });
        })
      )
    );
    return;
  }

  // 3) Network-first: 앱 코드 (index.html, main.dart.js 등)
  //    → 배포 시 항상 최신 버전을 가져오되, 오프라인이면 캐시 폴백
  if (event.request.mode === 'navigate' ||
      url.endsWith('.js') ||
      url.endsWith('.html')) {
    event.respondWith(
      fetch(event.request)
        .then((response) => {
          if (response.ok) {
            const clone = response.clone();
            caches.open(CACHE_NAME).then((cache) =>
              cache.put(event.request, clone)
            );
          }
          return response;
        })
        .catch(() => caches.match(event.request))
    );
    return;
  }

  // 4) 나머지: 네트워크 요청 그대로 (SW 미개입)
});

// ── Push 이벤트: 서버 푸시 수신 시 ────────────────────────────────────────
self.addEventListener('push', (event) => {
  let data = { title: 'Bosco Terminal', body: 'Double XP mission detected!' };
  if (event.data) {
    try {
      data = event.data.json();
    } catch (_) {
      data.body = event.data.text();
    }
  }
  event.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: 'icons/Icon-192.png',
      badge: 'icons/Icon-192.png',
      tag: data.tag || 'bosco-mission-alert',
      data: { url: data.url || './' },
      vibrate: [200, 100, 200],
    })
  );
});

// ── 알림 클릭: 앱 포커스 또는 새 창 열기 ───────────────────────────────────
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = event.notification.data?.url || './';
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then((clients) => {
        for (const client of clients) {
          if (client.url.includes('DRG_MissionTracker_Mobile') && 'focus' in client) {
            return client.focus();
          }
        }
        return self.clients.openWindow(targetUrl);
      })
  );
});

// ── 메시지 수신: Dart ↔ SW 통신 ────────────────────────────────────────────
self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SHOW_NOTIFICATION') {
    const { title, body, tag } = event.data;
    self.registration.showNotification(title, {
      body: body,
      icon: 'icons/Icon-192.png',
      badge: 'icons/Icon-192.png',
      tag: tag || 'bosco-mission-alert',
      data: { url: './' },
      vibrate: [200, 100, 200],
    });
  }
});
