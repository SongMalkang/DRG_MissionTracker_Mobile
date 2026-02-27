import sys
import io
import requests
import json
import os
from datetime import datetime, timedelta

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

def fetch_bulk_data():
    base_url = "https://doublexp.net/static/json/bulkmissions/"
    # 어제, 오늘, 내일 데이터를 모두 가져와서 가용성 확보
    dates = [(datetime.utcnow() + timedelta(days=i)).strftime('%Y-%m-%d') for i in range(-1, 2)]
    optimized_data = {}

    for date in dates:
        url = f"{base_url}{date}.json"
        print(f"Fetching {url}...")
        try:
            res = requests.get(url, timeout=15)
            if res.status_code == 200:
                raw = res.json()
                for ts, content in raw.items():
                    # 1. 날짜 형식이 아닌 키(ver, dailyDeal 등) 제외
                    if not isinstance(content, dict):
                        continue
                    
                    missions_list = []
                    biomes = content.get("Biomes", {})
                    for biome_name, missions in biomes.items():
                        for m in missions:
                            # 2. 데이터 구조 안전하게 추출
                            # MissionMutator: Double XP, Low Gravity 등 (하나의 문자열)
                            # MissionWarnings: Swarmageddon 등 (리스트 형태)
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
        # __file__ 기준 상대 경로 → 로컬·GitHub Actions 모두 올바르게 동작
        script_dir = os.path.dirname(os.path.abspath(__file__))
        out_path = os.path.join(script_dir, '..', 'data', 'daily_missions.json')
        out_path = os.path.normpath(out_path)
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        with open(out_path, 'w', encoding='utf-8') as f:
            json.dump(optimized_data, f, ensure_ascii=False)
        print(f"💾 저장 위치: {out_path}")
        print(f"✅ 최적화 완료: {len(optimized_data)} 개의 타임슬롯 저장됨")
        
        # 검증 출력
        has_double_xp = any(m['bf'] == "Double XP" for ms in optimized_data.values() for m in ms)
        print(f"🔍 Double XP 데이터 포함 여부: {has_double_xp}")

if __name__ == "__main__":
    fetch_bulk_data()
