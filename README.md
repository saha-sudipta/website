# Quarto based website

Pages are: — About, Research, CV, Teaching, Contact — built as a
[Quarto](https://quarto.org) website. It's plain-text files (`.qmd` = Markdown
+ YAML), no build tools beyond Quarto itself, and it deploys as static HTML.

Built with help of Claude 

## 1. Install Quarto (one-time)

If you use RStudio, Quarto is likely already bundled (RStudio 2022.07+).
Otherwise, download the CLI: <https://quarto.org/docs/get-started/>

Check it worked:

```bash
quarto --version
```

## 2. Preview locally

From this folder:

```bash
quarto preview
```

This opens a live-reloading local preview — edit any `.qmd` or `styles.scss`
file and the browser updates automatically. Stop it with Ctrl+C.

In RStudio, you can instead just open `index.qmd` and click **Render**, or
open the project and use the **Build** pane.

## 3. Replace the placeholder content


### Files to add

- `images/headshot.jpg` — then in `index.qmd`, change
  `images/headshot-placeholder.svg` to `images/headshot.jpg`
- `files/cv.pdf`,  — see `files/README.txt`


## 4. Customize the look (optional)

All design tokens live at the top of `styles.scss` under `scss:defaults`:

- `$accent` — status badge
- `$brass` — secondary accent (years in the bibliography, course role labels)
- Fonts: `Newsreader` (headings), `Public Sans` (body), `IBM Plex Mono`
  (labels/eyebrows) — loaded from Google Fonts at the top of the `scss:rules`
  section. Swap the `@import` URL and the `$font-family-*` variables to
  change them.

## 5. Deploy to GitHub Pages

**Create the GitHub repo first** (via github.com or `gh repo create`), then
from this folder:

```bash
git init
git add .
git commit -m "Initial site"
git branch -M main
git remote add origin https://github.com/yourusername/yourusername.github.io.git
git push -u origin main
```

> Naming the repo `yourusername.github.io` gets you a site at the root
> domain (`https://yourusername.github.io`). Any other repo name works too —
> it'll publish to `https://yourusername.github.io/repo-name/` instead; in
> that case also set `site-url` in `_quarto.yml` accordingly.

Then publish with Quarto's built-in command:

```bash
quarto publish gh-pages
```

This renders the site and pushes it to a `gh-pages` branch, and GitHub Pages
serves it automatically. Re-run `quarto publish gh-pages` any time you want
to push updates.

> **Once you set up the `reports/` section below, use `./deploy.sh` instead
> of `quarto publish gh-pages` directly** — it does the same thing, but
> also encrypts `reports/` first. Running plain `quarto publish` after that
> point would push an unencrypted copy of your in-progress reports.

**Alternative:** if you'd rather have GitHub rebuild the site automatically
on every push (no need to run `quarto publish` yourself), use a GitHub
Actions workflow instead — Quarto's docs have a ready-made one:
<https://quarto.org/docs/publishing/github-pages.html#github-action>

## 6. The password-protected reports section

`reports/` is a separate mini-blog for sharing in-progress work with
collaborators — not linked from the main nav, excluded from search-engine
indexing, and encrypted so the actual content isn't served to anyone
without the password.

**How it's kept private, in three layers:**

1. **Not linked anywhere** on the public site — only reachable if someone
   has the direct URL.
2. **`noindex` + `robots.txt`** tell well-behaved search engines not to
   crawl or index it. One honest wrinkle: Quarto doesn't offer a way to
   exclude specific pages from its auto-generated `sitemap.xml` (its URLs
   will still get listed there), but `robots.txt` disallows crawling the
   `reports/` path regardless, so compliant crawlers won't fetch or index
   it even though the URL appears in the sitemap.
3. **Real encryption** via [StatiCrypt](https://github.com/robinmoisson/staticrypt):
   at deploy time, every page under `reports/` is AES-256 encrypted in the
   browser-crypto sense — without the password, visitors (and search
   engine crawlers) get ciphertext, not a hidden page. This is the layer
   that actually matters; (1) and (2) are just good manners on top of it.

Honest caveat, straight from StatiCrypt's own docs: this protects against
casual/accidental access and search engines, not a determined attacker —
it's one shared password, visible to anyone you give it to, and the
encrypted file itself is still publicly downloadable (just unreadable
without the password). **Don't put anything here you'd be genuinely
harmed by leaking** (e.g., IRB-restricted data, anything under a strict
embargo) — for that, use Cloudflare Access instead (see the note Claude
gave you in chat) or just share via a private Google Drive / Overleaf
folder instead of a webpage.

### Set up the password (one-time)

```bash
cp .env.example .env
```

Edit `.env` and set `STATICRYPT_PASSWORD` to a long, random, shared
password (16+ characters — a password manager like Bitwarden can generate
one). `.env` is gitignored, so this never gets committed. Share this same
password with your collaborators directly (Slack DM, in person, etc. —
not email, ideally).

### Adding a new report

Duplicate `reports/posts/2026-08-08-example-update/`, rename the folder,
and edit `index.qmd` inside it — see the instructions in that file. New
posts automatically show up on the `reports/` listing page, newest first.

### Deploying

Instead of `quarto publish gh-pages`, use the bundled script, which
renders, encrypts `reports/`, and publishes in the correct order:

```bash
./deploy.sh
```

(First run will prompt you to authorize with GitHub in a browser, same as
a normal `quarto publish` — that's expected.)

After the first successful run, commit `.staticrypt.json` (it holds a
non-secret salt, not your password — keeping it stable means your
collaborators' browsers stay logged in across deploys instead of being
asked for the password again every time you push an update).

### Sharing access with collaborators

Send them two things, separately if you want to be careful:

- The link: `<your-site-url>/reports/`
- The password (from your `.env` file)

They'll see a password prompt once; if they check "Remember me" they won't
be asked again for 30 days on that browser (adjust `--remember` in
`deploy.sh` to change this).

### Rotating the password

Change `STATICRYPT_PASSWORD` in `.env` and run `./deploy.sh` again — this
re-encrypts everything with the new password. Anyone with the old password
loses access (their "remembered" session will also stop working next time
`quarto publish` runs, though it stays valid client-side until then).

## Folder structure

```
_quarto.yml     site config: nav bar, footer, theme
styles.scss     colors, fonts, layout — the site's visual identity
index.qmd       About / home page
research.qmd    research statement, job market paper, publications
cv.qmd          CV download + skimmable summary
teaching.qmd    teaching philosophy + courses
contact.qmd     contact info
images/         headshot + favicon
files/          CV and paper PDFs
robots.txt      tells crawlers not to index reports/

reports/                  private, unlisted reports section (see above)
  _metadata.yml             noindex header + excluded from Quarto search, for everything in here
  noindex.html              the actual <meta robots noindex> tag
  index.qmd                 listing page
  posts/2026-.../index.qmd  individual reports — duplicate to add new ones

deploy.sh        render + encrypt reports/ + publish, in one command
.env.example     template for your StatiCrypt shared password
```
