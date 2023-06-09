#!/bin/bash

display_help() {
    echo "Usage: $0 [options]"
    echo
    echo "   -ghu,  Github username"
    echo "   -ght,  Github token"
    echo "   -ct,   Codacy token"
    echo "   -n,    Project name"
    echo "   -o,    Full name"
    echo "   -desc, DESCRIPTION"
    echo "   -pm,  Package manager (npm, yarn, pnpm)"
    echo "   -sm   Semver token"
    echo "   -h|--help,    Display this help message and exit"
    echo
    exit 1
}

parse_arguments() {
    while (( "$#" )); do
        case "$1" in
            -ghu)
                GH_USERNAME="$2"
                CODACY_ORGANIZATION_PROVIDER=gh
                CODACY_USERNAME="$GH_USERNAME"
                shift 2
            ;;
            -ght)
                GH_TOKEN="$2"
                shift 2
            ;;
            -ct)
                CODACY_TOKEN="$2"
                shift 2
            ;;
            -n)
                PROJECT_NAME="$2"
                CODACY_PROJECT_NAME="$PROJECT_NAME"
                shift 2
            ;;
            -o)
                FULL_NAME="$2"
                shift 2
            ;;
            -pm)
                PACKAGE_MANAGER="$2"
                shift 2
            ;;
            -sm)
                SEMVER_TOKEN="$2"
                shift 2
            ;;
            -desc)
                DESCRIPTION="$2"
                shift 2
            ;;
            -h|--help)
                display_help
            ;;
            --) # end argument parsing
                shift
                break
            ;;
            -*|--*=) # unsupported flags
                echo "Error: Unsupported flag $1" >&2
                exit 1
            ;;
            *) # preserve positional arguments
                PARAMS="$PARAMS $1"
                shift
            ;;
        esac
    done
}

set_package_manager() {
    if [ -z "$PACKAGE_MANAGER" ]
    then
        PACKAGE_MANAGER="npm"
    fi
}

create_symfony_project() {
    export EDITOR=:
    echo "Creating Symfony project..."
    if [ -z "$PROJECT_NAME" ]
    then
        echo "Error: Project name is required" >&2
        exit 1
    fi
    symfony new "$PROJECT_NAME" --webapp --quiet
    cd "$PROJECT_NAME"
    check_starter_pack
    mv .env .env.local
    create_env_file
    mv pre-commit .git/hooks/
    chmod +x .git/hooks/pre-commit
    generate_and_set_secret_keys
    initialize_git
}

create_env_file() {
    cat > .env <<EOF
APP_ENV=prod
APP_SECRET="%env(APP_SECRET)%"
DATABASE_URL="sqlite:///%kernel.project_dir%/var/data.db"
MESSENGER_TRANSPORT_DSN=doctrine://default?auto_setup=0
# MAILER_DSN=null://null
EOF
}

generate_and_set_secret_keys() {
    for ENV in prod dev test
    do
        APP_RUNTIME_ENV=$ENV php bin/console secrets:generate-keys --quiet
        APP_RUNTIME_ENV=$ENV php bin/console secrets:set APP_SECRET --random --quiet
        APP_RUNTIME_ENV=$ENV php bin/console secrets:set APP_SECRET --random --local --quiet
    done
}

