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
    echo "   -h|--help,    Display this help message and exit"
    echo
    exit 1
}

parse_arguments() {
    while (( "$#" )); do
        case "$1" in
            -ghu)
                GH_USERNAME="$2"
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
    echo "Creating Symfony project..."
    symfony new "$PROJECT_NAME" --webapp --quiet
    cd "$PROJECT_NAME"
    check_starter_pack
    mv .env .env.local
    create_env_file
    mv pre-commit .git/hooks/
    chmod +x .git/hooks/pre-commit
    echo "coverage.xml" >> .gitignore
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
    modify_composer_json
    install_composer_packages
    composer update
}

modify_composer_json() {
    jq --arg pn "$PROJECT_NAME" --arg ghu "$GH_USERNAME" --arg desc "$DESCRIPTION" '
    .name = "\($ghu)/\($pn | ascii_downcase)"
    | .description = "\($desc)"
    | .license = "MIT"
    | .scripts += {"phpstan": "phpstan analyse", "phpcs": "./vendor/bin/php-cs-fixer fix --dry-run --allow-risky=yes"}' composer.json > newComposer.json
    mv newComposer.json composer.json
    composer config extra.symfony.allow-contrib true
    composer config --no-plugins allow-plugins.phpro/grumphp true
    composer update
}

install_composer_packages() {
    PACKAGES="rector/rector phpunit/phpunit phpstan/phpstan phpro/grumphp friendsofphp/php-cs-fixer symfony/webpack-encore-bundle squizlabs/php_codesniffer"
    composer req $PACKAGES --dev --with-all-dependencies --no-interaction --sort-packages --optimize-autoloader --fixed
    ./vendor/bin/php-cs-fixer fix --allow-risky=yes
    ./vendor/bin/phpunit --coverage-clover coverage.xml --migrate-configuration
}

setup_npm_packages() {
    jq --arg pm "$PACKAGE_MANAGER" '
    .scripts += {
        "lint": "./vendor/bin/phpcbf --standard=.phpcs.xml --ignore=vendor/,bin/,var/,node_modules/ src/ tests/",
        "analyze": "./vendor/bin/phpstan analyze --configuration=phpstan.neon",
        "security": "./bin/console security:check",
        "precommit": "\($pm) run lint && \($pm) run analyze && \($pm) run security"
    }
    | .["pre-commit"] = ["precommit"]
    ' package.json > newPackage.json
    
    mv newPackage.json package.json
    $PACKAGE_MANAGER up --latest
    $PACKAGE_MANAGER install
    $PACKAGE_MANAGER run build
}

initialize_git() {
    echo "Creating GitHub repository..."
    rm -rf .git
    echo -e "\n" | gh repo create $GH_USERNAME/$PROJECT_NAME --public -d "$DESCRIPTION" > /dev/null 2>&1 && echo "GitHub repository created."
    git config --global init.defaultBranch main
    git config --global --add --bool push.autoSetupRemote true
    git init
    git remote add origin https://github.com/$GH_USERNAME/$PROJECT_NAME.git
    echo "Creating branches..."
    generate_readme
    git add .
    git commit -m "🎉 INIT: add initial set of files [automated]"
    git push -u origin main
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

> ${DESCRIPTION}

## Pre-requisites :
- PHP 8.2
- Composer
- npm (I used pnpm)
- Symfony CLI
---

## Install

\`\`\`sh
git clone https://github.com/${GH_USERNAME}/${PROJECT_NAME}
cd ${PROJECT_NAME}
composer install --no-dev --optimize-autoloader
yarn install
yarn build
symfony console d:d:c
symfony console d:m:m
symfony console d:f:l
symfony serve
\`\`\`

## Features

## Usage

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

protect_branch() {
    curl -H "Authorization: token $GH_TOKEN" \
    -X PUT \
    -H "Accept: application/vnd.github.v3+json" \
    https://api.github.com/repos/$GH_USERNAME/$PROJECT_NAME/branches/main/protection \
    -d '{
            "required_pull_request_reviews": {
                "dismiss_stale_reviews": false,
                "require_code_owner_reviews": false,
                "required_approving_review_count": 0
            },
            "restrictions": null,
            "enforce_admins": false,
            "required_status_checks": null,
            "required_linear_history": false,
            "allow_force_pushes": false,
            "allow_deletions": false
    }' > /dev/null 2>&1 && echo "Branches created and main protected."
    echo "$PROJECT_NAME ready."
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
}

final_commit(){
    echo "Final commit..."
    rm -rf vendor
    composer install
    sleep 5
    GRADE_URL=$(curl -sX GET https://app.codacy.com/api/v3/organizations/gh/$GH_USERNAME/repositories/$PROJECT_NAME -H 'Accept: application/json' -H "api-token: $CODACY_TOKEN" | jq -r ".data | .badges | .grade")
    COVERAGE_URL=$(curl -sX GET https://app.codacy.com/api/v3/organizations/gh/$GH_USERNAME/repositories/$PROJECT_NAME -H 'Accept: application/json' -H "api-token: $CODACY_TOKEN" | jq -r ".data | .badges | .coverage")
    sed -i "s|GRADE_URL|$GRADE_URL|g" README.md
    sed -i "s|COVERAGE_URL|$COVERAGE_URL|g" README.md
    chmod -R 777 var
    git add .
    git commit -m "💻 CI: add CI process [automated]"
    git push -u origin main
    git checkout -b develop
    git config branch.main.pushRemote no_push
    protect_branch
}

parse_arguments "$@"
set_package_manager
create_symfony_project
install_required_packages
setup_npm_packages
final_commit