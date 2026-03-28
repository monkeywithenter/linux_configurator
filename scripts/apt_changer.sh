#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../utils/log.sh
source "${SCRIPT_DIR}/../utils/log.sh"

readonly SOURCES_LIST="/etc/apt/sources.list"
readonly SOURCES_BACKUP="/etc/apt/sources.list.bak"
readonly UBUNTU_SOURCES="/etc/apt/sources.list.d/ubuntu.sources"
readonly SIGNED_BY="/usr/share/keyrings/ubuntu-archive-keyring.gpg"

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    print_error "需要 root 权限，请使用 sudo 运行：sudo ./build.sh apt_changer.sh"
    exit 1
  fi
}

detect_codename() {
  local codename=""
  local distro_id=""

  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    codename="${VERSION_CODENAME:-}"
    distro_id="${ID:-}"
  fi

  if [[ "${distro_id}" != "ubuntu" ]]; then
    print_error "当前系统不是 Ubuntu（检测到 ID=${distro_id:-unknown}），脚本已退出。"
    exit 1
  fi

  if [[ -z "${codename}" ]] && command -v lsb_release >/dev/null 2>&1; then
    codename="$(lsb_release -sc 2>/dev/null || true)"
  fi

  if [[ -z "${codename}" ]]; then
    print_error "无法自动识别 Ubuntu 发行版代号（VERSION_CODENAME/lsb_release 均失败）。"
    exit 1
  fi

  printf '%s\n' "${codename}"
}

select_mirror() {
  local selected_mirror=""

  while true; do
    cat >&2 <<'EOF'
请选择镜像源：
  1 - 阿里云 (aliyun)
  2 - 清华大学 (tsinghua)
EOF
    read -r -p "请输入序号 [1-2]: " choice

    case "${choice}" in
      1)
        selected_mirror="https://mirrors.aliyun.com/ubuntu/"
        break
        ;;
      2)
        selected_mirror="https://mirrors.tuna.tsinghua.edu.cn/ubuntu/"
        break
        ;;
      *)
        print_warn "无效输入，请输入 1 或 2。"
        ;;
    esac
  done

  printf '%s\n' "${selected_mirror}"
}

backup_sources_list() {
  if [[ -f "${SOURCES_LIST}" ]]; then
    cp -f "${SOURCES_LIST}" "${SOURCES_BACKUP}"
    print_info "已备份 ${SOURCES_LIST} -> ${SOURCES_BACKUP}"
  else
    print_warn "${SOURCES_LIST} 不存在，跳过该文件备份。"
  fi
}

write_ubuntu_sources() {
  local codename="$1"
  local mirror="$2"
  local suites
  local tmp_existing
  local tmp_commented
  suites="${codename} ${codename}-security ${codename}-updates ${codename}-backports"

  tmp_existing="$(mktemp)"
  tmp_commented="$(mktemp)"

  if [[ -f "${UBUNTU_SOURCES}" ]]; then
    # 去掉上一次脚本生成的配置块，避免重复追加。
    awk '
      /^# BEGIN APT_CHANGER GENERATED$/ { in_generated=1; next }
      /^# END APT_CHANGER GENERATED$/   { in_generated=0; next }
      !in_generated { print }
    ' "${UBUNTU_SOURCES}" > "${tmp_existing}"

    # 将原有有效配置行注释掉，保留空行和已有注释。
    awk '
      /^[[:space:]]*$/ { print; next }
      /^[[:space:]]*#/ { print; next }
      { print "# " $0 }
    ' "${tmp_existing}" > "${tmp_commented}"

    cat "${tmp_commented}" > "${UBUNTU_SOURCES}"
  else
    : > "${UBUNTU_SOURCES}"
  fi

  cat >> "${UBUNTU_SOURCES}" <<EOF
# BEGIN APT_CHANGER GENERATED
Types: deb
URIs: ${mirror}
Suites: ${suites}
Components: main restricted universe multiverse
Signed-By: ${SIGNED_BY}
# END APT_CHANGER GENERATED
EOF

  rm -f "${tmp_existing}" "${tmp_commented}"
  print_info "已写入 ${UBUNTU_SOURCES}"
}

write_legacy_sources_list() {
  local codename="$1"
  local mirror="$2"
  local tmp_existing
  local tmp_processed

  if [[ ! -f "${SOURCES_LIST}" ]]; then
    print_error "${SOURCES_LIST} 不存在，无法继续进行 Ubuntu ${codename} 的换源。"
    exit 1
  fi

  tmp_existing="$(mktemp)"
  tmp_processed="$(mktemp)"

  # 去掉上一次脚本生成的配置块，避免重复追加。
  awk '
    /^# BEGIN APT_CHANGER GENERATED$/ { in_generated=1; next }
    /^# END APT_CHANGER GENERATED$/   { in_generated=0; next }
    !in_generated { print }
  ' "${SOURCES_LIST}" > "${tmp_existing}"

  # 仅注释 Ubuntu 官方源，保留第三方源与已有注释。
  awk '
    /^[[:space:]]*$/ { print; next }
    /^[[:space:]]*#/ { print; next }
    /^[[:space:]]*deb(-src)?[[:space:]]+/ {
      if ($0 ~ /(archive|security|[A-Za-z0-9.-]+)\.ubuntu\.com\/ubuntu/ ||
          $0 ~ /ports\.ubuntu\.com\/ubuntu-ports/) {
        print "# " $0
        next
      }
    }
    { print }
  ' "${tmp_existing}" > "${tmp_processed}"

  cat "${tmp_processed}" > "${SOURCES_LIST}"

  cat >> "${SOURCES_LIST}" <<EOF
# BEGIN APT_CHANGER GENERATED
deb ${mirror} ${codename} main restricted universe multiverse
deb-src ${mirror} ${codename} main restricted universe multiverse
deb ${mirror} ${codename}-updates main restricted universe multiverse
deb-src ${mirror} ${codename}-updates main restricted universe multiverse
deb ${mirror} ${codename}-backports main restricted universe multiverse
deb-src ${mirror} ${codename}-backports main restricted universe multiverse
deb ${mirror} ${codename}-security main restricted universe multiverse
deb-src ${mirror} ${codename}-security main restricted universe multiverse
# END APT_CHANGER GENERATED
EOF

  rm -f "${tmp_existing}" "${tmp_processed}"
  print_info "已写入 ${SOURCES_LIST}"
}

main() {
  print_start "权限检查"
  require_root
  print_success "权限检查完成!"

  print_start "Ubuntu发行版本自检"
  local codename
  codename="$(detect_codename)"
  print_info "检测到 Ubuntu 发行版本为：${codename}"

  print_start "镜像源配置"
  local mirror
  mirror="$(select_mirror)"
  print_info "已选择镜像：${mirror}"

  print_start "备份原软件源"
  backup_sources_list

  print_start "镜像源配置写入"
  case "${codename}" in
    bionic|focal)
      print_info "检测到 Ubuntu 18.04/20.04 系列，使用 ${SOURCES_LIST} 方式写入。"
      write_legacy_sources_list "${codename}" "${mirror}"
      ;;
    *)
      print_info "检测到 Ubuntu 22.04+ 系列，使用 ${UBUNTU_SOURCES} 方式写入。"
      write_ubuntu_sources "${codename}" "${mirror}"
      ;;
  esac

  print_start "更新软件库"
  apt update
}

main "$@"
