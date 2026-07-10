# Quick Start

Copy-paste commands for day-to-day work with moodle-docker instances.
All commands are run from this repository's root (`~/projects/moodle-docker`)
unless noted. For the full explanation of the multi-instance model see
"Multiple Instances" in the [README](README.md).

## The instance model in one paragraph

Each Moodle checkout on disk maps to its own container group ("instance"),
named after the checkout folder: `~/projects/moodle` is the default instance
(project `moodlemaster`, site `https://webserver/`, IP `127.0.0.1`) and
`~/projects/moodle2` is instance `moodle2` (project `moodlemaster2`, site
`https://webserver2/`, IP `127.0.0.2`), and so on. You select an instance by
prefixing commands with `MOODLE_DOCKER_INSTANCE=<name>`; no prefix means the
default instance. The agent harnesses (`claude/`, `codex/`, `copilot/`,
`gemini/` inside each checkout) set the variable automatically, so their
`./bin/*` wrappers always talk to their own checkout's containers.

## Start up an instance

```bash
# Default instance (~/projects/moodle):
bin/moodle-docker-compose up -d

# A named instance:
MOODLE_DOCKER_INSTANCE=moodle2 bin/moodle-docker-compose up -d

# Wait until the database is ready to accept commands:
MOODLE_DOCKER_INSTANCE=moodle2 bin/moodle-docker-wait-for-db
```

Instances are independent — starting or stopping one never affects the others.

## Tear down an instance

```bash
# Stop and remove the containers (data in docker volumes survives):
MOODLE_DOCKER_INSTANCE=moodle2 bin/moodle-docker-compose down

# Stop and remove containers AND volumes (destroys that instance's database):
MOODLE_DOCKER_INSTANCE=moodle2 bin/moodle-docker-compose down -v
```

## Status, logs, shell

```bash
bin/moodle-docker-instance list                                   # all instances at a glance
MOODLE_DOCKER_INSTANCE=moodle2 bin/moodle-docker-compose ps       # one instance's containers
MOODLE_DOCKER_INSTANCE=moodle2 bin/moodle-docker-compose logs -f webserver
MOODLE_DOCKER_INSTANCE=moodle2 bin/moodle-docker-compose exec webserver /bin/bash
```

## Install Moodle in an instance

Run after the containers are up and the DB is ready (fresh install, or again
after a `down -v`). The CLI installer lives at `admin/cli/install_database.php`
on all current branches:

```bash
MOODLE_DOCKER_INSTANCE=moodle2 bin/moodle-docker-compose exec webserver \
  php admin/cli/install_database.php \
  --agree-license \
  --fullname="Moodle 2" \
  --shortname="docker_moodle2" \
  --summary="Moodle dev site" \
  --adminpass="test" \
  --adminemail="you@example.com"
```

Then log in at that instance's URL (e.g. `https://webserver2/`) as
`admin` / `test`.

If the checkout has an agent harness cloned into it, you can use its wrapper
instead — it detects the CLI path and takes the admin credentials from the
harness env file (`MOODLE_ADMIN_USERNAME` / `MOODLE_ADMIN_PASSWORD`):

```bash
cd ~/projects/moodle2/claude && ./bin/install
```

To wipe and reinstall an instance from scratch:

```bash
MOODLE_DOCKER_INSTANCE=moodle2 bin/moodle-docker-compose down -v
MOODLE_DOCKER_INSTANCE=moodle2 bin/moodle-docker-compose up -d
MOODLE_DOCKER_INSTANCE=moodle2 bin/moodle-docker-wait-for-db
# ... then the install command above
```

## Set up a new instance (example: moodle3)

One-time prerequisites (already true if any instance works on this machine):
the `mattp:moodle_dev` image is built, the root CA exists in
`moodle_dev/assets/certs/` and is trusted by your keychain/browser
(see "SSL Setup" in the README).

1. Clone Moodle and add the config file. The config template needs **no
   editing** — it derives the site URL, DB settings, and hostnames from the
   container environment:

