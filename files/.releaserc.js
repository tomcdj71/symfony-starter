module.exports = {
    plugins: [
        ["@semantic-release/commit-analyzer", {
            preset: "angular",
            releaseRules: require('./custom-release-rules'),
            parserOpts: {
                headerPattern: /^(.*): (.*)$/,
                headerCorrespondence: ['type', 'subject']
            }
        }],
        "@semantic-release/release-notes-generator",
        "@semantic-release/changelog",
        "@semantic-release/github",
        "@semantic-release/git"
    ],
    branches: [
        "main",
        {
            name: "develop",
            channel: "next",
            prerelease: "beta"
        },
        {
            name: "staging",
            channel: "next",
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
            message: "🎫 CHORE(release): ${nextRelease.version}\n\n${nextRelease.notes}"
        }
    ]
};
