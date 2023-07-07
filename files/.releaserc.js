const releaseRules = require('./custom-release-rules');

module.exports = {
    plugins: [
        ["@semantic-release/commit-analyzer", {
            preset: "angular",
            releaseRules: releaseRules,
            parserOpts: {
                headerPattern: /^(.*): (.*)$/,
                headerCorrespondence: ['type', 'subject']
            }
        }],
        "@semantic-release/release-notes-generator",
        "@semantic-release/changelog",
        {
            "changelogFile": "CHANGELOG.md"
        },
        "@semantic-release/github",
        "@semantic-release/git"
    ],
    branches: [
        "main",
        {
            name: "develop",
            channel: "beta",
            prerelease: "beta"
        },
        {
            name: "staging",
            channel: "rc",
            prerelease: "rc"
        }
    ],
    prepare: [
        "@semantic-release/changelog",
        {
            path: "@semantic-release/git",
            assets: [
                "package.json",
                "package-lock.json",
                "composer.json",
                "CHANGELOG.md"
            ],
            message: "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
        }
    ]
};
