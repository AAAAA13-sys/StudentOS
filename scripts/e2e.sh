#!/usr/bin/env bash
# End-to-end contract check through the gateway on real PostgreSQL.
# Usage: scripts/e2e.sh [base_url]   (default http://localhost:8000)
set -u
BASE="${1:-http://localhost:8000}"
PASS=0; FAIL=0
STAMP="$(date +%s)$RANDOM"

# req METHOD PATH [TOKEN] [JSON]  -> sets CODE and BODY
req() {
  local method="$1" path="$2" token="${3:-}" data="${4:-}"
  local args=(-s -o /tmp/e2e_body -w '%{http_code}' -X "$method" "$BASE$path" -H 'Accept: application/json')
  [ -n "$token" ] && args+=(-H "Authorization: Bearer $token")
  [ -n "$data" ] && args+=(-H 'Content-Type: application/json' -d "$data")
  CODE="$(curl "${args[@]}")"
  BODY="$(cat /tmp/e2e_body 2>/dev/null)"
}
jget() { python -c "import sys,json; d=json.load(sys.stdin); print(eval(sys.argv[1], {'d': d}))" "$1" <<<"$BODY" 2>/dev/null; }
check() { # description, condition result (0/1 as string 'ok'), detail
  if [ "$2" = "ok" ]; then PASS=$((PASS+1)); echo "PASS  $1"; else FAIL=$((FAIL+1)); echo "FAIL  $1  -> HTTP $CODE $BODY" | cut -c1-400; fi
}
expect_code() { [ "$CODE" = "$2" ] && check "$1 ($2)" ok || check "$1 (wanted $2)" no; }
expect_eq() { [ "$(jget "$2")" = "$3" ] && check "$1" ok || check "$1 [got $(jget "$2") wanted $3]" no; }

echo "== Health =="
for s in auth calendar finance notes; do req GET "/api/$s/health"; expect_code "$s health" 200; done
req GET /api/health; expect_code "gateway health" 200

echo "== Auth =="
EMAIL_A="ana.$STAMP@example.com"; EMAIL_B="ben.$STAMP@example.com"
req POST /api/auth/register "" "{\"name\":\"Ana\",\"email\":\"$EMAIL_A\",\"password\":\"password123\"}"; expect_code "register A" 201
TA="$(jget "d['token']")"
req POST /api/auth/register "" "{\"name\":\"Ben\",\"email\":\"$EMAIL_B\",\"password\":\"password123\"}"; expect_code "register B" 201
TB="$(jget "d['token']")"
req POST /api/auth/register "" "{\"name\":\"Ana\",\"email\":\"$EMAIL_A\",\"password\":\"password123\"}"; expect_code "duplicate email rejected" 422
req POST /api/auth/login "" "{\"email\":\"$EMAIL_A\",\"password\":\"password123\"}"; expect_code "login A" 200
TA="$(jget "d['token']")"
req POST /api/auth/login "" "{\"email\":\"$EMAIL_A\",\"password\":\"wrong-password\"}"; expect_code "login wrong password" 401
req GET /api/auth/me "$TA"; expect_code "me" 200; expect_eq "me email" "d['user']['email']" "$EMAIL_A"
[ -z "$(jget "d['user'].get('password','')")" ] && check "me hides password" ok || check "me hides password" no
req GET /api/auth/me; expect_code "me without token" 401
req GET /api/auth/me "${TA}x"; expect_code "me with tampered token" 401
req GET /api/calendar/events; expect_code "calendar without token" 401
req GET /api/finance/transactions; expect_code "finance without token" 401
req GET /api/notes; expect_code "notes without token" 401
req GET /api/unknown/thing "$TA"; expect_code "unknown service" 404

echo "== Calendar =="
START="$(python -c "import datetime as d; print((d.datetime.now(d.timezone.utc)+d.timedelta(hours=2)).strftime('%Y-%m-%dT%H:%M:00Z'))")"
FROM="$(python -c "import datetime as d; print((d.datetime.now(d.timezone.utc)).strftime('%Y-%m-%dT00:00:00Z'))")"
TO="$(python -c "import datetime as d; print((d.datetime.now(d.timezone.utc)+d.timedelta(days=15)).strftime('%Y-%m-%dT00:00:00Z'))")"
req POST /api/calendar/events "$TA" "{\"title\":\"Math 101\",\"starts_at\":\"$START\",\"duration_minutes\":90,\"location\":\"Room 204\",\"recurrence\":\"weekly\",\"reminder_minutes\":15}"
expect_code "create event" 201; EID="$(jget "d['data']['id']")"
req GET /api/calendar/events "$TA"; expect_code "list events" 200; expect_eq "list has 1 event" "len(d['data'])" 1
req GET "/api/calendar/events?from=$FROM&to=$TO" "$TA"; expect_code "range query" 200
N="$(jget "len(d['data'])")"; { [ "${N:-0}" -ge 2 ] && check "weekly recurrence expanded ($N occurrences in 15 days)" ok; } || check "weekly recurrence expanded" no
req PUT "/api/calendar/events/$EID" "$TA" '{"title":"Math 101 (moved)"}'; expect_code "update event" 200; expect_eq "title updated" "d['data']['title']" "Math 101 (moved)"
req GET /api/calendar/widget "$TA"; expect_code "widget" 200; expect_eq "widget next event" "d['next_event']['title']" "Math 101 (moved)"
req GET /api/calendar/widget "$TB"; expect_eq "widget empty for other user" "d['next_event']" "None"
req GET "/api/calendar/events/$EID" "$TB"; expect_code "other user cannot read event" 404
req PUT "/api/calendar/events/$EID" "$TB" '{"title":"hacked"}'; expect_code "other user cannot update event" 404
req DELETE "/api/calendar/events/$EID" "$TB"; expect_code "other user cannot delete event" 404
req POST /api/calendar/events "$TA" '{"title":""}'; expect_code "event validation" 422

