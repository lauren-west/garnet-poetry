# Garnet Girls Poetry Club

A 16-day poetry challenge site: eight prompts, four poets, each poem due 48 hours after its prompt drops.

- `index.html` is the whole site (calendar, a bit of inspiration from a random poem, submissions, roasts, Hall of Shame).
- `config.js` holds the Supabase URL and anon key.
- `supabase/schema.sql` sets up the poem table and file storage.

## Setup

1. Create a free project at [supabase.com](https://supabase.com).
2. In the project, open **SQL Editor**, paste `supabase/schema.sql`, and run it.
3. In **Project Settings → API**, copy the Project URL and the `anon` public key into `config.js`.
4. Push to `main`. GitHub Pages serves the site from the repo root.

## Notes

- Submission times come from the database clock, so they can't be faked.
- The site has no logins: anyone with the link can read the poems and submit one.
- Poems can't be edited or deleted from the site. To remove one, delete its row in Supabase → Table Editor.
