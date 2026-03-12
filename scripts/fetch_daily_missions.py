import sys
import io
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


def fetch_deep_dive():
    """이번 주 Deep Dive 데이터를 doublexp.net에서 가져와 저장.

    Deep Dive는 매주 목요일 11:00 UTC(KST 20:00)에 리셋된다.
    가장 최근 목요일 11:00 UTC 시점의 데이터를 가져온다.

    전략: 이번 주(현재) DD를 먼저 시도하고, 실패하면 지난주 DD를 시도한다.
    이를 통해 매일 00:05 UTC 실행에서도 최신 DD를 캐치할 수 있다.
    (doublexp.net이 목요일 리셋 전에 다음 주 DD를 미리 게시하는 경우 대응)
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
    fetch_bulk_data()
    fetch_deep_dive()
