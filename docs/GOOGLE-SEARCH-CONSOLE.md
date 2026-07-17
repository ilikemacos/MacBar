# Google Search Console — get rNitro into Google

Marketing URL (indexed): **https://chopstickshq.com/rnitro/**  
FAQ: **https://chopstickshq.com/rnitro/faq.html**  
Terms: **https://chopstickshq.com/rnitro/terms.html**  
Privacy: **https://chopstickshq.com/rnitro/privacy.html**  
Download CDN (legacy): **https://getrnitro.netlify.app/** (marketing pages 301 → HQ)

There is **no Search Console API** in this workflow for full verification — do these steps in the browser with the Google account that owns the site.

Verification file (already deployed):

- https://chopstickshq.com/googleadfac0eaf77a74e6.html  
- https://chopstickshq.com/rnitro/googleadfac0eaf77a74e6.html  
- https://getrnitro.netlify.app/googleadfac0eaf77a74e6.html  

## 1. Add properties

Open [Google Search Console](https://search.google.com/search-console):

1. **URL-prefix:** `https://chopstickshq.com/` (or domain property `chopstickshq.com`)
2. **URL-prefix:** `https://chopstickshq.com/rnitro/` (optional, more focused)
3. Optional: `https://getrnitro.netlify.app/` (downloads only; canonical content is HQ)

### Verify

Use the **HTML file** method if prompted. The file name above must match GSC’s token exactly. If Google issues a **new** token, replace the file in both repos and redeploy.

## 2. Submit sitemaps

**Sitemaps → Add:**

| Property | Sitemap |
|----------|---------|
| chopstickshq.com | `https://chopstickshq.com/sitemap.xml` |
| rnitro prefix | `https://chopstickshq.com/rnitro/sitemap.xml` |
| getrnitro (optional) | `https://getrnitro.netlify.app/sitemap.xml` |

## 3. Request indexing

**URL Inspection** → paste each URL → **Request indexing**:

1. `https://chopstickshq.com/`
2. `https://chopstickshq.com/rnitro/`
3. `https://chopstickshq.com/rnitro/faq.html` ← FAQ + FAQPage schema
4. `https://chopstickshq.com/rnitro/terms.html` ← Terms & Conditions
5. `https://chopstickshq.com/rnitro/privacy.html`
6. `https://chopstickshq.com/rnitro/cli.html`
7. `https://chopstickshq.com/rnitro/linux.html`

Google may queue these for hours–days.

### Checklist after deploy (copy/paste)

```
[ ] GSC property verified (HTML file)
[ ] Sitemap submitted: https://chopstickshq.com/sitemap.xml
[ ] Sitemap submitted: https://chopstickshq.com/rnitro/sitemap.xml
[ ] Request index: /rnitro/
[ ] Request index: /rnitro/faq.html
[ ] Request index: /rnitro/terms.html
[ ] Request index: /rnitro/privacy.html
```

## 4. Keywords we target

- rNitro / rnitro  
- free open source macos cpu monitor  
- free mac menu bar monitor  
- macOS system monitor Apple Silicon  
- free iStat alternative / open source menu bar app  
- btop mac alternative  

On-page: title, meta description, H1/H2, FAQ page, JSON-LD `SoftwareApplication` + `FAQPage`.

## 5. Off-site (you control, high impact)

- GitHub topics + README badges  
- AlternativeTo / Product Hunt listing  
- One honest post: r/MacApps or Show HN when shipping a feature  
- Ask for backlinks only where genuine  

## 6. After each major release

1. Redeploy getrnitro + HQ  
2. GSC → Sitemaps → refresh if sitemap changed  
3. Re-request indexing for `/rnitro/` and `/rnitro/faq.html` if content changed a lot  

## What is already automated

- Canonical + OG → `chopstickshq.com/rnitro/`  
- Rich results schema on product page + FAQ  
- Sitemaps with FAQ + lastmod  
- getrnitro marketing 301 → HQ (ranking signals consolidate)  
- FAQ at `/rnitro/faq.html`  

## Expectation

Organic ranking takes **days to weeks**, not minutes. GSC “Request indexing” only puts you in the queue—it does not guarantee page 1.
