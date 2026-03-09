"""Deep Dive JSON 게시 시점 확인 (1회성 스크립트)

다음 목요일 11:00 UTC(KST 20:00) 직전에 실행하면,
doublexp.net이 새 DD JSON을 언제 게시하는지 확인할 수 있다.

사용법: python scripts/check_dd_availability.py
종료:   Ctrl+C

HEAD 요청만 사용하므로 서버 부하 최소 (body 다운로드 없음).
"""

import requests
from datetime import datetime, timedelta, timezone
import time

# 이번 주 목요일 계산
now = datetime.now(timezone.utc)
days_since = (now.weekday() - 3) % 7
thursday = (now - timedelta(days=days_since)).replace(
    hour=11, minute=0, second=0, microsecond=0
)
if now < thursday:
    pass  # 아직 이번 주 목요일 전 → 그대로 사용
else:
    thursday += timedelta(days=7)  # 다음 주 목요일

date_str = thursday.strftime('%Y-%m-%d')
url = f"https://doublexp.net/static/json/DD_{date_str}T11-00-00Z.json"

print(f"대상 URL: {url}")
print(f"대상 시각: {date_str} 11:00 UTC (KST {thursday.hour + 9}:00)")
print(f"현재 시각: {now.strftime('%Y-%m-%d %H:%M:%S')} UTC")
print(f"─" * 50)
print(f"30초 간격으로 HEAD 요청 (Ctrl+C로 종료)\n")

check_count = 0
while True:
    check_count += 1
    t = datetime.now(timezone.utc)
    try:
        res = requests.head(url, timeout=10)
        status = res.status_code
        size = res.headers.get('Content-Length', '?')
        symbol = "✅" if status == 200 else "⏳"
        print(f"{symbol} [{t.strftime('%H:%M:%S')} UTC] #{check_count}  → {status}  (size: {size})")

        if status == 200:
            print(f"\n🎯 게시 확인! {t.strftime('%Y-%m-%d %H:%M:%S')} UTC")
            diff = t - thursday
            print(f"   리셋(11:00 UTC) 대비: +{int(diff.total_seconds())}초 ({diff})")
            break
    except Exception as e:
        print(f"⚠️ [{t.strftime('%H:%M:%S')} UTC] #{check_count}  → 오류: {e}")

    time.sleep(30)
