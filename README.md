# moodle-docker: Docker Containers for Moodle Developers
# Overview
These instructions cover setting up a Moodle (omnibus) development environment. It uses Docker to run Moodle LMS and the related services for a development environment. It is a fork of: https://github.com/moodlehq/moodle-docker but with additions for SSO and Matrix.

The services set up are:
* Moodle LMS
* Postgres Database server
* Mailhog
* Keycloak
* Matrix-synapase Mock

Once the following steps are complete the sites can be accessed at the following URLs:
* Moodle LMS: https://webserver/
* Keycloak: https://keycloak:8443/
* Mailhog: http://webserver:1234/_/mail
* Matrix-synapase Mock: http://elementmock:8001 (Make sure port 8001 is not used)

For Matrix-synapase Mock, there will not be any settings needed and will be available once the "Build and Install" step is done.

The entire setup process should take about: 45 minutes

# MacOS Host Setup
These are the steps that need to be done to set up the development environment on a MacOS based machine.
## Homebrew Setup
Home brew is a package manager for OSX, it makes it easier to install things.<br/>
To add it to a Mac:<br/>
`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

There are some helpful utilities we want to install initially:<br/>
`brew install libpq`
`echo 'export PATH="/opt/homebrew/opt/libpq/bin:$PATH"' >> ~/.zshrc`

Next install openssl on mac using homebrew, run the following command:<br/>
`brew install openssl`

## Docker Setup
Best place to go for both intel and apple silicon is here: https://docs.docker.com/desktop/install/mac-install/

On Mac we need to enable a couple of experimental settings to improve performance.<br/>
In Docker desktop on Mac:
* Go to settings > General
* Enable: Use virtualization framework
* Enable: VirtioFS accelerated directory sharing
* Restart the host machine.

## PHP
We use homebrew to install the required versions of PHP we need for development on the host machine.<br/>
`brew install php@7.4`<br/>
`brew install php@8.0`

The php.ini and php-fpm.ini file can be found in:<br/>
`/usr/local/etc/php/7.4/`

Switch from 7.4 to 8.0:<br/>
`brew unlink php@7.4`<br/>
`brew link php@8.0 --force`

## Moodle LMS Code
The following steps are required to get the Moodle code locally and initial setups.<br/>
Start by cloning the Moodle codebase locally to the host:</br>
`git clone https://github.com/moodle/moodle.git`

You can then checkout any branch you want to work with.

## Node Setup
Node is required for js compilation etc.<br/>
First we install NVM:
`curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash`

Then we set up node, run the following:<br/>
`cd moodle_local #Or the location where you cloned the Moodle code`<br/>
`nvm install`<br/>
`nvm use`

nvm use will also output the node version, use it in the following command:<br/>
`nvm alias default v16.17.0`

Next run the package install:<br/>
`npm install`

# Moodle Docker
Moodle HQ have been awesome enough to create a set of Docker containers and a Docker compose setup that automates much of the setup and configuration of running Moodle in Docker.

We’ve further extended this work with a “Custom setup” that pre-builds some of the tools and setup options we use in our development workflow. This document contains instructions on how to use both methods.

The aim of the custom setup is to decrease the setup time for a Moodle development workflow and to have commonly used components pre-built.

## Initial steps
We start by cloning our fork of the Moodle Docker repository:<br/>
`git clone git@github.com:mattporritt/moodle-docker.git`

Checkout out the branch: `omnibus`

Add a sample config.php file to Moodle code:<br/>
`cp moodle-docker/config.docker-template.php moodle_local/config.php`

Copy the sample environment file:<br/>
`cp moodle-docker/.env.example moodle-docker/.env`

Update the MOODLE_DOCKER_WWWROOT variable in the .env file to the location of the Moodle code on the host.

## Host file
To make it easier to access the sites that have been setup and to allow correct SSO workflows, the hosts file on the machine running the docker containers needs to be updated. With extra services added to the localhost entry.

Update your local hosts file: `/etc/hosts` to include the following names for the localhost IP (127.0.0.1):
* Keycloak
* Webserver (Moodle)
* Elementmoc (Matrix-synapse Mock)

If you haven’t already customised your hosts file the line should look like:<br/>
`127.0.0.1   	localhost webserver keycloak elementmock`

## SSL Setup
Next make the self signed certs so we can run Moodle and associated services over ssl/tls. This is required to setup SSO.<br/>
There is a helper script that creates the root CA and dev certificates and keys.

