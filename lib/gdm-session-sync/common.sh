# Shared helpers for gdm-session-sync (sourced, not executed).
# Distro-agnostic: wheel|sudo|admin, themes/icons under /usr/local and /usr/share.

USER_WAIT_TIMEOUT="${USER_WAIT_TIMEOUT:-60}"
# Coalesce bursts of dconf/inotify events into one sync.
DEBOUNCE_SECS="${DEBOUNCE_SECS:-0.5}"

# debounce_run PID_VAR command [args...]
# Restarts a sleep+command timer; only the last burst runs after DEBOUNCE_SECS.
debounce_run() {
  local -n _debounce_pid="$1"
  shift
  if [[ -n "${_debounce_pid:-}" ]] && kill -0 "${_debounce_pid}" 2>/dev/null; then
    kill "${_debounce_pid}" 2>/dev/null || true
    wait "${_debounce_pid}" 2>/dev/null || true
  fi
  (
    sleep "${DEBOUNCE_SECS}"
    "$@"
  ) &
  _debounce_pid=$!
}

find_active_user() {
  local sid active user class
  while read -r sid _; do
    [[ -n "${sid}" ]] || continue
    active="$(loginctl show-session "${sid}" -p Active --value 2>/dev/null || true)"
    user="$(loginctl show-session "${sid}" -p Name --value 2>/dev/null || true)"
    class="$(loginctl show-session "${sid}" -p Class --value 2>/dev/null || true)"
    if [[ "${active}" == "yes" && "${class}" == "user" && -n "${user}" ]]; then
      printf '%s\n' "${user}"
      return 0
    fi
  done < <(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1}')
  return 1
}

wait_user() {
  active_user="$(find_active_user || true)"
  local waited=0
  while [[ -z "${active_user}" && "${waited}" -lt "${USER_WAIT_TIMEOUT}" ]]; do
    sleep 2
    waited=$((waited + 2))
    active_user="$(find_active_user || true)"
  done
}

user_is_admin() {
  local user="$1"
  id -nG "${user}" 2>/dev/null | tr ' ' '\n' | grep -qxE 'wheel|sudo|admin'
}

validate_user() {
  local user="$1"
  [[ -n "${user}" ]] || return 1
  [[ "${user}" != "gdm" ]] || return 1
  loginctl show-user "${user}" -p Display --value 2>/dev/null | grep -q . || return 1
  user_is_admin "${user}"
}

user_runtime() {
  local uid="$1"
  printf '%s' "${XDG_RUNTIME_DIR:-/run/user/${uid}}"
}

as_user() {
  local user="$1" uid
  uid="$(id -u "${user}")"
  shift
  local run
  run="$(user_runtime "${uid}")"
  runuser -u "${user}" -- env \
    XDG_RUNTIME_DIR="${run}" \
    DBUS_SESSION_BUS_ADDRESS="unix:path=${run}/bus" \
    "$@"
}

get_user_gsettings() {
  local user="$1" key="$2" uid
  uid="$(id -u "${user}")"
  [[ -e "$(user_runtime "${uid}")/bus" ]] || return 1
  as_user "${user}" gsettings get org.gnome.desktop.interface "${key}" 2>/dev/null || return 1
}

unquote_gvariant() {
  local raw="$1"
  raw="${raw#\'}"
  raw="${raw%\'}"
  printf '%s\n' "${raw}"
}

# Resolve a theme/icon name against system data dirs (/usr/local first for Silverblue).
theme_data_dirs() {
  local d
  for d in /usr/local/share /usr/share; do
    printf '%s\n' "${d}"
  done
  if [[ -n "${XDG_DATA_DIRS:-}" ]]; then
    local IFS=':'
    for d in ${XDG_DATA_DIRS}; do
      [[ -n "${d}" ]] && printf '%s\n' "${d}"
    done
  fi
}

theme_exists() {
  local kind="$1" name="$2" d sub
  case "${kind}" in
    gtk-theme) sub="themes" ;;
    icon-theme|cursor-theme) sub="icons" ;;
    *) return 1 ;;
  esac
  while read -r d; do
    [[ -d "${d}/${sub}/${name}" ]] && return 0
  done < <(theme_data_dirs)
  return 1
}

resolve_theme_name() {
  local kind="$1" raw="$2" name
  [[ -z "${raw}" ]] && return 1
  name="$(unquote_gvariant "${raw}")"
  theme_exists "${kind}" "${name}" || return 1
  printf '%s\n' "${name}"
}

wait_session_bus() {
  local uid="$1" i
  for i in 1 2 3 4 5; do
    [[ -e "$(user_runtime "${uid}")/bus" ]] && return 0
    sleep 1
  done
  [[ -e "$(user_runtime "${uid}")/bus" ]]
}

# Common startup: set active_user or exit 0.
bootstrap_active_admin_user() {
  wait_user
  validate_user "${active_user:-}" || exit 0
  local uid
  uid="$(id -u "${active_user}" 2>/dev/null || true)"
  [[ -n "${uid}" ]] || exit 0
  wait_session_bus "${uid}" || exit 0
}
