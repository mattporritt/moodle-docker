# moodle-docker: Docker Containers for Moodle Developers
# Overview
These instructions cover setting up a Moodle (omnibus) development environment. It uses Docker to run Moodle LMS and the related services for a development environment. It is a fork of: https://github.com/moodlehq/moodle-docker but with additions for SSO and Matrix.

The services set up are:
* Moodle LMS
* Postgres Database server
* Mailhog
* Selenium
* Matrix (Both Synapse and Element)
* Keycloak
* Matrix-synapase Mock

Once the following steps are complete the sites can be accessed at the following URLs:
* Moodle LMS: https://webserver/
* Keycloak: https://keycloak:8443/
* Element: https://element:8081/
* Synapse: https://synapse:8008/
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
* Synapse
* Element
* Webserver (Moodle)
* Elementmoc (Matrix-synapse Mock)

If you haven’t already customised your hosts file the line should look like:<br/>
`127.0.0.1   	localhost synapse webserver keycloak element elementmock`

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
`./createcerts.sh synapse`
`./createcerts.sh element`

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
`docker build -t "stevando:moodle_dev" .`

Finally, actually start the services:<br/>
`cd moodle-docker/bin`<br/>
`./moodle-docker-compose up -d`

Next we need to install Moodle:<br/>
`./moodle-docker-compose exec webserver php admin/cli/install_database.php --agree-license --fullname="Moodle Master" --shortname="docker_moodle" --summary="Moodle dev site" --adminpass="test" --adminemail="you@gmail.com"`

## Synapse admin user
We also need to create an initial Synapse admin user. This is an initial user you'll need before you can use the Matrix API.<br/>
Synapse provides a cli tool to create users. To create an initial admin user:<br/>
`cd moodle-docker/bin`<br/>
```
docker exec -it {containerid} register_new_matrix_user \
-u admin \
-a \
-c /data/homeserver.yaml \
https://synapse:8008/
```
Where `{containerid}` is the Docker ID of the running Synapse container.

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
This will set up Keycloak as an Identity Provider (IdP) for Moodle and Synapse. Users will be able to log into Moodle and Element via Keycloak once the following configuration is complete.

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

Set up the Synapse client:<br/>
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

## Synapse
The following steps will set up Synapse as a Service Provider with Keycloak as an Identity Provider.

To do this:<br/>
* Open the homeserver.yaml for the synapse configuration: moodle-docker/synapse_data/homeserver.yaml
* Change the value for client_secret to the client secret value for the synapse-client from Keycloak
* Restart the synapse container in Docker.

# Accessing Sites
Once the above steps are complete the sites can be accessed at the following URLs:
* Moodle LMS: https://webserver/
* Keycloak: https://keycloak:8443/
* Element: https://element:8081/
* Synapse: https://synapse:8008/
* Mailhog: http://webserver:1234/_/mail
* Matrix-synapase Mock: http://elementmock:8001

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

# Mailhog
MailHog is an email-testing tool with a fake SMTP server underneath. It encapsulates the SMTP protocol with extensions and does not require specific backend implementations. MailHog runs a super simple SMTP server that hogs outgoing emails sent to it. You can see the hogged emails in a web interface.

To access mailhog:<br/>
http://webserver:1234/_/mail

# Useful Docker Commands
To access the container directly:<br/>
`./moodle-docker-compose exec -it webserver /bin/bash`

To get container logs (which include apache logs for webserver container:<br/>
`docker logs -f moodlemaster-webserver-1`

To shut things down:<br/>
`./moodle-docker-compose down`

To access the Moodle DB from the host machine:<br/>
`psql -h 127.0.0.1 -p 5433 -U moodle`

To dump the db from the host machine:<br/>
`pg_dump -h 127.0.0.1 -p 5433 -U moodle -Fc moodle > moodle.dump`

To restore the db when none exists:<br/>
`pg_restore -h 127.0.0.1 -p 5433 -U moodle -d moodle moodle.dump`
