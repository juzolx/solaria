# Turning on Solaria's online features

The leaderboard, guilds and weekly raids run on **Supabase**, a free hosted
database. The game works fine without it; the Online tab just tells you it's off.

Setup takes about 5 minutes and only has to be done once (by you, the developer).
Players never see any of this.

## 1. Make a Supabase project

1. Go to https://supabase.com and sign up (free).
2. Click **New project**. Name it `solaria`, make up a database password
   (save it somewhere), and pick the region closest to you (West US for Washington).
3. Wait a minute or two while it sets up.

## 2. Allow name-only logins

Players don't make an account with an email; the game logs them in quietly.

1. In the left menu go to **Authentication**, then **Sign In / Providers**.
2. Turn on **Allow anonymous sign-ins** and press **Save**.

## 3. Create the tables

1. In the left menu open **SQL Editor**, then **New query**.
2. Open `supabase_setup.sql` from the game folder, copy all of it, and paste it in.
3. Press **Run**. You should see "Success. No rows returned".

(It's safe to run again later if you ever update it.)

## 4. Connect the game

1. Go to **Project Settings** (gear icon), then **API** / **API Keys**.
2. Copy the **Project URL** (looks like `https://abcdxyz.supabase.co`).
3. Copy the **anon public** key (starts with `eyJ...`) or the **publishable** key
   (starts with `sb_publishable_...`). Either one works.
4. In Godot, open `online_config.gd` and paste them between the quotes:

```gdscript
const SUPABASE_URL := "https://abcdxyz.supabase.co"
const ANON_KEY := "eyJhbGciOi..."
```

5. Save, press F5, open the **Online** tab and pick your name.

## Good to know

- The anon/publishable key is meant to be inside the game. Your database rules
  (in the SQL file) make sure players can only change their own rows.
- **Never** put the `service_role` / secret key in the game.
- Free projects pause after a week with no activity. If online stops working,
  open the Supabase dashboard and press **Restore**.
- Supabase limits anonymous sign-ups to 30 per hour per internet connection by
  default. That's plenty for playtesting; you can raise it under
  Authentication > Rate Limits.
- Hardcore runs are sent to the leaderboard when a Hardcore hero dies (if you've
  picked a name).
- Raid rules: each guild gets a boss every week (Monday to Sunday, UTC). Every
  member can attack 3 times a day. If the guild beats it, every member can claim
  a reward once.
