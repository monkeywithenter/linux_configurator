#!/usr/bin/env bash

# Unified logging helpers.
# Colors are enabled only for interactive terminals (TTY).

readonly LOG_COLOR_RED='\033[31m'
readonly LOG_COLOR_YELLOW='\033[33m'
readonly LOG_COLOR_BLUE='\033[34m'
readonly LOG_COLOR_GREEN='\033[32m'
readonly LOG_STYLE_BOLD='\033[1m'
readonly LOG_COLOR_RESET='\033[0m'

log_use_color_stdout=0
log_use_color_stderr=0

if [[ -t 1 ]]; then
  log_use_color_stdout=1
fi

if [[ -t 2 ]]; then
  log_use_color_stderr=1
fi

print_info() {
  printf '[INFO] %s\n' "$1"
}

print_start() {
  if [[ "${log_use_color_stdout}" -eq 1 ]]; then
    printf '%b%b[START] %s%b\n' "${LOG_STYLE_BOLD}" "${LOG_COLOR_BLUE}" "$1" "${LOG_COLOR_RESET}"
    return
  fi
  printf '[START] %s\n' "$1"
}

print_warn() {
  if [[ "${log_use_color_stderr}" -eq 1 ]]; then
    printf '%b%b[WARN] %s%b\n' "${LOG_STYLE_BOLD}" "${LOG_COLOR_YELLOW}" "$1" "${LOG_COLOR_RESET}" >&2
    return
  fi
  printf '[WARN] %s\n' "$1" >&2
}

print_error() {
  if [[ "${log_use_color_stderr}" -eq 1 ]]; then
    printf '%b%b[ERROR] %s%b\n' "${LOG_STYLE_BOLD}" "${LOG_COLOR_RED}" "$1" "${LOG_COLOR_RESET}" >&2
    return
  fi
  printf '[ERROR] %s\n' "$1" >&2
}

print_success() {
  if [[ "${log_use_color_stdout}" -eq 1 ]]; then
    printf '%b%b[INFO] %s%b\n' "${LOG_STYLE_BOLD}" "${LOG_COLOR_GREEN}" "$1" "${LOG_COLOR_RESET}"
    return
  fi
  printf '[INFO] %s\n' "$1"
}
