# Shared environment loader for the moodle-docker bin scripts.
#
# Usage (from a script that has computed ${basedir}):
#   source "${basedir}/bin/moodle-docker-env.sh"
#   moodle_docker_load_env "${basedir}"
#
# Loads ${basedir}/.env, then overlays ${basedir}/instances/${MOODLE_DOCKER_INSTANCE}/.env
# when MOODLE_DOCKER_INSTANCE names a non-default instance. The default instance is
# the one described by the base .env (identified by the basename of its
# MOODLE_DOCKER_WWWROOT), so existing single-instance setups behave exactly as before.

moodle_docker_load_env() {
    local basedir="$1"

    if [ -f "${basedir}/.env" ]; then
        set -a
        # shellcheck disable=SC1091
        . "${basedir}/.env"
        set +a
    fi

    local instance="${MOODLE_DOCKER_INSTANCE:-}"
    local default_instance
    default_instance="$(basename "${MOODLE_DOCKER_WWWROOT:-}")"

    if [ -n "${instance}" ] && [ "${instance}" != "${default_instance}" ]; then
        local overlay="${basedir}/instances/${instance}/.env"
        if [ ! -f "${overlay}" ]; then
            echo "Error: unknown moodle-docker instance '${instance}' (missing ${overlay})." >&2
            echo "Create it with: ${basedir}/bin/moodle-docker-instance create <path-to-moodle-checkout>" >&2
            exit 1
        fi
        set -a
        # shellcheck disable=SC1090
        . "${overlay}"
        set +a
    fi

    export MOODLE_DOCKER_INSTANCE="${instance:-${default_instance}}"
}
