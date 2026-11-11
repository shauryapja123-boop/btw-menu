# Shared order login setup

The customer and manager workspaces use Supabase for shared authentication and orders. Do not put a Supabase `service_role` key in this website.

## Configure Supabase

1. Create a Supabase project and open its SQL Editor.
2. Run `supabase/schema.sql` to create the profiles and orders tables, access policies, and realtime publication.
3. In Authentication settings, enable Phone sign-in and configure an SMS provider. Add `http://127.0.0.1:5173` and your eventual HTTPS website address to the allowed redirect URLs.
4. Create the restaurant manager's email/password user in Authentication > Users.
5. Promote that user in the SQL Editor, replacing the email:

   ```sql
   update public.profiles
   set role = 'manager'
   where id = (select id from auth.users where email = 'manager@example.com');
   ```

## Publish this app with GitHub Pages

1. In the GitHub repository, open Settings > Secrets and variables > Actions > Variables.
2. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` from the Supabase project's API settings. The publishable/anon key is intended for browser use; database row-level security protects the data. Never use a `service_role` key here.
3. Open Settings > Pages and set the build and deployment source to GitHub Actions.
4. Push this workflow and the Vite config to the repository's `main` branch. The workflow builds both the menu and QR page and deploys `dist` to `https://shauryapja123-boop.github.io/btw-menu/`.
5. In Supabase Authentication URL settings, add `https://shauryapja123-boop.github.io/btw-menu/` to the allowed site URLs / redirect URLs. Keep `http://127.0.0.1:5173` for local work.

The included `.github/workflows/deploy.yml` redeploys after every push to `main`. GitHub Pages must use the GitHub Actions source for the compiled Supabase client and Vite assets to load correctly.

## Run locally

1. Copy `.env.example` to `.env.local`.
2. Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` from the Supabase project's API settings.
3. Run `npm run dev` and open `http://127.0.0.1:5173/`.

Customers sign in with their phone and SMS code. The manager signs in with the email/password created above. Orders are stored centrally, customers can read only their own orders, and only managers can update order status.

## Before taking live orders

The menu is still rendered from static HTML, so the submitted subtotal is a customer-side estimate and must be confirmed by the restaurant. For production, validate item names and prices on a trusted server before treating an order total as final. SMS delivery may require a paid provider account.