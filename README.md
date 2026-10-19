# Rei da Areia

A footvolley career game. Start on Copacabana with R$ 5,000, survive 8 tournaments, and try to finish with **R$ 1 million**.

Plain static site (one `index.html`, no build step) + a Supabase database for the online features:

- **Ranking**: every finished career is posted; all-time and weekly boards.
- **Share a career**: each career gets a link (`?c=<id>`) with its money chart and trophy wall.
- **Weekly challenge**: everyone plays with the same draws (partners, rivals, events) for the ISO week.

## Setup

### 1. Supabase (once)
1. Open your project → **SQL Editor** → paste `supabase/schema.sql` → **Run**.
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
| `supabase/schema.sql` | Table, security rules, `submit_career()` and the `leaderboard` view |
| `og.jpg`, `icon.png` | Link preview image and home-screen icon |

## Moderation
Remove a career: Supabase → Table editor → `careers` → delete the row.
