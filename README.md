# Rei da Areia

A footvolley career game. Start on Copacabana with R$ 5,000, survive 8 tournaments, and try to finish with **R$ 1 million**.

Plain static site (one `index.html`, no build step) + a Supabase database for the online features:

- **Ranking**: every finished career is posted; all-time and weekly boards.
- **Share a career**: each career gets a link (`?c=<id>`) with its money chart and trophy wall.
- **Weekly challenge**: everyone plays with the same draws (partners, rivals, events) for the ISO week.

## Setup

### 1. Supabase (once)
1. Open your project → **SQL Editor** → paste `schema.sql` → **Run**.
2. **Project Settings → API**: copy the **Project URL** and the **anon public** key.

### 2. Config
Put both values in `config.js`:

```js
window.REI_CONFIG = {
  supabaseUrl: 'https://YOUR-PROJECT.supabase.co',
  supabaseAnonKey: 'eyJ...anon key...',
};
```

The anon key is meant to be public. Row-level security only lets it **read** careers and **submit** through `submit_career()`, which sanity-checks every career. Never put the `service_role` key here.

### 3. GitHub Pages
Push this folder to the repo's `main` branch → **Settings → Pages** → *Deploy from a branch* → `main` / `/ (root)`.
The game is live at `https://<user>.github.io/<repo>/` within a minute. A custom domain can be added on the same page.

## Files
| File | What it is |
|---|---|
| `index.html` | The whole game (art, sounds and code embedded) |
| `config.js` | Supabase URL + anon key (empty = offline mode) |
| `schema.sql` | Tables, security rules, `submit_career()`, the `leaderboard` view, analytics `events` + `stats_overview()` |
| `og.jpg`, `icon.png` | Link preview image and home-screen icon |
| `stats.html` | Analytics dashboard (not linked from the game) |
| `deploy.sh`, `CHANGELOG.md` | Release helper and version history |

## Analytics
Open `/stats.html` on your site (e.g. `https://nivzadik88-ship-it.github.io/rei-da-areia/stats.html`).
It shows visitors, careers started/finished, how many reached R$ 1M, how far careers get, choices players make, offers accepted, devices and traffic sources.
Events are anonymous (a random browser id, no cookies, no names). The page only ever receives totals.

## Deploying a new version
Every push to `main` goes live on GitHub Pages in about a minute.
- **From Claude:** ask for the change; Claude edits and pushes it with your token.
- **By hand:** GitHub → the repo → **Add file → Upload files** → drop the new `index.html` → **Commit changes**.
- **From a terminal:** `./deploy.sh "what changed"`.
Bump `APP_VERSION` in the game and add a line to `CHANGELOG.md` for each release; the stats page shows which versions people play.

## Moderation
Remove a career: Supabase → Table editor → `careers` → delete the row.