Change to the directory of the script first:<br/>
`cd moodle-docker/moodle_dev/assets/certs`

Then run it for each service that we require certificates for. The first time the script is run it will generate a root cert and key. After that it will re-use the root cert and just make the certs required for each service we want to run using SSL/TLS.

Run the script:<br/>
`./createcerts.sh webserver`

Then run it for each additional service we need<br/>
`./createcerts.sh keycloak`

These certs will be automatically loaded into the containers. We only need to generate them.

Next we add the root CA, this is to remove the browser self signed errors.<br/>
To add the root CA to the Mac OS keychain. Run this on this host machine:<br/>
`sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" ca.pem`

To add the certificate to firefox to get rid of the self signed warning. (Chrome should “just work”):<br/>
1. Run Firefox.
2. Position to Settings > Privacy & Security.
3. Under Certificates, click "View Certificates..."
4. In the Certificate Manager, click the Authorities tab.
5. Click the Import button to import your certificate.
6. You might be prompted to set the trust level upon importing the certificate. ...
7. Restart Firefox.

## Build and install
Next we need to build our version of the moodle dev container:<br/>
`cd moodle-docker/moodle_dev`<br/>
`docker build -t "mattp:moodle_dev" .`

Set the environment variable if you want to run Matrix test mock server
`export MOODLE_DOCKER_MATRIX_MOCK=true`

Finally, actually start the services:<br/>
`cd moodle-docker/bin`<br/>
`./moodle-docker-compose up -d`

Next we need to install Moodle:<br/>
`./moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="Moodle Master" --shortname="docker_moodle" --summary="Moodle dev site" --adminpass="test" --adminemail="you@gmail.com"`

# PHPStorm Setup
Next we set up profiling in PHPStorm. Go to your PhpStorm and go to:<br/>
`Run -> Edit configurations`<br/>
and select new:<br/>
`PHP Remote Debug`

`Name: "xdebug webserver" (or what you want to)`<br/>
`Configuration: check "Filter debug connection by IDE key"`<br/>
`IDE key(session id): "phpstorm"`<br/>
`Define a new server:`<br/>
`Name: must be "moodle-local"`<br/>
`Host: webserver`<br/>
`Port: Must be the port you're using for the web server. This should be 443`<br/>
`Debugger: use the default (Xdebug)`<br/>
`Check "Use path mappings (...)"`<br/>
`Set for your "Project files" Moodle root the "Absolute path on the server" as "/var/www/html"`<br/>
`Apply and OK on this screen. This screen will be closed.`<br/>
`Apply and OK on the next screen. Settings screen will be closed.`<br/>

Now, test that live debugging works. To do so:<br/>
Put a breakpoint on /index.php file.<br/>
Press telephone icon with a red symbol with title "Start listening for PHP Debug Connections": telephone should appear with some waves now.<br/>

Finally we need to add the xdebug browser extension to Firefox. Go here to install the extension:<br/>
https://addons.mozilla.org/en-US/firefox/addon/xdebug-helper-for-firefox/