echo "== Finance =="
MONTH="$(date -u +%Y-%m)"; TODAY="$(date -u +%Y-%m-%d)"
req GET /api/finance/categories "$TA"; expect_code "categories" 200; expect_eq "7 categories" "len(d['data'])" 7
req POST /api/finance/transactions "$TA" "{\"type\":\"income\",\"amount\":5000,\"category\":\"Allowance\",\"occurred_on\":\"$TODAY\"}"; expect_code "add income" 201
req POST /api/finance/transactions "$TA" "{\"type\":\"expense\",\"amount\":120.50,\"category\":\"Food\",\"occurred_on\":\"$TODAY\",\"note\":\"Lunch\"}"; expect_code "add expense" 201; XID="$(jget "d['data']['id']")"
req POST /api/finance/transactions "$TA" "{\"type\":\"expense\",\"amount\":0.10,\"category\":\"Transport\",\"occurred_on\":\"$TODAY\"}"; expect_code "add expense 0.10" 201
req POST /api/finance/transactions "$TA" "{\"type\":\"expense\",\"amount\":0.20,\"category\":\"Transport\",\"occurred_on\":\"$TODAY\"}"; expect_code "add expense 0.20" 201
req GET "/api/finance/summary?month=$MONTH" "$TA"; expect_code "summary" 200
expect_eq "total income" "d['total_income']==5000" True
expect_eq "total expenses" "d['total_expenses']==120.8" True
expect_eq "balance" "d['balance']==4879.2" True
expect_eq "top category" "d['by_category'][0]['category']" "Allowance"
req GET "/api/finance/transactions?month=$MONTH&category=Food" "$TA"; expect_eq "filter by category" "len(d['data'])" 1
req GET "/api/finance/summary?month=$MONTH" "$TB"; expect_eq "other user's summary is empty" "d['total_income']==0 and d['total_expenses']==0" True
req GET "/api/finance/transactions/$XID" "$TB"; expect_code "other user cannot read transaction" 404
req DELETE "/api/finance/transactions/$XID" "$TB"; expect_code "other user cannot delete transaction" 404
req POST /api/finance/transactions "$TA" "{\"type\":\"expense\",\"amount\":-5,\"category\":\"Food\",\"occurred_on\":\"$TODAY\"}"; expect_code "negative amount rejected" 422
req DELETE "/api/finance/transactions/$XID" "$TA"; expect_code "delete transaction" 204
req GET "/api/finance/summary?month=$MONTH" "$TA"; expect_eq "summary after delete" "round(d['total_expenses'],2)==0.3" True

echo "== Notes =="
req POST /api/notes "$TA" '{"title":"Lecture 3: Derivatives","body":"Chain rule and the Quokka example","tags":["Math"," Exam "]}'; expect_code "create note" 201; NID="$(jget "d['data']['id']")"
expect_eq "tags normalised" "sorted(d['data']['tags'])" "['exam', 'math']"
req POST /api/notes "$TA" '{"title":"Groceries","body":"rice, eggs","tags":["home"]}'; expect_code "create second note" 201
req GET "/api/notes?q=quokka" "$TA"; expect_code "search body" 200; expect_eq "search by body finds 1" "len(d['data'])" 1
req GET "/api/notes?q=LECTURE" "$TA"; expect_eq "search by title (case-insensitive)" "len(d['data'])" 1
req GET "/api/notes?q=exam" "$TA"; expect_eq "search by tag" "len(d['data'])" 1
req GET "/api/notes?q=%25" "$TA"; expect_eq "literal % matches nothing" "len(d['data'])" 0
req GET "/api/notes?tag=home" "$TA"; expect_eq "tag filter" "d['data'][0]['title']" "Groceries"
req GET /api/notes/tags "$TA"; expect_eq "tags list" "d['data']" "['exam', 'home', 'math']"
req PUT "/api/notes/$NID" "$TA" '{"body":"Chain rule, updated"}'; expect_code "update note" 200
req GET /api/notes "$TA"; expect_eq "sorted by last modified" "d['data'][0]['id']" "$NID"
req GET "/api/notes?q=lecture" "$TB"; expect_eq "other user's search is empty" "len(d['data'])" 0
req GET "/api/notes/$NID" "$TB"; expect_code "other user cannot read note" 404
req PUT "/api/notes/$NID" "$TB" '{"title":"hacked"}'; expect_code "other user cannot update note" 404
req DELETE "/api/notes/$NID" "$TB"; expect_code "other user cannot delete note" 404
req DELETE "/api/notes/$NID" "$TA"; expect_code "delete note" 204
req GET "/api/notes/$NID" "$TA"; expect_code "deleted note is gone" 404

echo "== Logout =="
req POST /api/auth/logout "$TA"; expect_code "logout" 204

echo
echo "RESULT: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
