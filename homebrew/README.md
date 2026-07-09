# Homebrew — `brew install rnitro`

```bash
brew tap ilikemacos/rnitro
brew install rnitro
```

Installs **rNitro.app** to `/Applications` (or `~/Applications`) and adds an `rnitro` command.

**No Homebrew / permission issues:**

```bash
curl -fsSL https://raw.githubusercontent.com/ilikemacos/homebrew-rnitro/main/install.sh | bash
```

## Regenerate after a release

```bash
python3 build-homebrew.py
```

Commit and push [homebrew-rnitro](https://github.com/ilikemacos/homebrew-rnitro).