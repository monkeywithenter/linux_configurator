#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
# shellcheck source=utils/log.sh
source "${SCRIPT_DIR}/utils/log.sh"

usage() {
  cat <<EOF
🧾 用法:
  bash build.sh <script_name> [args...]
  ./build.sh <script_name> [args...]

💡 说明:
  <script_name> 对应 ./scripts 下的脚本名称（不含 .sh 后缀）

EOF
}

list_available_scripts() {
  if ! compgen -G "${SCRIPTS_DIR}/*.sh" > /dev/null; then
    printf '❌ 当前没有可用脚本：%s\n' "${SCRIPTS_DIR}" >&2
    return
  fi

  printf '✅ 可用脚本:\n' >&2
  for file in "${SCRIPTS_DIR}"/*.sh; do
    printf '  - %s\n' "$(basename "${file}" .sh)" >&2
  done
}

main() {
  if [[ "$#" -lt 1 ]]; then
    usage
    list_available_scripts
    exit 1
  fi

  local script_name="$1"
  shift

  if [[ "${script_name}" == "-h" || "${script_name}" == "--help" ]]; then
    usage
    list_available_scripts
    exit 0
  fi

  local script_path="${SCRIPTS_DIR}/${script_name}.sh"
  if [[ ! -f "${script_path}" ]]; then
    print_error "未找到脚本 ${script_name}"
    list_available_scripts
    exit 1
  fi

  bash "${script_path}" "$@"
  print_success "✅ 完成 ${script_name}"
}

main "$@"
