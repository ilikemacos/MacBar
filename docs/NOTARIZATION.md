# Notarizing rNitro (when you have an Apple Developer account)

This machine currently has **no Developer ID Application certificate**
(`security find-identity -v -p codesigning` → 0 identities). Until a cert
exists, we ship **ad-hoc** signatures and document Gatekeeper “right-click → Open”.

## Prerequisites

1. Apple Developer Program membership  
2. Create **Developer ID Application** certificate in Keychain  
3. App Store Connect API key or Apple ID app-specific password for notarytool  

```bash
# List signing identities (should show Developer ID Application: …)
security find-identity -v -p codesigning

# Store notary credentials once
xcrun notarytool store-credentials "rnitro-notary" \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"
```

## Per-release flow (after ZIP/APP is built)

```bash
# 1) Sign with Developer ID (not ad-hoc "-")
codesign --force --options runtime --timestamp \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  path/to/rNitro.app

# 2) Zip for notary
ditto -c -k --keepParent rNitro.app rNitro-notary.zip

# 3) Submit + wait
xcrun notarytool submit rNitro-notary.zip \
  --keychain-profile "rnitro-notary" --wait

# 4) Staple
xcrun stapler staple rNitro.app

# 5) Verify
spctl --assess --type execute -vv rNitro.app
```

## Wire into packaging (later)

- `build-app-zip.py` / `build-app-pkg.py` / `signing.py`: prefer Developer ID when identity env `RNITRO_SIGN_IDENTITY` is set; fall back to ad-hoc.  
- Document `RNITRO_NOTARY_PROFILE` for CI.

## Until then

- Site Gatekeeper card on getrnitro  
- Prefer **curl install** (compiles locally) for least friction  
- PKG/DMG still need right-click Open  
