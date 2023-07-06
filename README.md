# Welcome to $symfony-starter 👋
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](#)
[![Twitter: tomcdj71](https://img.shields.io/twitter/follow/tomcdj71.svg?style=social)](https://twitter.com/tomcdj71)

> Setup a symfony repo with a powerful CI and code analysis tools

## Pre-requisites :
- PHP (8.2 prefered)
- Composer
- npm
- Symfony CLI
- GitHub CLI (gh)
- Codacy Analysis Tools

In order to install Codacy Analysis Tools you can do the following : 
```sh
sudo curl -L https://github.com/codacy/codacy-analysis-cli/releases/latest/download/codacy-analysis-cli.sh > /usr/bin/codacy-analysis-cli.sh
sudo chmod +x /usr/bin/codacy-analysis-cli.sh
```
---

## Install

```sh
git clone https://github.com/tomcdj71/symfony-starter
cd symfony-starter
chmod +x sf_install.sh
sudo ln -s sf_install.sh /usr/bin/sfi
```

## Usage

```sh
-ghu,  Github username
-ght,  Github token (1)
-ct,   Codacy token (2)
-n,    Project name
-o,    Full name
-desc, Description
-pm,   Package Manager
-h|--help,    Display the help
```
(1) _[learn how to create a GitHub token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens)_
(2) _[learn how to create a Codacy token](https://docs.codacy.com/codacy-api/api-tokens/)_

Full usage : 
`sfi -ghu $github_username -ght $github_token -ct $codacy_token -o $full_name -pm $pm -desc $description -n $project_name` 


You also can set up with ENV variables

```sh
export FULL_NAME="John Doe"
export GITHUB_USERNAME="johndoe54"
export GITHUB_TOKEN="ghp_xxx"
export CODACY_TOKEN="zzz"

export PACKAGE_MANAGER=pnpm
sfi -ghu $GITHUB_USERNAME -ght $GITHUB_TOKEN -ct $CODACY_TOKEN -o $FULL_NAME -pm $PACKAGE_MANAGER -desc "My super project" -n "TestProject"`
```


## Author

👤 **Thomas Chauveau**

* Twitter: [@tomcdj71](https://twitter.com/tomcdj71)
* Github: [@tomcdj71](https://github.com/tomcdj71)

## Show your support

Give a ⭐️ if this project helped you!


***
_This README was generated with ❤️ by [readme-md-generator](https://github.com/kefranabg/readme-md-generator)_
