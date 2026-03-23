#!/usr/bin/env bash
# ── Pi Deep Dive Poller ──────────────────────────────────────────────
# 목요일 UTC 11:00에 cron으로 1회 실행.
# Python 스크립트가 내부 적응형 폴링(10s→15s→30s→60s)으로 최대 90분간 감시.
# 새 데이터 감지 시 자동 commit & push.
#
# ── 설치 (Pi에서 1회) ────────────────────────────────────────────────
#
#   git clone git@github.com:SongMalkang/DRG_MissionTracker_Mobile.git ~/drg
#   cd ~/drg
#   git config user.name "SongMalkang"
#   git config user.email "SongMalkang@users.noreply.github.com"
#   chmod +x scripts/pi_poll_dd.sh
#
#   crontab -e
#   # KST 기준 (UTC+9): UTC 11:00 = KST 20:00
#   0 20 * * 4 /home/malkang/drg/scripts/pi_poll_dd.sh
#
# ─────────────────────────────────────────────────────────────────────

set -uo pipefail

REPO_DIR="${REPO_DIR:-$HOME/drg}"
LOG_FILE="${LOG_FILE:-$HOME/dd_poll.log}"
LOCK_FILE="/tmp/pi_dd_poll.lock"
MAX_LOG_LINES=500
POLL_TIMEOUT=5400  # 90분: DD 리셋 윈도우 전체 커버

log() {
    echo "$(date -u '+%Y-%m-%d %H:%M:%S UTC') $*" | tee -a "$LOG_FILE"
}

# 로그 크기 제한
if [ -f "$LOG_FILE" ] && [ "$(wc -l < "$LOG_FILE")" -gt "$MAX_LOG_LINES" ]; then
    tail -n "$MAX_LOG_LINES" "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
fi

# 중복 실행 방지
if [ -f "$LOCK_FILE" ]; then
    LOCK_PID=$(cat "$LOCK_FILE" 2>/dev/null)
    if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
        log "[SKIP] Already running (PID: $LOCK_PID)"
        exit 0
    fi
    rm -f "$LOCK_FILE"
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "[START] Deep Dive Thursday poll (max ${POLL_TIMEOUT}s)"

# 사전 검증
if [ ! -d "$REPO_DIR/.git" ]; then
    log "[ERROR] Repo not found at $REPO_DIR"; exit 1
fi
if ! python3 -c "import requests" 2>/dev/null; then
    log "[ERROR] python3 requests not available"; exit 1
fi

cd "$REPO_DIR"

# 최신 코드 pull
log "[PULL] Syncing repo..."
git pull --ff-only >> "$LOG_FILE" 2>&1 || git pull --rebase >> "$LOG_FILE" 2>&1 || {
    log "[ERROR] Pull failed"; exit 1
}

# Python 적응형 폴링 실행 (내부에서 10s→15s→30s→60s 간격으로 최대 90분)
# 이미 이번 주 데이터면 즉시 종료됨
python3 scripts/fetch_daily_missions.py --poll --poll-max-seconds "$POLL_TIMEOUT" 2>&1 | tee -a "$LOG_FILE"
POLL_EXIT=${PIPESTATUS[0]}

if [ "$POLL_EXIT" -ne 0 ]; then
    log "[ERROR] Poll exited with code $POLL_EXIT"; exit "$POLL_EXIT"
fi

# 변경사항 commit & push
git add data/
if git diff --cached --quiet; then
    log "[DONE] No changes"
else
    git commit -m "data: update deep dive (pi) [skip ci]"
    git pull --rebase >> "$LOG_FILE" 2>&1 || true
    if git push >> "$LOG_FILE" 2>&1; then
        log "[DONE] Pushed new DD data!"
    else
        log "[WARN] Push failed, rolling back"
        git reset HEAD~1 --soft
    fi
fi

log "[END] Complete"
