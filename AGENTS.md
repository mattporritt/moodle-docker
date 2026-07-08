# AGENTS.md

Guidance for agents working in this repository.

## Project Shape

This repository is a Docker Compose based Moodle development and test environment. It is not the Moodle LMS source tree itself. The Moodle checkout is expected to live outside this repo, or in `./moodle` for CI-style runs, and is mounted into the `webserver` container through `MOODLE_DOCKER_WWWROOT`.

Important components:

- `bin/moodle-docker-compose` builds the effective Docker Compose command from `.env`, required compose fragments, optional service fragments, and `local.yml` if present.
- `base.yml` defines the custom Moodle webserver, database dependency, external test files service, Keycloak, and the default network.
- `db.*.yml` and `db.*.port.yml` select database engines and optional host port exposure.
- `selenium.*.yml` and `selenium.grid.yml` select browser test services for Behat.
- `moodle-app*.yml` adds Moodle app testing services when Chrome and app variables are set.
- `service.mail.yml`, `matrix-mock.yml`, `bbb-mock.yml`, `mlbackend.yml`, and `phpunit-external-services.yml` add optional support services.
- `moodle_dev/Dockerfile` builds the local `mattp:moodle_dev` Apache/PHP image used by `base.yml`.
- `config.docker-template.php` is copied into the Moodle checkout as `config.php`.
- `tests/*.sh` are CI-oriented setup, test, and teardown wrappers.

## Environment Model

Use `.env.example` as the template for local environment variables. The real `.env` is intentionally ignored.

Required baseline variables:

- `MOODLE_DOCKER_WWWROOT`: absolute path to the Moodle checkout.
- `MOODLE_DOCKER_DB`: one of the supported database fragments, such as `pgsql`, `mysql`, `mariadb`, `mssql`, or `oracle`.
- `COMPOSE_PROJECT_NAME`: stable compose project name for the environment.
- `MOODLE_DOCKER_DBNAME`, `MOODLE_DOCKER_DBUSER`, `MOODLE_DOCKER_DBPASS`: database credentials consumed by `config.docker-template.php`.

Common optional variables:

- `MOODLE_DOCKER_PHP_VERSION`: PHP version for upstream Moodle images where supported.
- `MOODLE_DOCKER_DB_VERSION`: database image version override.
- `MOODLE_DOCKER_WEB_PORT`: exposes Apache HTTP through `webserver.port.yml`.
- `MOODLE_DOCKER_DB_PORT`: exposes the selected DB to the host.
- `MOODLE_DOCKER_BROWSER`: `firefox` or `chrome`, optionally with a Selenium tag such as `firefox:4`.
- `MOODLE_DOCKER_BEHAT_MODE`: `serial` or `parallel`.
- `MOODLE_DOCKER_BEHAT_PARALLEL`: node count for parallel Firefox Behat.
- `MOODLE_DOCKER_MATRIX_MOCK`, `MOODLE_DOCKER_BBB_MOCK`, `MOODLE_DOCKER_MLBACKEND`, `MOODLE_DOCKER_PHPUNIT_EXTERNAL_SERVICES`: enable optional service fragments.

Do not commit `.env`, generated certificates, local database state, or generated Moodle checkouts.

## Local Operation

Use the wrapper rather than calling `docker compose` directly, because it applies the repo's compose fragments and environment defaults:

```sh
./bin/moodle-docker-compose up -d
./bin/moodle-docker-compose ps
./bin/moodle-docker-compose logs webserver
./bin/moodle-docker-compose down
```

To build the custom webserver image used by this fork:

```sh
docker build -t "mattp:moodle_dev" moodle_dev
```

For a first install, copy `config.docker-template.php` into the Moodle checkout as `config.php`, start containers, wait for the database when needed, then run Moodle's CLI installer inside `webserver`.

## Testing

Prefer the existing scripts and wrappers.

CI-style integration smoke:

```sh
export MOODLE_DOCKER_WWWROOT="$PWD/moodle"
export MOODLE_DOCKER_DB=pgsql
tests/integration-setup.sh
tests/integration-test.sh
tests/integration-teardown.sh
```

PHPUnit:

```sh
export SUITE=phpunit
tests/phpunit-setup.sh
tests/phpunit-test.sh
tests/phpunit-teardown.sh
```

Full PHPUnit with external services:

```sh
export SUITE=phpunit-full
tests/phpunit-setup.sh
tests/phpunit-test.sh
tests/phpunit-teardown.sh
```

Behat:

```sh
export SUITE=behat
tests/behat-setup.sh
tests/behat-test.sh
tests/behat-teardown.sh
```

Direct Behat helpers:

```sh
./bin/behat-init serial
./bin/behat-run serial --tags=@auth_manual
./bin/behat-init parallel
./bin/behat-run parallel --tags=@auth_manual
```

Parallel Behat currently supports Firefox only. `bin/moodle-docker-wait-for-selenium` detects `serial` versus `parallel` mode and checks the appropriate Selenium endpoint from inside the `webserver` container.

When generating and testing temporary smoke test files, put them under `/_smoke_test` at the repository root. Keep generated smoke artifacts out of committed changes.

## Development Notes

- Prefer `rg` for searching and inspect shell scripts before changing compose behavior.
- Keep compose changes narrowly scoped; most functionality is added by layering small YAML fragments.
- Preserve the wrapper behavior in `bin/moodle-docker-compose`: it is the compatibility layer for Docker Compose v2/v5, database selection, browser selection, optional services, macOS volume options, and local overrides.
- Be careful with `local.yml`: it is intentionally local-only and should remain ignored.
- Do not make destructive Docker changes such as deleting volumes unless the user explicitly asks.
- If tests need network access for Docker image pulls, dependency installs, or GitHub clones, ask for approval when the sandbox blocks them.
- Use `shellcheck` style reasoning for Bash edits even if `shellcheck` is not installed: quote paths, preserve `set -e` or `set -euo pipefail` behavior, and avoid Bash features that break the existing scripts' assumptions.
- This repo supports both old and current Moodle branches, so avoid assuming a single Moodle directory layout. Existing scripts check for `public/admin/...` versus `admin/...`; preserve that pattern.
