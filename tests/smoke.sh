#!/usr/bin/env bash
# smoke: проверяет, что скрипт жив и отвечает, не снимая экран.
#
# Полноценный снимок проверить здесь нельзя — нужен настоящий терминал
# с compositor. Этот тест ловит только то, что ломается молча: битый
# синтаксис, потерянный файл, неверные права.
#
# Коды выхода проверяются явно, потому что они часть поведения:
#   shot --help  → 0
#   shot d       → 1 (показывает список мониторов и просит указать)
#   shot qqq     → 1 (неизвестная команда)
#   shot last    → 0 если снимки есть, 1 если нет — проверяется отдельно.

set -Eeuo pipefail

cd "$(dirname "$0")/.."
SHOT=./bin/shot

fails=0

check() {
    local name="$1" want="$2"
    shift 2
    local out rc
    set +e
    out="$("$SHOT" "$@" 2>&1)"
    rc=$?
    set -e
    if [ "$rc" -ne "$want" ]; then
        printf 'FAIL  %-10s код %d, ждали %d\n' "$name" "$rc" "$want"
        printf '%s\n' "$out" | head -3 | sed 's/^/        /'
        fails=$((fails + 1))
        return
    fi
    if [ -z "$out" ]; then
        printf 'FAIL  %-10s пустой вывод\n' "$name"
        fails=$((fails + 1))
        return
    fi
    printf 'ok    %-10s код %d, %d строк\n' "$name" "$rc" "$(printf '%s' "$out" | wc -l)"
}

# shot last: код зависит от того, есть ли снимки на машине. 0 — нашёл
# и напечатал путь, 1 — снимков нет. Оба варианта верны, поэтому
# проверяем не код, а форму ответа.
set +e
last_out="$(./bin/shot last 2>&1)"
last_rc=$?
set -e
last_ok=1
if [ "$last_rc" -eq 0 ] && printf '%s' "$last_out" | grep -q '\.png$'; then
    printf 'ok    %-10s нашёл снимок\n' last
elif [ "$last_rc" -eq 1 ]; then
    printf 'ok    %-10s снимков нет (ожидаемо)\n' last
else
    printf 'FAIL  %-10s код %d, вывод: %s\n' last "$last_rc" "$last_out"
    fails=$((fails + 1))
    last_ok=0
fi
[ "$last_ok" -eq 1 ] || true

check help      0 --help
check monitors  1 d
check unknown   1 qqq

# Синтаксис скрипта — отдельным шагом: bash -n ловит опечатки, которые
# при обычном запуске не проявляются.
if bash -n "$SHOT" 2>/dev/null; then
    printf 'ok    %-10s синтаксис\n' syntax
else
    printf 'FAIL  %-10s синтаксис\n' syntax
    fails=$((fails + 1))
fi

if [ -x "$SHOT" ]; then
    printf 'ok    %-10s исполняемый\n' exec
else
    printf 'FAIL  %-10s не исполняемый\n' exec
    fails=$((fails + 1))
fi

echo
if [ "$fails" -eq 0 ]; then
    echo "все проверки прошли"
else
    echo "провалено: $fails"
fi
exit "$fails"