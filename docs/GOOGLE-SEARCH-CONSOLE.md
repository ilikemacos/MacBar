# Google Search Console — get rNitro into Google

Marketing URL (indexed): **https://chopstickshq.com/rnitro/**  
Download CDN (not the homepage): **https://getrnitro.netlify.app/**

There is **no Search Console MCP** in this workspace — do these steps once in the browser with the Google account that owns the site (verification file `googleadfac0eaf77a74e6.html` is already deployed).

## 1. Add properties

Open [Google Search Console](https://search.google.com/search-console):

1. **URL-prefix property:** `https://chopstickshq.com/rnitro/`
2. Optional **Domain property:** `chopstickshq.com` (needs DNS TXT — best long-term)
3. Keep **URL-prefix:** `https://getrnitro.netlify.app/` if it already exists (downloads / verification)

### Verify HTML file (already on CDN + HQ mirror)

- CDN: https://getrnitro.netlify.app/googleadfac0eaf77a74e6.html  
- HQ: https://chopstickshq.com/rnitro/googleadfac0eaf77a74e6.html  

If GSC asks for a **new** token, replace the file name in the repos and redeploy.

## 2. Submit sitemaps

In each property → **Sitemaps** → submit:

| Property | Sitemap URL |
|----------|-------------|
| chopstickshq.com (domain or root) | `https://chopstickshq.com/sitemap.xml` |
| rnitro prefix | `https://chopstickshq.com/rnitro/sitemap.xml` |
| getrnitro (optional) | `https://getrnitro.netlify.app/sitemap.xml` |

## 3. Request indexing (homepage)

**URL Inspection** → enter:

`https://chopstickshq.com/rnitro/`

→ **Request indexing**. Repeat for:

- `https://chopstickshq.com/rnitro/cli.html`
- `https://chopstickshq.com/rnitro/linux.html`

Google may queue these (hours–days).

## 4. Keywords we target (on-page already)

- rNitro / rnitro  
- open source macos cpu monitor  
- free mac menu bar monitor  
- macOS system monitor  
- Apple Silicon temperature  
- free iStat alternative / btop mac alternative  

Ranking takes **days to weeks** and needs links (GitHub, AlternativeTo, Product Hunt, Reddit, blogs).

## 5. After each major release

1. Redeploy getrnitro + HQ (so sitemap / meta stay current)  
2. In GSC → Sitemaps → resubmit if changed  
3. Optionally re-request indexing for `/rnitro/`

## What we automated in the product

- Canonical + Open Graph → `chopstickshq.com/rnitro/`  
- Rich `SoftwareApplication` + FAQ JSON-LD  
- Keyword-rich title/description  
- Sitemap URLs point at HQ product pages  
- getrnitro **301**s marketing pages to HQ (signals consolidate)  
