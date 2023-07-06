#---Symfony-Justfile---------------#
# Author: https://github.com/tomcdj71
# License: MIT
#---------------------------------------------#

# Variables
set shell := ["bash", "-c"]
PWD := "`pwd`"
SYMFONY := "symfony"
SYMFONY_CONSOLE := "symfony console"
COMPOSER := "composer"
NPM := "pnpm"
VENDOR_BIN := "./vendor/bin"
PHPUNIT := "APP_ENV=test ${SYMFONY} php vendor/bin/phpunit"

# Symfony
#Starts the Symfony server.
sf-start:
    {{SYMFONY}} serve -d
#Stops the Symfony server.
sf-stop: 
    {{SYMFONY}} server:stop
#Clears the Symfony cache.
sf-cc: 
    {{SYMFONY_CONSOLE}} cache:clear
#Opens the Symfony server log.
sf-log: 
    {{SYMFONY}} server:log
#Creates the Doctrine database.
sf-dc: 
    {{SYMFONY_CONSOLE}} doctrine:database:create
#Drops the Doctrine database.
sf-dd: 
    {{SYMFONY_CONSOLE}} doctrine:database:drop --force
#Updates the Doctrine schema.
sf-su: 
    {{SYMFONY_CONSOLE}} doctrine:schema:update --force
#Creates a new Doctrine migration.
sf-mm: 
    {{SYMFONY_CONSOLE}} make:migration
#Executes the Doctrine migrations.
sf-dmm: 
    {{SYMFONY_CONSOLE}} doctrine:migrations:migrate --no-interaction
#Loads the Doctrine fixtures.
sf-fixtures: 
    {{SYMFONY_CONSOLE}} doctrine:fixtures:load --no-interaction
#Creates a new Symfony Entity.
sf-me: 
    {{SYMFONY_CONSOLE}} make:entity
#Creates a new Symfony Controller.
sf-mc: 
    {{SYMFONY_CONSOLE}} make:controller
#Creates a new Symfony Form.
sf-mf: 
    {{SYMFONY_CONSOLE}} make:form
#Fix ./var permissions.
sf-perm: 
    chmod -R 777 var
#Fix ./var permissions with sudo.
sf-sudo-perm: 
    sudo chmod -R 777 var
#Dumps the content of the .env file.
sf-dump-env: 
    {{SYMFONY_CONSOLE}} debug:dotenv
#Dumps the environment variables used by the container.
sf-dump-env-container: 
    {{SYMFONY_CONSOLE}} debug:container --env-vars
#Dumps the Symfony routes.
sf-dump-routes: 
    {{SYMFONY_CONSOLE}} debug:router
#Opens the local Symfony application in the default browser.
sf-open: 
    {{SYMFONY}} open:local
#Opens the Symfony email collector in the default browser.
sf-open-email: 
    {{SYMFONY}} open:local:webmail
#Checks the Symfony application's requirements.
sf-check-requirements: 
    {{SYMFONY}} check:requirements
#Generates secret keys for the Symfony application.
sf-generate-keys: 
    {{SYMFONY_CONSOLE}} secret:generate-keys
#Generates secret keys for both the dev and prod environments.
sf-generate-all-keys: 
    APP_RUNTIME_ENV=dev just sf-generate-keys && APP_RUNTIME_ENV=prod just sf-generate-keys
#Rotates the secret keys for the Symfony application.
sf-rotate-keys: 
    {{SYMFONY_CONSOLE}} secret:generate-keys --rotate
#Rotates the secret keys for both the dev and prod environments.
sf-rotate-all-keys: 
    APP_RUNTIME_ENV=dev just sf-rotate-keys && APP_RUNTIME_ENV=prod just sf-rotate-keys
#Decrypts the secrets to the local .env file.
sf-decrypt: 
    {{SYMFONY_CONSOLE}} secrets:decrypt-to-local --force

# Composer
#Installs the composer dependencies.
composer-install: 
    {{COMPOSER}} install
#Updates the composer dependencies.
composer-update: 
    {{COMPOSER}} update
#Validates the composer.json and composer.lock files.
composer-validate: 
    {{COMPOSER}} validate
#Executes a deeper validation of the composer.json and composer.lock files.
composer-validate-deep: 
    {{COMPOSER}} validate --strict --check-lock
#Check if there are outdate packages
composer-outdated: 
    {{COMPOSER}} outdated --direct --strict

# NPM
#Installs the npm packages.
npm-install: 
    {{NPM}} install --force
#Updates the npm packages.
npm-update: 
    {{NPM}} update
#Runs the npm build script.
npm-build: 
    {{NPM}} run build
#Runs the npm dev script.
npm-dev: 
    {{NPM}} run dev
#Runs the npm watch script.
npm-watch: 
    {{NPM}} run watch

