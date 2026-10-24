#!/bin/bash

log_level_echo() {
    case "$1" in
        DEBUG) echo 0 ;;
        INFO)  echo 1 ;;
        WARN)  echo 2 ;;
        ERROR) echo 3 ;;
        *) return 1 ;;
    esac
}

log_level_printf() {
    case "$1" in
        DEBUG) printf '0\n' ;;
        INFO)  printf '1\n' ;;
        WARN)  printf '2\n' ;;
        ERROR) printf '3\n' ;;
        *) return 1 ;;
    esac
}

echo "--- Test echo ---"

dbg=$(log_level_echo DEBUG) || exit 1
inf=$(log_level_echo INFO) || exit 1

echo "dbg=$dbg"
echo "inf=$inf"

if (( dbg < inf )); then
    echo "DEBUG < INFO"
fi

echo
echo "--- Test printf ---"

dbg=$(log_level_printf DEBUG) || exit 1
inf=$(log_level_printf INFO) || exit 1

echo "dbg=$dbg"
echo "inf=$inf"

if (( dbg < inf )); then
    echo "DEBUG < INFO"
fi