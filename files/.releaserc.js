const releaseRules = require('./custom-release-rules');

module.exports = {
    plugins: [
        "@semantic-release/commit-analyzer",
        "@semantic-release/release-notes-generator",
        "@semantic-release/changelog",
        "@semantic-release/github",
        "@semantic-release/git"
    ],
    analyzeCommits: {
        preset: "angular",
        releaseRules: releaseRules
    },
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
                "CHANGELOG.md"
            ],
            message: "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}"
        }
    ]
};