```bash
git clone git@github.com:moodle/moodle.git ~/projects/moodle3
cp ~/projects/moodle-docker/config.docker-template.php ~/projects/moodle3/config.php
```

2. Scaffold the instance. This allocates the next loopback IP and subnet,
   writes `instances/moodle3/.env`, generates TLS certs for
   `webserver3`/`keycloak3` signed by the existing root CA, and prepares a
   private Keycloak data directory. `--apply-network` runs the sudo steps
   (loopback alias + `/etc/hosts` entry) for you:

```bash
bin/moodle-docker-instance create ~/projects/moodle3 --apply-network
```

3. (Recommended on macOS) Make the loopback alias survive reboots:

```bash
sudo cp instances/moodle3/loopback.plist /Library/LaunchDaemons/com.moodledocker.loopback.moodle3.plist
sudo launchctl load /Library/LaunchDaemons/com.moodledocker.loopback.moodle3.plist
```

4. Start it and install Moodle:

```bash
MOODLE_DOCKER_INSTANCE=moodle3 bin/moodle-docker-compose up -d
MOODLE_DOCKER_INSTANCE=moodle3 bin/moodle-docker-wait-for-db
MOODLE_DOCKER_INSTANCE=moodle3 bin/moodle-docker-compose exec webserver \
  php admin/cli/install_database.php --agree-license --fullname="Moodle 3" \
  --shortname="docker_moodle3" --summary="Moodle dev site" \
  --adminpass="test" --adminemail="you@example.com"
```

The site is now at `https://webserver3/` (no certificate warnings — the cert
chains to the CA you already trust) and Keycloak at `https://keycloak3:8443/`.

5. (Optional) Add an agent harness to the checkout. Clone it inside the
   checkout and copy the env examples; **leave `MOODLE_DIR` and
   `MOODLE_DOCKER_INSTANCE` unset** in the env file so the harness derives
   them from its location:

```bash
git clone git@git.in.moodle.com:matt.porritt/moodle_claude.git ~/projects/moodle3/claude
cd ~/projects/moodle3/claude
cp .claude.env.example .claude.env          # edit secrets/credentials as needed
cp .claude.identity.example .claude.identity
./bin/doctor
```

Every `./bin/*` command in that clone now targets the `moodlemaster3`
containers automatically.

6. (Optional) If the instance needs Keycloak SSO, configure the OAuth2 issuer
   in that Moodle as `https://keycloak3:8443/realms/moodle/` — i.e. always the
   instance's own Keycloak hostname (see "Keycloak IdP Setup" in the README
   for the full walkthrough).

### Config changes summary for a new instance

| File | Change |
|---|---|
| `<checkout>/config.php` | copy of `config.docker-template.php`, unedited |
| `instances/<name>/.env` | generated by the scaffold — do not create by hand |
| `/etc/hosts` | `127.0.0.N  webserverN keycloakN` (scaffold prints/applies) |
| harness `.<agent>.env` | copy of the example; leave `MOODLE_DIR` unset |
| base `.env` | untouched — it describes the default instance only |

## Remove an instance

```bash
# Stops containers, deletes instances/moodle3/ state, prints the sudo
# commands to undo the /etc/hosts entry and loopback alias.
bin/moodle-docker-instance rm moodle3          # keep docker volumes
bin/moodle-docker-instance rm moodle3 --purge  # also delete volumes/database
```

## Troubleshooting

- **`https://webserverN/` does not resolve** — the `/etc/hosts` entry or
  loopback alias is missing: `bin/moodle-docker-instance network-setup <name>`
  prints the required commands.
- **Port binding fails on `up` after a reboot** — the loopback alias is gone;
  re-add it (`sudo ifconfig lo0 alias 127.0.0.N up`) or install the launchd
  plist (step 3 above).
- **Browser certificate warnings** — trust the root CA:
  `sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" moodle_dev/assets/certs/ca.pem`
  (Firefox needs a separate import; see "SSL Setup" in the README).
- **Which instance am I talking to?** — `bin/moodle-docker-instance list`
  shows name, IP, compose project, and running container count. Container
  names are prefixed by the project, e.g. `moodlemaster3-webserver-1`.
