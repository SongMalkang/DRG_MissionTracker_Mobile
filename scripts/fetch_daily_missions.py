import sys
import io
import argparse
import time
import requests
import json
import os
from datetime import datetime, timedelta, timezone

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")


def fetch_bulk_data():
    """오늘과 내일의 미션 데이터를 doublexp.net에서 가져와 압축 포맷으로 저장."""
    base_url = "https://doublexp.net/static/json/bulkmissions/"
    dates = [(datetime.now(timezone.utc) + timedelta(days=i)).strftime('%Y-%m-%d') for i in range(0, 2)]
    optimized_data = {}

    for date in dates:
        url = f"{base_url}{date}.json"
        print(f"Fetching {url}...")
        try:
            res = requests.get(url, timeout=15)
            if res.status_code == 200:
                raw = res.json()
                for ts, content in raw.items():
                    if not isinstance(content, dict):
                        continue

                    missions_list = []
                    biomes = content.get("Biomes", {})
                    for biome_name, missions in biomes.items():
                        for m in missions:
                            mutator = m.get("MissionMutator")
                            warnings = m.get("MissionWarnings", [])

                            missions_list.append({
                                "b": biome_name,
                                "t": m.get("PrimaryObjective"),
                                "so": m.get("SecondaryObjective"),
                                "cn": m.get("CodeName"),
                                "l": int(m.get("Length", 1)),
                                "c": int(m.get("Complexity", 1)),
                                "bf": mutator if mutator else None,
                                "df": ", ".join(warnings) if warnings else None,
                                "s": m.get("included_in", [])
                            })
                    optimized_data[ts] = missions_list
            else:
                print(f"Failed to fetch {date}: Status {res.status_code}")
        except Exception as e:
            print(f"Error processing {date}: {e}")

    if optimized_data:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        out_path = os.path.join(script_dir, '..', 'data', 'daily_missions.json')
        out_path = os.path.normpath(out_path)
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        with open(out_path, 'w', encoding='utf-8') as f:
            json.dump(optimized_data, f, ensure_ascii=False)
        print(f"💾 저장 위치: {out_path}")
        print(f"✅ 최적화 완료: {len(optimized_data)} 개의 타임슬롯 저장됨")

        has_double_xp = any(m['bf'] == "Double XP" for ms in optimized_data.values() for m in ms)
        print(f"🔍 Double XP 데이터 포함 여부: {has_double_xp}")


def _write_summary(lines):
    """GitHub Actions Job Summary에 내용을 추가한다."""
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY", "")
    if summary_path:
        try:
            with open(summary_path, "a", encoding="utf-8") as f:
                f.write("\n".join(lines) + "\n")
        except Exception:
            pass


