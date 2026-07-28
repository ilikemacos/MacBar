rNitro GitHub package — v1.3.29-Experimental (Enable Logging)
==============================================================

This folder is a ready-to-push snapshot of the ilikemacos/rNitro website +
installers repo (not an Xcode project; app source is embedded in
install-rNitro-experimental.sh).

Main tree
---------
• install-rNitro-experimental.sh  — Experimental compile installer (source of truth)
• install-rNitro.sh / -intel / -linux / -windows
• version.json, changelog.json, index.html, docs/, cli/, fonts/, etc.

release-assets/
---------------
• rNitro-v1.3.29-Experimental.sh  — named installer (upload as GitHub Release asset)
• rNitro-v1.3.29-Experimental.zip  — App ZIP (upload as GitHub Release asset)

Typical push
------------
  cd this-folder
  git init   # or clone ilikemacos/rNitro and copy over
  # commit & push main
  # gh release create v1.3.29-Experimental release-assets/*

Live site already mirrors HQ Netlify: https://chopstickshq.com/rnitro/