check_starter_pack() {
    echo "Checking if starter pack exists..."
    if [ ! -d "$HOME/symfony-starter" ]; then
        STARTER_PACK_REPO="https://github.com/tomcdj71/symfony-starter.git"
        git clone $STARTER_PACK_REPO $HOME/symfony-starter
    else
        git -C $HOME/symfony-starter pull
    fi
    cp -pR $HOME/symfony-starter/files/* .
    cp -pR $HOME/symfony-starter/files/.* .
}

install_required_packages() {
    echo "Installing dependencies..."
    NAME="$(echo "$GH_USERNAME/$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')"
    modify_composer_json
    setup_npm_packages
}

modify_composer_json() {
    echo "Editing composer.json..."
    jq --arg name "$NAME" --arg desc "$DESCRIPTION" --arg full_name "$FULL_NAME" \
    '.name = "\($name)"
    | .description = "\($desc)"
    | .license = "MIT"
    | .authors = [{"name": "\($full_name)", "email": "change@me.com"}]
    | .homepage = "https://github.com/\($name).git"
    | .scripts = (.scripts // {}) + {"phpstan-baseline": "./vendor/bin/phpstan analyze --configuration=phpstan.neon --level=9 --allow-empty-baseline --generate-baseline --verbose", "phpstan": "./vendor/bin/phpstan analyze --configuration=phpstan.neon --level=9 --verbose", "phpcs": "./vendor/bin/php-cs-fixer fix ./src --rules=@Symfony --verbose --allow-risky=yes", "phpcs-dr": "./vendor/bin/php-cs-fixer fix ./src --rules=@Symfony --verbose --allow-risky=yes --dry-run", "translations-update": "php bin/console translation:extract --force fr --format=yml --sort"}' composer.json > newComposer.json
    mv newComposer.json composer.json
    composer config extra.symfony.allow-contrib true
    composer config --no-plugins allow-plugins.phpro/grumphp true
    install_composer_packages
}


install_composer_packages() {
    echo "Installing composer packages..."
    composer update -q
    PACKAGES="rector/rector phpunit/phpunit phpstan/phpstan phpro/grumphp friendsofphp/php-cs-fixer squizlabs/php_codesniffer phpmd/phpmd phpstan/phpstan-doctrine"
    composer req $PACKAGES --dev --with-all-dependencies --no-interaction --sort-packages --optimize-autoloader --fixed -q
    composer req symfony/webpack-encore-bundle -q
    ./vendor/bin/php-cs-fixer fix --allow-risky=yes
    echo ".phpunit.cache/" >> .gitignore
}

setup_npm_packages() {
    echo "Installing npm packages..."
    jq --arg pm "$PACKAGE_MANAGER" --arg name "$NAME" --arg desc "$DESCRIPTION" '
    .scripts += {
        "dev-server": "encore dev-server",
        "dev": "encore dev",
        "watch": "encore dev --watch",
        "build": "encore production --progress",
        "lint": "./vendor/bin/phpcbf --standard=.phpcs.xml --ignore=vendor/,bin/,var/,node_modules/ src/ tests/",
        "fix": "./vendor/bin/rector process ./src",
        "analyze": "./vendor/bin/phpstan analyze --configuration=phpstan.neon --generate-baseline",
        "security": "symfony check:security",
        "precommit": "\($pm) run lint && \($pm) run analyze && \($pm) run security"
    }
    | .["pre-commit"] = ["precommit"]
    | .license = "MIT"
    | .version = "0.0.1"
    | .name = "@\($name)"
    | .description = "\($desc)"
    ' package.json > newPackage.json
    mv newPackage.json package.json
    PACKAGES="semantic-release @semantic-release/commit-analyzer @semantic-release/release-notes-generator @semantic-release/git @semantic-release/github @semantic-release/changelog conventional-changelog-custom conventional-changelog-angular conventional-changelog-conventionalcommits conventional-changelog"
    echo "Installing packages..."
    $PACKAGE_MANAGER install --force --save-dev $PACKAGES
    echo "Updating packages to the latest versions..."
    $PACKAGE_MANAGER up --lates
    if [ "$PACKAGE_MANAGER" != "pnpm" ]; then
        echo "Running audit fix..."
        $PACKAGE_MANAGER audit fix --force
    else
        echo "Running audit fix for pnpm..."
        $PACKAGE_MANAGER audit --fix
    fi
    echo "Building the project..."
    $PACKAGE_MANAGER run build
}

initialize_git() {
    echo "Creating GitHub repository..."
    rm -rf .git
    echo -e "\n" | gh repo create $GH_USERNAME/$PROJECT_NAME --public -d "$DESCRIPTION" > /dev/null 2>&1 && echo "GitHub repository created."
    git config --global init.defaultBranch main
    git config --global --add --bool push.autoSetupRemote true
    git config --global push.default current
    git init
    git remote add origin https://github.com/$GH_USERNAME/$PROJECT_NAME.git
    echo "Creating branches..."
    generate_readme
    install_required_packages
    ./vendor/bin/phpunit --coverage-clover coverage.xml --migrate-configuration
    echo "coverage.xml" >> .gitignore
    git add .
    git commit -m "🎉 INIT: add initial set of files [skip ci]" -n
    git push -u origin develop
    git-flow init -d -f
    create_codacy_repo
    wait_for_codacy
}

generate_readme() {
    echo "Generating README.md..."
    cat > README.md <<EOF
# Welcome to $PROJECT_NAME 👋
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](#)
[![Twitter: ${GH_USERNAME}](https://img.shields.io/twitter/follow/${GH_USERNAME}.svg?style=social)](https://twitter.com/${GH_USERNAME})
[![Codacy Badge](GRADE_URL)](https://app.codacy.com/gh/${GH_USERNAME}/${PROJECT_NAME}/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
[![Codacy Badge](COVERAGE_URL)](https://app.codacy.com/gh/${GH_USERNAME}/${PROJECT_NAME}/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_coverage)
![GitHub release (with filter)](https://img.shields.io/github/v/release/${GH_USERNAME}/${PROJECT_NAME})
![GitHub release (with filter)](https://img.shields.io/github/v/release/${GH_USERNAME}/${PROJECT_NAME}?filter=*beta)

> ${DESCRIPTION}

## Pre-requisites :
- PHP 8.2
- Composer
- npm/yarn (I used pnpm)
- Symfony CLI
---

## Install

\`\`\`sh
git clone https://github.com/${GH_USERNAME}/${PROJECT_NAME}
cd ${PROJECT_NAME}
composer install --no-dev --optimize-autoloader
yarn install --force
yarn build
symfony console d:d:c
symfony console d:m:m
symfony console d:f:l
symfony serve
\`\`\`

## Features

## Usage

## About this project

## Author

👤 **${FULL_NAME}**

* Twitter: [@${GH_USERNAME}](https://twitter.com/${GH_USERNAME})
* Github: [@${GH_USERNAME}](https://github.com/${GH_USERNAME})

## Show your support

Give a ⭐️ if this project helped you!


***
_This README was generated with ❤️ by [readme-md-generator](https://github.com/kefranabg/readme-md-generator)_
EOF
}

create_codacy_repo() {
    sleep 5
    echo "Creating Codacy repository..."
    curl -X POST https://app.codacy.com/api/v3/repositories \
    -H 'Content-Type: application/json' \
    -H "api-token: $CODACY_TOKEN" \
    -d "{
    \"provider\": \"gh\",
    \"repositoryFullPath\": \"$GH_USERNAME/$PROJECT_NAME\"
    }" > /dev/null 2>&1 && echo "Codacy repository created."
}

wait_for_codacy() {
    echo "waiting 15sec for Codacy to be ready..."
    sleep 15
    PROJECT_TOKEN=$(curl -sX POST "https://app.codacy.com/api/v3/organizations/gh/$GH_USERNAME/repositories/$PROJECT_NAME/tokens" -H "api-token: $CODACY_TOKEN" | jq -r ".data.token")
    echo "Codacy ready."
    echo "$PROJECT_TOKEN is the project token."
    gh secret set CODACY_PROJECT_TOKEN --body $PROJECT_TOKEN
    FILEPATHS=("config/preload" "config/secrets" "README.md" "assets/app.js" "assets/styles/app.css" "public/index.php" "tests/bootstrap.php" "webpack.config.js")
    for filepath in ${FILEPATHS[@]}; do
        curl -X PATCH https://app.codacy.com/api/v3/organizations/gh/$GH_USERNAME/repositories/$PROJECT_NAME/file \
        -H 'Content-Type: application/json' \
        -H "api-token: $CODACY_TOKEN" \
        --data-raw '{
            "ignored": true,
        "filepath": "'$filepath'" }'
    done
    bash <(curl -Ls https://coverage.codacy.com/get.sh) report -r coverage.xml
}

final_commit() {
    echo "Final commit..."
    sleep 5
    GRADE_URL=$(curl -sX GET https://app.codacy.com/api/v3/organizations/gh/$GH_USERNAME/repositories/$PROJECT_NAME -H 'Accept: application/json' -H "api-token: $CODACY_TOKEN" | jq -r ".data | .badges | .grade")
    COVERAGE_URL=$(curl -sX GET https://app.codacy.com/api/v3/organizations/gh/$GH_USERNAME/repositories/$PROJECT_NAME -H 'Accept: application/json' -H "api-token: $CODACY_TOKEN" | jq -r ".data | .badges | .coverage")
    sed -i "s|GRADE_URL|$GRADE_URL|g" README.md
    sed -i "s|COVERAGE_URL|$COVERAGE_URL|g" README.md
    chmod -R 777 var
    git add .
    git branch --set-upstream-to=origin/main develop
    git commit -m "💻 CI: add CI process [automated]" -n
    git push origin develop
    git checkout -b staging develop
    git push origin staging
    npx semantic-release
}

parse_arguments "$@"
set_package_manager
create_symfony_project
final_commit