def fetch_deep_dive(poll_mode=False, poll_max_seconds=1500):
    """이번 주 Deep Dive 데이터를 doublexp.net에서 가져와 저장.

    Deep Dive는 매주 목요일 11:00 UTC(KST 20:00)에 리셋된다.
    가장 최근 목요일 11:00 UTC 시점의 데이터를 가져온다.

    전략: 이번 주(현재) DD를 먼저 시도하고, 실패하면 지난주 DD를 시도한다.
    이를 통해 매일 00:05 UTC 실행에서도 최신 DD를 캐치할 수 있다.
    (doublexp.net이 목요일 리셋 전에 다음 주 DD를 미리 게시하는 경우 대응)

    Args:
        poll_mode: True이면 적응형 폴링 모드로 동작한다.
        poll_max_seconds: 폴링 모드에서 최대 대기 시간 (초, 기본 1500=25분).
    """
    now = datetime.now(timezone.utc)
    summary = []

    # 가장 최근 목요일 계산 (weekday: Mon=0, Thu=3)
    days_since_thursday = (now.weekday() - 3) % 7
    thursday = now - timedelta(days=days_since_thursday)
    thursday = thursday.replace(hour=11, minute=0, second=0, microsecond=0)

    # 오늘이 목요일인데 아직 11:00 UTC 전이면 지난주 목요일
    if now < thursday:
        thursday -= timedelta(days=7)

    # 이번 주 DD와 다음 주 DD 후보 목록 (우선순위 순)
    next_thursday = thursday + timedelta(days=7)
    candidates = []

    # 다음 목요일 DD를 먼저 시도 (doublexp.net이 미리 게시하는 경우)
    if now >= thursday and now < next_thursday:
        candidates.append(next_thursday)

    # 현재 주 DD
    candidates.append(thursday)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    out_path = os.path.join(script_dir, '..', 'data', 'deep_dive.json')
    out_path = os.path.normpath(out_path)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)

    # 기존 파일의 CodeName을 읽어서 동일 데이터 재저장 방지
    existing_names = set()
    existing_info = {}
    existing_has_thursday = False
    if os.path.exists(out_path):
        try:
            with open(out_path, 'r', encoding='utf-8') as f:
                existing = json.load(f)
            existing_has_thursday = "thursday" in existing
            dd = existing.get("Deep Dives", {})
            for key in ["Deep Dive Normal", "Deep Dive Elite"]:
                cn = dd.get(key, {}).get("CodeName", "")
                biome = dd.get(key, {}).get("Biome", "")
                if cn:
                    existing_names.add(cn)
                    existing_info[key] = f"{biome} - {cn}"
        except Exception:
            pass

    summary.append("### Deep Dive")
    summary.append(f"- **실행 시각**: {now.strftime('%Y-%m-%d %H:%M UTC')}")
    summary.append(f"- **기준 목요일**: {thursday.strftime('%Y-%m-%d')} 11:00 UTC")
    if existing_info:
        summary.append(f"- **기존 Normal**: {existing_info.get('Deep Dive Normal', 'N/A')}")
        summary.append(f"- **기존 Elite**: {existing_info.get('Deep Dive Elite', 'N/A')}")

    # ── 폴링 모드 ──────────────────────────────────────────────────────────────
    if poll_mode:
        # 폴링 대상은 이번 주 목요일 DD (다음 주 선점 후보 제외, 목요일 업데이트 전용)
        poll_thursday = thursday
        date_str = poll_thursday.strftime('%Y-%m-%d')
        url = f"https://doublexp.net/static/json/DD_{date_str}T11-00-00Z.json"

        summary.append(f"- **폴링 모드**: 활성화 (최대 {poll_max_seconds}초)")
        summary.append(f"- **대상 URL**: {url}")

        print(f"[POLL] Deep Dive 폴링 시작")
        print(f"[POLL] 대상 URL: {url}")
        print(f"[POLL] 최대 대기 시간: {poll_max_seconds}초 ({poll_max_seconds // 60}분)")
        print(f"[POLL] 기존 데이터 CodeNames: {existing_names or '없음'}")

        poll_start = time.monotonic()
        attempt = 0

        while True:
            elapsed = time.monotonic() - poll_start
            remaining = poll_max_seconds - elapsed

            if remaining <= 0:
                print(f"[POLL] 최대 대기 시간 초과 ({poll_max_seconds}초). 종료.")
                summary.append(f"- **결과**: ⏰ 폴링 타임아웃 ({poll_max_seconds}초 경과, 새 데이터 없음)")
                _write_summary(summary)
                return

            attempt += 1
            ts_str = datetime.now(timezone.utc).strftime('%H:%M:%S UTC')
            print(f"[POLL] #{attempt} | {ts_str} | 경과 {elapsed:.0f}s | 남은 시간 {remaining:.0f}s")

            # HEAD 요청으로 가볍게 존재 확인
            try:
                head_res = requests.head(url, timeout=10)
                print(f"[POLL]   HEAD → HTTP {head_res.status_code}")

                if head_res.status_code != 200:
                    # URL이 아직 존재하지 않음 → 다음 인터벌까지 대기
                    pass
                else:
                    # URL이 200 → GET으로 실제 데이터 확인
                    try:
                        get_res = requests.get(url, timeout=15)
                        if get_res.status_code == 200:
                            data = get_res.json()

                            dd = data.get("Deep Dives", {})
                            normal = dd.get("Deep Dive Normal", {})
                            elite = dd.get("Deep Dive Elite", {})

                            if not normal and not elite:
                                print(f"[POLL]   GET → Deep Dive 데이터 비어있음, 계속 폴링")
                            else:
                                new_names = set()
                                for key_data in [normal, elite]:
                                    cn = key_data.get("CodeName", "")
                                    if cn:
                                        new_names.add(cn)

                                if new_names and new_names == existing_names and existing_has_thursday:
                                    print(f"[POLL]   GET → 기존 데이터와 동일 (CodeNames: {new_names}), 계속 폴링")
                                else:
                                    # 진짜 새 데이터!
                                    data["thursday"] = date_str

                                    with open(out_path, 'w', encoding='utf-8') as f:
                                        json.dump(data, f, ensure_ascii=False)

                                    print(f"[POLL]   ✅ 새 Deep Dive 데이터 저장: {out_path}")
                                    print(f"[POLL]   Normal: {normal.get('Biome', 'N/A')} - {normal.get('CodeName', 'N/A')}")
                                    print(f"[POLL]   Elite:  {elite.get('Biome', 'N/A')} - {elite.get('CodeName', 'N/A')}")
                                    print(f"[POLL]   총 소요 시간: {elapsed:.0f}초 ({attempt}회 시도)")

                                    summary.append(f"- **결과**: 🆕 새 데이터 저장! ({elapsed:.0f}초 후, {attempt}회 시도)")
                                    summary.append(f"  - Normal: {normal.get('Biome', 'N/A')} - {normal.get('CodeName', 'N/A')}")
                                    summary.append(f"  - Elite: {elite.get('Biome', 'N/A')} - {elite.get('CodeName', 'N/A')}")
                                    _write_summary(summary)
                                    return
                        else:
                            print(f"[POLL]   GET → HTTP {get_res.status_code}")
                    except Exception as e:
                        print(f"[POLL]   GET 오류: {e}")

            except Exception as e:
                print(f"[POLL]   HEAD 오류: {e}")

            # 적응형 인터벌 계산
            if elapsed < 300:        # 0-5분: 10초
                interval = 10
            elif elapsed < 600:      # 5-10분: 15초
                interval = 15
            elif elapsed < 1200:     # 10-20분: 30초
                interval = 30
            else:                    # 20분+: 60초
                interval = 60

            # 남은 시간보다 인터벌이 길면 남은 시간만큼만 대기
            sleep_time = min(interval, max(0, remaining - 1))
            if sleep_time <= 0:
                continue
            print(f"[POLL]   다음 확인까지 {sleep_time}초 대기...")
            time.sleep(sleep_time)

        # (while True는 위에서 return 또는 타임아웃으로 종료됨)

    # ── 기존 원샷 모드 (poll_mode=False) ───────────────────────────────────────
    for thu in candidates:
        date_str = thu.strftime('%Y-%m-%d')
        url = f"https://doublexp.net/static/json/DD_{date_str}T11-00-00Z.json"
        print(f"Fetching Deep Dive: {url}...")

        try:
            res = requests.get(url, timeout=15)
            if res.status_code == 200:
                data = res.json()

                # 검증: Deep Dives 키 존재 확인
                dd = data.get("Deep Dives", {})
                normal = dd.get("Deep Dive Normal", {})
                elite = dd.get("Deep Dive Elite", {})

                if not normal and not elite:
                    print(f"⚠️ {date_str}: Deep Dive 데이터가 비어있음, 건너뜀")
                    summary.append(f"- **{date_str}**: 빈 데이터, 건너뜀")
                    continue

                # 새 데이터인지 확인
                new_names = set()
                for key_data in [normal, elite]:
                    cn = key_data.get("CodeName", "")
                    if cn:
                        new_names.add(cn)

                if new_names and new_names == existing_names and existing_has_thursday:
                    print(f"ℹ️ {date_str}: 기존 데이터와 동일, 건너뜀")
                    summary.append(f"- **결과**: ✅ 동일 데이터 (변경 없음)")
                    _write_summary(summary)
                    return

                data["thursday"] = date_str

                with open(out_path, 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False)

                print(f"✅ Deep Dive 저장: {out_path}")
                print(f"   Normal: {normal.get('Biome', 'N/A')} - {normal.get('CodeName', 'N/A')}")
                print(f"   Elite:  {elite.get('Biome', 'N/A')} - {elite.get('CodeName', 'N/A')}")
                summary.append(f"- **결과**: 🆕 새 데이터 저장!")
                summary.append(f"  - Normal: {normal.get('Biome', 'N/A')} - {normal.get('CodeName', 'N/A')}")
                summary.append(f"  - Elite: {elite.get('Biome', 'N/A')} - {elite.get('CodeName', 'N/A')}")
                _write_summary(summary)
                return  # 성공하면 즉시 종료
            else:
                print(f"⚠️ {date_str}: Status {res.status_code}")
                summary.append(f"- **{date_str}**: HTTP {res.status_code}")
        except Exception as e:
            print(f"⚠️ {date_str}: {e}")
            summary.append(f"- **{date_str}**: 오류 - {e}")

    print("ℹ️ Deep Dive: 새 데이터 없음 (기존 데이터 유지)")
    summary.append("- **결과**: ⚠️ 새 데이터 없음 (기존 유지)")
    _write_summary(summary)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="DRG Mission / Deep Dive 데이터 수집 스크립트")
    parser.add_argument(
        "--poll",
        action="store_true",
        help="Deep Dive 적응형 폴링 모드 활성화 (목요일 DD 업데이트 감지용)"
    )
    parser.add_argument(
        "--poll-max-seconds",
        type=int,
        default=1500,
        metavar="SECONDS",
        help="폴링 모드 최대 대기 시간 (초, 기본값: 1500 = 25분)"
    )
    args = parser.parse_args()

    if args.poll:
        fetch_deep_dive(poll_mode=True, poll_max_seconds=args.poll_max_seconds)
    else:
        fetch_bulk_data()
        fetch_deep_dive()
