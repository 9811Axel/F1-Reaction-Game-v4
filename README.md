# F1 Reaction Challenge (GitHub Pages + Supabase)

This project is a static frontend you can host on **GitHub Pages**, backed by **Supabase** for:
- real multi-user auth (login/signup)
- a real multi-user leaderboard (best valid reaction time per user)

## 1) Create Supabase project
1. Go to [Supabase](https://supabase.com/) and create a new project.
2. Open **Authentication** settings.
3. For the simplest experience: **disable email confirmations** so users can sign up and log in immediately.

## 2) Run the database SQL
1. In Supabase, open **SQL Editor**.
2. Run the contents of `supabase_setup.sql` (file in this repo).

This creates:
- `public.profiles` (stores `country`)
- `public.attempts` (stores reaction attempts, optional `display_name` per row for “Today” leaderboard)
- `public.leaderboard_best_times` (SQL view used for all-time best)
- `public.leaderboard_avg_times` (SQL view used for “Best average” leaderboard)

If you already ran an older version of `supabase_setup.sql`, re-run it (or at least apply the schema update) so `public.profiles.display_name` exists, `attempts.display_name` exists, `leaderboard_best_times` returns `display_name`, and `leaderboard_avg_times` exists.

## 3) Configure the frontend with your Supabase keys
1. Open `index.html`.
2. Replace these placeholders:
   - `PASTE_SUPABASE_PROJECT_URL`
   - `PASTE_SUPABASE_ANON_KEY`

You can find both values in Supabase:
- Project Settings -> API -> Project URL
- Project Settings -> API -> anon public key

## 4) Deploy to GitHub Pages
1. Create a new GitHub repository.
2. Upload these files to the repo (commit them):
   - `index.html`
   - `supabase_setup.sql` (optional, but recommended for reference)
   - `README.md`
3. Go to **Repository Settings** -> **Pages**.
4. Set:
   - Source: **Deploy from a branch**
   - Branch: `main`
   - Folder: `/ (root)`
5. Wait for Pages to finish building and give you a URL.

## Notes / troubleshooting
- If sign-up/login complains about confirming email, enable email confirmation flow or (recommended) disable email confirmations in Supabase.
- The leaderboard shows users who have at least one **valid** attempt (`reaction_time_ms >= 100`).
- GitHub Pages is static, so you must use Supabase (or another backend) for multi-user data.

