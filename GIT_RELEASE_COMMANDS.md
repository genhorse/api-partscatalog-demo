# Git Release Commands for v1.2.0

Execute these commands in order to create the GitHub release:

---

## 1. Verify All Changes Are Committed

```bash
cd api-partscatalog-demo
git status
```

Ensure all files are staged and committed.

---

## 2. Create Annotated Tag

```bash
git tag -a v1.2.0 -m "Release v1.2.0: i18n (6 languages) + Enterprise Migrations"
```

---

## 3. Push Tag to GitHub

```bash
git push origin v1.2.0
```

---

## 4. Create GitHub Release

### Option A: Via GitHub Web UI

1. Go to: https://github.com/gennorse/api-partscatalog-demo/releases
2. Click "Draft a new release"
3. Tag version: `v1.2.0`
4. Release title: `v1.2.0 - i18n + Enterprise Migrations`
5. Copy content from `RELEASE_NOTES_v1.2.0.md`
6. Click "Publish release"

### Option B: Via GitHub CLI

```bash
gh release create v1.2.0 \
    --title "v1.2.0 - i18n + Enterprise Migrations" \
    --notes-file RELEASE_NOTES_v1.2.0.md
```

---

## 5. Verify Release

```bash
# Check tag exists locally
git tag -l v1.2.0

# Check tag exists on remote
git ls-remote --tags origin | grep v1.2.0

# View release info
gh release view v1.2.0
```

---

## 6. Update Main Branch (if needed)

```bash
git checkout main
git merge v1.2.0
git push origin main
```

---

## 7. Notify Team (Optional)

```bash
# Example Slack notification
# 🚀 Release v1.2.0 is now available!
# Features: i18n (6 languages), Auto-Migration, Rollback support
# Link: https://github.com/gennorse/api-partscatalog-demo/releases/tag/v1.2.0
```

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `git tag -a v1.2.0 -m "..."` | Create annotated tag |
| `git push origin v1.2.0` | Push tag to remote |
| `gh release create v1.2.0` | Create GitHub release |
| `git tag -l` | List all tags |
| `git show v1.2.0` | Show tag details |

---

## Rollback (If Needed)

```bash
# Delete tag locally
git tag -d v1.2.0

# Delete tag on remote
git push origin :refs/tags/v1.2.0

# Fix issues and re-tag
git tag -a v1.2.0 -m "Release v1.2.0: Fixed"
git push origin v1.2.0
```
