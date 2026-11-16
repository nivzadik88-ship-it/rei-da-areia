# Changelog

## 1.19.0
- Career goal: reach R$ 1,000,000 in 3 seasons of 4 tournaments (CBFUT, TAFC, Open Nacional, Liga Grande Final). Each tournament plays a short version of its real format (repechage, double elimination, best of 3 sets, group + no deuce).
- New flow: your team → training camp → tactics → meet your rivals → live tournament → payday → career decision → road map.
- Live matches with must-win moments, a 50/50 clutch read at 17-17, golden point finals and a premium knockout arena.
- New tactics: Shark, Powerful Header, Pingo, Águia vs Shark / Pingo / Line / Lob Defense.
- Career decisions are yes/no gambles. Money HUD, payday screen, richest-in-Brazil ladder. OVR grows towards 100 over the seasons; category badges.
- Social leaderboards: the R$ 1M race (all careers) and a daily challenge. Needs the `scores` table from schema.sql.
- Brazilian Portuguese (EN / PT-BR switch on every screen). First-time tutorial with replay.
- Analytics: optional PostHog (set `posthogKey` in config.js) next to the built-in Supabase events.

## 1.3.0
- Header: 8 stop segments (gold = title) instead of a log-scale money bar; "% of 1M" is accurate.
- Training: tap the skills you want to train (up to 3), "Coach picks" shortcut, two weekly specials, live "after training" bar. New Chest session.
- Game Plan: top-down court - your shot in gold, their favourite in red, defence shows stopped / half / open. First-visit explainer + "?" help.
- Partner: celebration popup on signing, partner card (tap his face) with strength, trait, side fit, chemistry and growth; he appears on the court, road and results.
- Golden point: odds depend on your skill, shot level, partner's specialty and the rival (30-78%), shown on each option.
- "Beach practice" renamed "Match prep". R$ on every amount. "Fitness" is now "Energy". Less text on raffle, create, road and popups. Curved road with fixed path drawing.

## 1.2.0
- Picking a face, side, club, ball or option no longer jumps the page back to the top.
- Mobile fold: every gameplay screen and result popup fits a regular phone without scrolling (player card beside name/shirt, tighter HUD and buttons, beach practice shows only your game once played, smaller popup trophies and tiles).

## 1.1.0
- Online ranking (all-time + weekly), shareable career links, weekly challenge with the same draws for everyone.
- Anonymous analytics (no cookies) and a stats page at `/stats.html`.
- Version number on the home screen.

## 1.0.0
- First public release on GitHub Pages.
