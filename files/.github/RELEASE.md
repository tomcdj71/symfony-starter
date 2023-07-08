# Release

I'm using [semantic-release](https://semantic-release.gitbook.io/) to perform releases and changelog.

The convention is the [JSHint](https://github.com/conventional-changelog/conventional-changelog/tree/master/packages/conventional-changelog-eslint) format, with the next rules:

```javascript
{ type: '💥 BREAKING', release: 'major' },
{ type: '👷 BUILD', release: 'patch' },
{ type: '🎫 CHORE', release: 'minor' },
{ type: '💻 CI', release: 'patch' },
{ type: '📖 DOCS', release: 'patch' },
{ type: '✨ FEATURE', release: 'minor' },
{ type: '🐛 FIX', release: 'patch' },
{ type: '🎉 INIT', release: 'patch' },
{ type: '🔨 REFACTOR', release: 'patch' },
{ type: '💎 STYLE', release: 'patch' },
{ type: '🚨 TEST', release: 'patch' }
```

When you commiting something, you don't have to keep the convention, but let's say in the PR, squash (prefer don't merge) and update the squash message with these examples:

```
💥 BREAKING: I broke something
🐛 FIX: fix (fixes #1234)
👷 BUILD: some packages updates (refs #123)
✨ FEATURE: Added a new feature
```

I think the `refs` should be the PR itself, since these messages generated in the Changelog.
