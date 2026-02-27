import requests
import json
import os

# 2026년 현재 가장 유력한 소스 및 공식 미션 시드 관련 URL
URL_CANDIDATES = [
    "https://drgapi.com/v1/missions", # 커뮤니티 통합 API
    "https://raw.githubusercontent.com/rolfosian/drgmissions/gh-pages/missions.json",
    "https://raw.githubusercontent.com/GoldBlaze/DRG-Mission-Data/main/data/missions.json", # 경로 심화
    "https://drg.ghostship.dk/events/weekly" # 공식 주간 이벤트 시드 (참고용)
]

def debug_fetch():
    print("🤖 [Bosco] 심층 탐색을 시작합니다...")
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/json'
    }

    for url in URL_CANDIDATES:
        try:
            print(f"\n📡 연결 시도: {url}")
            response = requests.get(url, headers=headers, timeout=8)
            
            if response.status_code == 200:
                print(f"✅ 성공! 데이터 확인 중...")
                content = response.json()
                # 데이터가 비어있지 않은지 확인
                if content:
                    print(f"📦 데이터 수집 완료 ({len(str(content))} bytes)")
                    save_mock_if_needed(content)
                    return
            else:
                print(f"❌ 실패 (Status: {response.status_code})")
                # 404인 경우 서버가 보낸 메시지 출력
                if response.status_code == 404:
                    print("   ㄴ 해당 경로에 파일이 존재하지 않습니다.")

        except Exception as e:
            print(f"⚠️ 에러 발생: {e}")

    print("\n❗ 모든 데이터 소스에 도달할 수 없습니다.")
    print("💡 팁: 현재 네트워크가 외부 GitHub Raw 서버를 차단하고 있지는 않은지 확인해 주세요.")

def save_mock_if_needed(data):
    os.makedirs('data', exist_ok=True)
    with open('data/current_missions.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print("💾 'data/current_missions.json' 파일이 생성되었습니다.")

if __name__ == "__main__":
    debug_fetch()