Once installed you can enable and disable debugging from Firefox (providing PHP storm is listening.

# Keycloak IdP Setup
This will set up Keycloak as an Identity Provider (IdP) for Moodle. Users will be able to log into Moodle and Element via Keycloak once the following configuration is complete.

## Keycloak
The following steps will set up a Moodle LMS client in Keycloak so users can authenticate to Moodle from Keycloak using OIDC/Oauth.

Access the Moodle realm in Keycloak:<br/>
* First log into Keycloak (https://keycloak:8443/ ) using the admin credentials you defined in the .env file in the root of the moodle-docker project.
* Then click on the link to Keycloak Administration
* Then on the left of the screen change the “Realm Select” drop down menu from master to moodle.

Set up the Moodle client:<br/>
* Click Clients from the Manage menu on the left of the page
* From the list of clients that are displayed click on the “moodle-client” link in the Client ID column
* Click the Credentials tab
* Click the Regenerate button for the Client secret
* Note the Client secret.

We also need to create at least one user in the moodle realm in keycloak. All users that log into Moodle using SSO via Keycloak need an account in the moodle realm.<br/>
To do this:<br/>
* Click Users from the Manage menu on the left of the page
* Click the Add user button
* Set the following settings for the new user:
  - Username
  - Email (can be fake)
  - Set Email verified to true/on
  - First name
  - Last name
* Click the create button

## Moodle
The following steps will set up Moodle LMS as a Service Provider with  Keycloak as an Identity Provider.

As we are using a development environment we need to allow non standard port.<br/>
To do this:<br/>
* Log into the Moodle LMS instance (https://webserver) as an admin.
* Access the HTTP security settings: Site administration > General > HTTP security (https://webserver/admin/settings.php?section=httpsecurity)
* In the “cURL allowed ports list” add the port: 8443 (We are using non standard ports in development)
* Click “Save changes”

Next we need to set up the Oauth2 service for Keycloak in Moodle LMS:<br/>
* Log into the Moodle LMS instance (https://webserver) as an admin.
* Access the OAuth2 services settings: Site administration > Server > OAuth2 services (https://webserver/admin/tool/oauth2/issuers.php )
* Click the “Custom” button for the “Create new service” setting
* Set the following settings:
  - Name to: Keycloak
  - Client ID to: moodle-client
  - Client secret to: the value you noted from keycloak during setup
  - Service base URL to: https://keycloak:8443/realms/moodle/
  - Logo URL to: https://keycloak:8443/resources/u40ce/login/keycloak/img/favicon.ico
  - This service will be used to: Login page and internal services
  - Unselect: Require email validation
  - Select: I understand that disabling email verification can be a security issue.
* Click: Save changes

Next we configure the fields from Keycloak against the Moodle user profile:<br/>
* From the “Edit” column for the Keycloak “service”, click the “Configure user field mappings” icon
* Click the “Create new user field mapping for issuer ‘Keycloak’” button
* Set the following settings
  - External field name to: preferred_username
  - Internal field name  to: username

Finally, we configure the Oauth2 authentication plugin to allow users to log into Moodle LMS using Keycloak:<br/>
* Log into the Moodle LMS instance (https://webserver) as an admin.
* Access the Manage authentication settings: Site administration > Plugins > Authentication >  Manage authentication (https://webserver/admin/settings.php?section=manageauths )
* Enable the Oauth2 authentication plugin
Keycloak users will now be able to use Keycloak SSO to log into Moodle.

# Accessing Sites
Once the above steps are complete the sites can be accessed at the following URLs:
* Moodle LMS: https://webserver/
* Keycloak: https://keycloak:8443/
* Mailhog: http://webserver:1234/_/mail
* Matrix-synapase Mock: http://elementmock:8001

# Multiple Instances
One moodle-docker checkout can run several independent container groups ("instances") at the same time, one per Moodle code checkout. This allows multiple agents or developers to each work on their own issue, in their own checkout, with their own containers, database, Keycloak, and browser-reachable URLs — in parallel.

## How it works
* Each instance is named after its Moodle checkout folder: `~/projects/moodle2` → instance `moodle2`, compose project `moodlemaster2`, hostnames `webserver2` and `keycloak2`.
* The base `.env` describes the default instance (`~/projects/moodle`, project `moodlemaster`, hostnames `webserver`/`keycloak`) and is unchanged.
* Extra instances live in `instances/<name>/` (gitignored): an `.env` overlay, per-instance TLS certs, and private Keycloak state.
* Instance selection happens through the `MOODLE_DOCKER_INSTANCE` environment variable. The bin scripts load the base `.env`, then overlay `instances/$MOODLE_DOCKER_INSTANCE/.env` on top. When the variable is unset (or names the default instance) behaviour is identical to a single-instance setup. The agent harness wrappers (claude/codex/copilot/gemini `bin/*`) export it automatically from their checkout folder name.
* **Networking:** every instance binds its published ports to its own loopback IP — the default instance owns `127.0.0.1`, instance 2 owns `127.0.0.2`, and so on. Because each instance has its own IP, all instances keep the *same* ports (443, 8080, 8443, 1234, 5433). `/etc/hosts` maps each instance's hostnames to its IP. This keeps URLs identical inside and outside Docker (e.g. `https://keycloak2:8443` works from your browser *and* from the Moodle container), which is what makes Keycloak OIDC issuer URLs consistent — a requirement for SSO. Inside Docker, each instance gets its own network and subnet (`172.32.238.0/24`, `172.32.239.0/24`, ...), and the webserver/keycloak services carry their instance hostname as a network alias.
* TLS certs for new instances are signed by the same root CA you already trust, so no extra browser/keychain setup is needed.
* All instances share the `mattp:moodle_dev` image — no per-instance rebuild.

Note: as part of this work, all published ports now bind to the instance's loopback IP instead of `0.0.0.0`. If anything on your LAN was connecting to these services, it no longer can.

## Creating an instance
1. Clone Moodle into a new folder and add the config template:
```
git clone git@github.com:moodle/moodle.git ~/projects/moodle2
cp ~/projects/moodle-docker/config.docker-template.php ~/projects/moodle2/config.php
```
(The config template derives the site URL from the instance's hostname automatically — no editing needed.)

2. Scaffold the instance (from the moodle-docker checkout):
```
bin/moodle-docker-instance create ~/projects/moodle2
```
This writes `instances/moodle2/.env`, generates the TLS certs (you will be asked for the root CA passphrase), prepares a private Keycloak data directory with the realm redirect URLs rewritten for `webserver2`, and prints the network setup commands.

3. Apply the network setup (needs sudo — either run the printed commands, or pass `--apply-network` to the create command):
```
sudo ifconfig lo0 alias 127.0.0.2 up
sudo sh -c 'echo "127.0.0.2       webserver2 keycloak2" >> /etc/hosts'
```
The loopback alias does not survive a reboot on macOS. To make it persistent, install the generated launchd daemon:
```
sudo cp instances/moodle2/loopback.plist /Library/LaunchDaemons/com.moodledocker.loopback.moodle2.plist
sudo launchctl load /Library/LaunchDaemons/com.moodledocker.loopback.moodle2.plist
```
(Re-print these steps any time with `bin/moodle-docker-instance network-setup moodle2`.)

4. Start and install as usual, selecting the instance:
```
MOODLE_DOCKER_INSTANCE=moodle2 bin/moodle-docker-compose up -d
MOODLE_DOCKER_INSTANCE=moodle2 bin/moodle-docker-compose exec webserver php public/admin/cli/install_database.php --agree-license --fullname="Moodle 2" --shortname="docker_moodle2" --summary="Moodle dev site" --adminpass="test" --adminemail="you@gmail.com"
```
The site is now at https://webserver2/ and Keycloak at https://keycloak2:8443/. If you use the agent harnesses, clone the wanted agent repo into `~/projects/moodle2/<agent>` and its `./bin/*` commands will target this instance automatically.

If configuring Keycloak SSO for this instance, use `https://keycloak2:8443/realms/moodle/` as the issuer/service base URL (i.e. this instance's Keycloak hostname).

## Managing instances
* `bin/moodle-docker-instance list` — all instances, their IPs, projects, and running container counts.
* `bin/moodle-docker-instance rm moodle2` — stop the containers and delete the instance state (`--purge` also removes its docker volumes). Prints the commands to undo the network setup.
* Host database access is per-IP: `psql -h 127.0.0.2 -p 5433 -U moodle` reaches instance 2's database, `-h 127.0.0.1` the default instance's.
* Behat/PHPUnit work per instance exactly as before; just set `MOODLE_DOCKER_INSTANCE` (or use the harness wrappers): `MOODLE_DOCKER_INSTANCE=moodle2 bin/behat-init serial`.

# PHP Unit Tests
Running unit tests in the docker container is very similar to running them from the command line in a VM.
To initialise phpunit environment:<br/>
`cd bin`<br/>
`./moodle-docker-compose exec webserver php admin/tool/phpunit/cli/init.php`

To run phpunit tests:<br/>
`./moodle-docker-compose exec webserver vendor/bin/phpunit`

# BEHAT Tests
Running behat tests in the docker container is very similar to running them from the command line in a VM.<br/>
To initialise behat environment:<br/>
`./moodle-docker-compose exec webserver php admin/tool/behat/cli/init.php`

To run behat tests:<br/>
`./moodle-docker-compose exec -u www-data webserver php admin/tool/behat/cli/run.php --tags=@auth_manual`

## Serial and parallel Behat modes
This repository now supports two separate Behat execution modes so small local runs and larger parallel runs do not interfere with each other.

Serial mode uses the existing standalone Selenium container and remains the default mode.

Initialise serial Behat:<br/>
`bin/behat-init serial`

Run serial Behat:<br/>
`bin/behat-run serial --tags=@auth_manual`

Parallel mode uses Selenium Grid with a `selenium-hub` container and a scaled `selenium-firefox` node service. Firefox is the only supported browser for parallel mode.

Initialise parallel Behat with the default 4 workers:<br/>
`bin/behat-init parallel`

Run parallel Behat:<br/>
`bin/behat-run parallel --tags='@javascript'`

You can change the parallel worker count with:<br/>
`export MOODLE_DOCKER_BEHAT_PARALLEL=6`

The wrappers set `MOODLE_DOCKER_BEHAT_MODE` for you, start the correct Selenium topology, wait for Selenium to become ready, and then execute Moodle's `init.php` or `run.php`.

Operator note:<br/>
Use serial mode for single features, small tag runs, and debugging because startup is simpler and output is easier to read.<br/>
Use parallel mode for broader Behat subsets and Javascript-heavy runs where setup cost is worth the reduced wall-clock time.<br/>
When switching between serial and parallel modes, prefer the wrapper commands so the old Selenium topology is removed automatically.

If you prefer the raw commands, parallel mode is still just Moodle's native parallel runner:<br/>
`MOODLE_DOCKER_BEHAT_MODE=parallel MOODLE_DOCKER_BEHAT_PARALLEL=4 ./bin/moodle-docker-compose up -d --scale selenium-firefox=4`<br/>
`./bin/moodle-docker-compose exec webserver php public/admin/tool/behat/cli/init.php --parallel=4`<br/>
`./bin/moodle-docker-compose exec -u www-data webserver php public/admin/tool/behat/cli/run.php --tags='@javascript'`

# Mailpit
Mailpit is an email-testing tool with a fake SMTP server underneath. It captures outgoing emails sent to it and provides a web interface for viewing them during development and tests.

To access Mailpit:<br/>
http://webserver:1234/_/mail

# Useful Docker Commands
To access the container directly:<br/>
`./moodle-docker-compose exec -it webserver /bin/bash`

To get container logs (which include apache logs for webserver container:<br/>
`docker logs -f moodlemaster-webserver-1`<br/>
(Container names are prefixed with the instance's compose project name — e.g. `moodlemaster2-webserver-1` for instance `moodle2`.)

To shut things down:<br/>
`./moodle-docker-compose down`

To access the Moodle DB from the host machine:<br/>
`psql -h 127.0.0.1 -p 5433 -U moodle`

To dump the db from the host machine:<br/>
`pg_dump -h 127.0.0.1 -p 5433 -U moodle -Fc moodle > moodle.dump`

To restore the db when none exists:<br/>
`pg_restore -h 127.0.0.1 -p 5433 -U moodle -d moodle moodle.dump`

## Environment variables

You can change the configuration of the docker images by setting various environment variables **before** calling `bin/moodle-docker-compose up`.
When you change them, use `bin/moodle-docker-compose down && bin/moodle-docker-compose up -d` to recreate your environment.

| Environment Variable                      | Mandatory | Allowed values                        | Default value | Notes                                                                        |
|-------------------------------------------|-----------|---------------------------------------|---------------|------------------------------------------------------------------------------|
| `MOODLE_DOCKER_MATRIX_MOCK`               | no        | any value                             | not set       | If set, matrix test mock server is added                                     |
| `MOODLE_DOCKER_BEHAT_MODE`               | no        | `serial`, `parallel`                  | `serial`      | Selects standalone Selenium or Selenium Grid for Behat                       |
| `MOODLE_DOCKER_BEHAT_PARALLEL`           | no        | positive integer                      | `4`           | Default parallel worker count for Behat Grid mode                            |
| `MOODLE_DOCKER_INSTANCE`                 | no        | instance name                         | not set       | Selects an instance overlay from `instances/<name>/.env` (see Multiple Instances) |
| `MOODLE_DOCKER_BIND_IP`                  | no        | loopback IP                           | `127.0.0.1`   | Host IP that all published ports bind to (per-instance loopback alias)       |
| `MOODLE_DOCKER_WEB_HOSTNAME`             | no        | hostname                              | `webserver`   | Instance web hostname; network alias and `$CFG->wwwroot` host                |
| `MOODLE_DOCKER_KEYCLOAK_HOSTNAME`        | no        | hostname                              | `keycloak`    | Instance Keycloak hostname; network alias                                    |
| `MOODLE_DOCKER_SUBNET`                   | no        | CIDR subnet                           | `172.32.238.0/24` | Docker network subnet for the instance                                   |
| `MOODLE_DOCKER_GATEWAY`                  | no        | IP address                            | `172.32.238.1`| Docker network gateway for the instance                                      |
| `MOODLE_DOCKER_CERTS_DIR`                | no        | path                                  | `./moodle_dev/assets/certs` | Directory holding the instance's TLS leaf certs                 |
| `MOODLE_DOCKER_KEYCLOAK_DATA_DIR`        | no        | path                                  | `./keycloak/data` | Directory holding the instance's Keycloak state and realm import         |
