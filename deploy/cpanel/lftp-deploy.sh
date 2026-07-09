#!/usr/bin/env bash
# XMONEY cPanel deploy via lftp (explicit FTPS / AUTH TLS on port 21).
# Uploads the built package folder to public_html/.
set -euo pipefail

: "${FTP_HOST:?FTP_HOST is required}"
: "${FTP_USERNAME:?FTP_USERNAME is required}"
: "${FTP_PASSWORD:?FTP_PASSWORD is required}"

FTP_PORT="${FTP_PORT:-21}"
FTP_MODE="${FTP_MODE:-ftps}"
DRY_RUN="${DRY_RUN:-false}"
LOCAL_DIR="${LOCAL_DIR:-deploy/cpanel/dist/xmoney-cpanel-package}"
REMOTE_DIR="${FTP_REMOTE_PATH:-/public_html}"

REMOTE_DIR="$(echo -n "$REMOTE_DIR" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s#/$##')"
case "$REMOTE_DIR" in
  public_html|/public_html|/home/smartdms/public_html)
    REMOTE_DIR="/public_html"
    ;;
  "")
    REMOTE_DIR="/public_html"
    ;;
  /*) ;;
  *) REMOTE_DIR="/${REMOTE_DIR}" ;;
esac

if [[ ! -d "$LOCAL_DIR" ]]; then
  echo "::error::Package folder missing: ${LOCAL_DIR}"
  exit 1
fi

LOCAL_DIR="$(cd "$LOCAL_DIR" && pwd)"

run_lftp() {
  local mode="$1"
  local ssl_allow="false"
  local ssl_force="false"
  local ssl_protect="false"

  if [[ "$mode" == "ftps" ]]; then
    ssl_allow="true"
    ssl_force="true"
    ssl_protect="true"
  fi

  local dry_flag=""
  if [[ "$DRY_RUN" == "true" ]]; then
    dry_flag="--dry-run"
  fi

  echo "lftp ${mode} → ftp://${FTP_HOST}:${FTP_PORT}${REMOTE_DIR}/"
  echo "local: ${LOCAL_DIR}"

  lftp -u "${FTP_USERNAME}","${FTP_PASSWORD}" -p "${FTP_PORT}" "ftp://${FTP_HOST}" <<LFTP_EOF
set cmd:fail-exit yes;
set net:timeout 90;
set net:max-retries 3;
set net:reconnect-interval-base 5;
set ftp:passive-mode true;
set ftp:prefer-epsv false;
set ftp:use-feat false;
set ftp:use-mdtm false;
set ssl:verify-certificate no;
set ftp:ssl-allow ${ssl_allow};
set ftp:ssl-force ${ssl_force};
set ftp:ssl-protect-data ${ssl_protect};
lcd ${LOCAL_DIR};
cd ${REMOTE_DIR};
mirror -R --parallel=3 --verbose --ignore-time ${dry_flag} \
  --exclude-glob .git/ \
  --exclude-glob .github/ \
  --exclude-glob node_modules/ \
  --exclude-glob '*.zip' \
  ./ .;
bye
LFTP_EOF
}

attempt_modes() {
  local -a modes=()
  if [[ "$FTP_MODE" == "auto" ]]; then
    modes=(ftps plain)
  else
    modes=("$FTP_MODE")
  fi

  local mode
  for mode in "${modes[@]}"; do
    echo "=== XMONEY deploy attempt: ${mode} ==="
    if run_lftp "$mode"; then
      echo "XMONEY deploy OK (${mode})"
      return 0
    fi
    echo "::warning::Deploy failed for mode ${mode}"
  done
  return 1
}

if ! attempt_modes; then
  echo "::error::XMONEY FTP deploy failed. Check FTP_HOST, FTP_USERNAME, FTP_PASSWORD, FTP_REMOTE_PATH=/public_html/"
  exit 1
fi
