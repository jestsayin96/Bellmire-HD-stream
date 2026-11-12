# Fonts served by the hub

Self-hosted on purpose. docs/HUB_SECURITY.md forbids third-party scripts, fonts
and CDNs, and the page's Content-Security-Policy has `font-src 'self'` - a
Google Fonts link would be refused by the browser and would hand a third party
a request from every viewer. These files are committed to the repo and served
from the same origin as the page.

| file | face | licence |
|---|---|---|
| gloock-latin-400.woff2 | Gloock Regular, latin | SIL Open Font License 1.1 - Gloock-OFL.txt |
| gloock-latin-ext-400.woff2 | Gloock Regular, latin-ext | same |

Gloock is the high-contrast display serif of the Bellmire HD title card. It is
used for the wordmark and section titles ONLY - never for body text, and never
for numbers. Research note (web/NOTES.md): decorative faces confuse 1/l/I and
0/O, which is exactly the wrong failure for a leaderboard, so every figure on
this page is set in the UI face with tabular numerals.

Source: the @fontsource/gloock npm package (v5.3.0), which repackages the
Google Fonts release. Upstream: https://github.com/duartp/gloock
Copyright 2022 The Gloock Project Authors.
