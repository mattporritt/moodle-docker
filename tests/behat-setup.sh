#!/usr/bin/env bash
set -e
basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"

export MOODLE_DOCKER_WWWROOT="${basedir}/moodle"

if [ -d "${MOODLE_DOCKER_WWWROOT}/public" ];
then
    :
else
    :
fi

if [ "$SUITE" != "behat" ]; then
    echo "Error, unknown suite '$SUITE'"
    exit 1
fi

echo "Pulling docker images"
$basedir/bin/moodle-docker-compose pull
echo "Initialising serial Behat environment"
$basedir/bin/behat-init serial