# PHPQA
#Runs PHP CS Fixer in dry run mode.
qa-cs-fixer-dr: 
    @if {{COMPOSER}} run-script phpcs-dr; then \
        echo "No errors found."; \
    else \
        read -p "Errors found. Do you want to run qa-cs-fixer? (y/N) " decision; \
        if [ "$$decision" = "y" ]; then \
            {{COMPOSER}} run-script phpcs; \
        fi \
    fi
#Runs PHP CS Fixer.
qa-cs-fixer: 
    {{COMPOSER}} run-script phpcs
#Runs PHPStan report.
qa-phpstan-baseline: 
    {{COMPOSER}} run-script phpstan-baseline
#Runs PHPStan.
qa-phpstan: 
    {{COMPOSER}} run-script phpstan
#Runs Psalm.
qa-psalm: 
    {{VENDOR_BIN}}/psalm
#Runs PHPLoc.
qa-phploc: 
    {{VENDOR_BIN}}/phploc
#Runs Symfony security checker.
qa-security-checker: 
    {{SYMFONY}} check:security
#Runs PHPMetrics.
qa-phpmetrics: 
    {{VENDOR_BIN}}/phpmetrics
#Runs PHPMD.
qa-phpmd-baseline: 
    {{VENDOR_BIN}}/phpmd src text phpmd-rules.xml --reportfile phpmd-baseline.txt || true
qa-phpmd: 
    {{VENDOR_BIN}}/phpmd src text phpmd-rules.xml
#Runs Rector in dry run mode.
qa-rector-dr:
    @if {{VENDOR_BIN}}/rector process src --dry-run; then \
        echo "No errors found."; \
    else \
        read -p "Errors found. Do you want to run qa-rector-fix? (y/N) " decision; \
        if [ "$$decision" = "y" || "$$decision" = "yes" ]; then \
            just qa-rector; \
        fi \
    fi
#Runs Rector.
qa-rector: 
    {{VENDOR_BIN}}/rector process src
#Lints Twig templates.
qa-lint-twigs:
    {{SYMFONY_CONSOLE}} lint:twig ./templates
#Lints YAML files.
qa-lint-yaml:
    {{SYMFONY_CONSOLE}} lint:yaml ./config
#Checks the Symfony DI container for errors.
qa-lint-container:
    {{SYMFONY_CONSOLE}} lint:container
#Validates that the Doctrine schema is in sync with the current mapping metadata.
qa-lint-schema:
    {{SYMFONY_CONSOLE}} doctrine:schema:validate --skip-sync -v --no-interaction
#Runs a security audit using the local composer.lock file.
qa-audit:
    {{COMPOSER}} audit
#Extracts the translation messages.
qa-translations-update:
    {{COMPOSER}} run-script translations-update

# Tests
#Runs PHPUnit tests.
test-phpunit: 
    {{PHPUNIT}}
#Runs PHPSpec tests.
test-phpspec: 
    {{SYMFONY_CONSOLE}} phpspec:run
#Runs Behat tests.
test-behat: 
    {{SYMFONY_CONSOLE}} behat
#Runs PHPUnit tests with code coverage.
test-phpunit-coverage: 
    {{PHPUNIT}} --coverage-html var/coverage
#Runs all the tests with testdox format.
tests: 
    APP_ENV=test symfony php {{VENDOR_BIN}}/phpunit --testdox
#Runs all the tests with code coverage.
tests-coverage: 
    APP_ENV=test symfony php {{VENDOR_BIN}}/phpunit --coverage-html var/coverage

# Other commands
#Runs a series of checks before committing code.
before-commit:
    just update
    just report
    just lint

update:
    just composer-update
    just composer-outdated
    just npm-update

#Executes a series of commands to prepare for the first installation.
first-install: 
    just composer-install
    just npm-install
    just npm-build
    just sf-perm
    just sf-decrypt
    just sf-start
    just sf-open

#Starts the Symfony server and opens the local Symfony application in the default browser.
start: 
    just sf-start
    just sf-open

#Stops the Symfony server.
stop: 
    just sf-stop

# Resets the database. This will delete and recreate the database, and run any existing migrations.
reset-db:
    #!/usr/bin/env bash
    read -p "Are you sure you want to reset the database? [y/N] " confirm
    if [[ $$confirm == "y" ]]; then
        just sf-dd
        just sf-dc
        just sf-dmm
    fi

#Prints the values of various variables.
print-vars:
    echo "${SYMFONY}"
    echo "${PHPUNIT}"
    echo "${SYMFONY_CONSOLE}"
    echo "${COMPOSER}"
    echo "${NPM}"
    echo "${VENDOR_BIN}"
    echo "${RECTOR}"

fix:
    just qa-cs-fixer
    just qa-rector
    just qa-phpstan

lint:
    just qa-translations-update
    just qa-lint-twigs
    just qa-lint-yaml
    just qa-lint-container
    just qa-lint-schema

report:
    just qa-security-checker
    just qa-cs-fixer-dr
    just qa-phpstan-baseline
    just qa-rector-dr
    just qa-phpmd-baseline

#Lists all available just commands.
help: 
    @just --list
