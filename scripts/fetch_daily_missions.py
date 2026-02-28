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


def fetch_deep_dive():
    """이번 주 Deep Dive 데이터를 doublexp.net에서 가져와 저장.

    Deep Dive는 매주 목요일 11:00 UTC(KST 20:00)에 리셋된다.
    가장 최근 목요일 11:00 UTC 시점의 데이터를 가져온다.
    """
    now = datetime.now(timezone.utc)

    # 가장 최근 목요일 계산 (weekday: Mon=0, Thu=3)
    days_since_thursday = (now.weekday() - 3) % 7
    thursday = now - timedelta(days=days_since_thursday)
    thursday = thursday.replace(hour=11, minute=0, second=0, microsecond=0)

    # 오늘이 목요일인데 아직 11:00 UTC 전이면 지난주 목요일
    if now < thursday:
        thursday -= timedelta(days=7)

    date_str = thursday.strftime('%Y-%m-%d')
    url = f"https://doublexp.net/static/json/DD_{date_str}T11-00-00Z.json"
    print(f"Fetching Deep Dive: {url}...")

    try:
        res = requests.get(url, timeout=15)
        if res.status_code == 200:
            data = res.json()

            script_dir = os.path.dirname(os.path.abspath(__file__))
            out_path = os.path.join(script_dir, '..', 'data', 'deep_dive.json')
            out_path = os.path.normpath(out_path)
            os.makedirs(os.path.dirname(out_path), exist_ok=True)
            with open(out_path, 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False)

            # 검증
            dd = data.get("Deep Dives", {})
            normal = dd.get("Deep Dive Normal", {})
            elite = dd.get("Deep Dive Elite", {})
            print(f"✅ Deep Dive 저장: {out_path}")
            print(f"   Normal: {normal.get('Biome', 'N/A')} - {normal.get('CodeName', 'N/A')}")
            print(f"   Elite:  {elite.get('Biome', 'N/A')} - {elite.get('CodeName', 'N/A')}")
        else:
            print(f"Failed to fetch Deep Dive: Status {res.status_code}")
    except Exception as e:
        print(f"Error fetching Deep Dive: {e}")


if __name__ == "__main__":
    fetch_bulk_data()
    fetch_deep_dive()
