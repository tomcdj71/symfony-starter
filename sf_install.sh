#!/bin/bash

#!/bin/bash

# Function to display usage message
function display_help {
    echo "Usage: $0 [options]"
    echo
    echo "   -ghu,  Github username"
    echo "   -ght,  Github token"
    echo "   -ct,   Codacy token"
    echo "   -d,    Base directory"
    echo "   -n,    Project name"
    echo "   -o,    Full name"
    echo "   -desc, Description"
    echo "   -h|--help,    Display this help message and exit"
    echo
    exit 1
}

# Parse the command-line arguments
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
        -d)
            base_dir="$2"
            shift 2
        ;;
        -n)
            project_name="$2"
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
            description="$2"
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

# Clone the repo if the boilerplate directory doesn't exist
if [ ! -d "$STARTER_PACK_DIR" ]; then
    cd $BASE_DIR
    STARTER_PACK_REPO="https://github.com/tomcdj71/symfony-starter.git"
    git clone $STARTER_PACK_REPO $STARTER_PACK_DIR
fi

# Create a new Symfony project
cd "$BASE_DIR"
symfony new "$PROJECT_NAME" --webapp

# Configure the project
cd "$PROJECT_NAME"
mv .env .env.local
cat > .env <<EOF
APP_ENV=prod
APP_SECRET="%env(APP_SECRET)%"
DATABASE_URL="sqlite:///%kernel.project_dir%/var/data.db"
MESSENGER_TRANSPORT_DSN=doctrine://default?auto_setup=0
# MAILER_DSN=null://null
EOF

# Generate and set secret keys
for ENV in prod dev test
do
    APP_RUNTIME_ENV=$ENV php bin/console secrets:generate-keys --quiet
    APP_RUNTIME_ENV=$ENV php bin/console secrets:set APP_SECRET --random --quiet
    APP_RUNTIME_ENV=$ENV php bin/console secrets:set APP_SECRET --random --local --quiet
done

# Install the required packages
packages="rector/rector phpunit/phpunit phpstan/phpstan phpro/grumphp friendsofphp/php-cs-fixer symfony/webpack-encore-bundle squizlabs/php_codesniffer"
composer req $packages --dev

# Configure GrumPHP
vendor/bin/grumphp configure
vendor/bin/grumphp git:init

# Copy the boilerplate files to the new project directory
cp -R "$STARTER_PACK_DIR/"* "../$PROJECT_NAME/"

# Install dependencies and build the project
echo "Installing dependencies..."
# Modify composer.json
jq --arg pn "$PROJECT_NAME" --arg ghu "$GH_USERNAME" '
    .name = "\($ghu)/\($pn)"
    | .DESCRIPTION = "\($pn)"
    | .scripts += {"phpstan": "phpstan analyse", "phpcs": "./vendor/bin/php-cs-fixer fix --dry-run --allow-risky=yes"}
| .config += {"allow-plugins": {"phpro/grumphp": true}}' composer.json > newComposer.json

mv newComposer.json composer.json
# Modify package.json
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
$PACKAGE_MANAGER up --latest > /dev/null 2>&1
$PACKAGE_MANAGER install > /dev/null 2>&1
$PACKAGE_MANAGER run build > /dev/null 2>&1

# Initialize git, commit and push the project to GitHub
echo "Creating GitHub repository..."
echo -e "\n" | gh repo create $GH_USERNAME/$PROJECT_NAME --public -d "$DESCRIPTION" > /dev/null 2>&1 && echo "GitHub repository created."
echo "Creating Codacy repository..."
curl 'https://app.codacy.com/api/v3/repositories' -H 'content-type: application/json; charset=utf-8' -H 'caller: codacy-spa'
--data-raw '{"repositoryFullPath":"$GH_USERNAME'/'$PROJECT_NAME","provider":"gh"}'
curl -X POST https://app.codacy.com/api/v3/repositories \
-H 'Content-Type: application/json' \
-H 'Accept: application/json' \
-H 'caller: string' \
-H "api-token: $CODACY_TOKEN" \
--data-raw '{
  "provider": "gh",
  "repositoryFullPath": "'$GH_USERNAME'/'$PROJECT_NAME'"
}' > /dev/null 2>&1 && echo "Codacy repository created."
# create branches main and develop and push them to GitHub
echo "Generating README.md..."
cat > README.md <<EOF
# Welcome to $PROJECT_NAME 👋
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](#)
[![Twitter: \${GH_USERNAME}](https://img.shields.io/twitter/follow/\${GH_USERNAME}.svg?style=social)](https://twitter.com/\${GH_USERNAME})
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/267dc4acb65d4386beaf17e56a71e5f9)](https://app.codacy.com/gh/\${GH_USERNAME}/\${PROJECT_NAME}/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
[![Codacy Badge](https://app.codacy.com/project/badge/Coverage/267dc4acb65d4386beaf17e56a71e5f9)](https://app.codacy.com/gh/\${GH_USERNAME}//\${PROJECT_NAME}/dashboard?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_coverage)

> \${DESCRIPTION}

## Pre-requisites :
- PHP 8.2
- Composer
- npm (I used pnpm)
- Symfony CLI
---

## Install

\`\`\`sh
git clone https://github.com/\${GH_USERNAME}/\${PROJECT_NAME}
cd \${PROJECT_NAME}
composer install --no-dev --optimize-autoloader
yarn install
yarn build
symfony console d:d:c
symfony console d:m:m
symfony console d:f:l
symfony serve
\`\`\`

## Usage

## Author

👤 **\${FULL_NAME}**

* Twitter: [@\${GH_USERNAME}](https://twitter.com/\${GH_USERNAME})
* Github: [@\${GH_USERNAME}](https://github.com/\${GH_USERNAME})

## Show your support

Give a ⭐️ if this project helped you!


***
_This README was generated with ❤️ by [readme-md-generator](https://github.com/kefranabg/readme-md-generator)_
EOF
echo "Creating branches..."
git config --global init.defaultBranch main
git init
git remote add origin https://github.com/$GH_USERNAME/$PROJECT_NAME.git
git config --global init.defaultBranch main
git init
git remote add origin https://github.com/$GH_USERNAME/$PROJECT_NAME.git
git checkout -b main
git add .
git commit -m "📦 NEW: Initial commit"
git push -u origin main
git checkout -b develop
git config branch.main.pushRemote no_push
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
}'

echo "$PROJECT_NAME ready. Don't forget to update the README.md file to include the codacy badge."
