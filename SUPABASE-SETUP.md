# Shared order login setup

The customer and manager workspaces use Supabase for shared authentication and orders. Do not put a Supabase `service_role` key in this website.

## Configure Supabase

1. Create a Supabase project and open its SQL Editor.
2. Run `supabase/schema.sql` to create the profiles and orders tables, access policies, and realtime publication.
3. In Authentication settings, enable Phone sign-in and configure an SMS provider. Add `http://localhost:5173` and your eventual HTTPS website address to the allowed redirect URLs.
4. Create the restaurant manager's email/password user in Authentication > Users.
5. Promote that user in the SQL Editor, replacing the email:

   ```sql
   update public.profiles
   set role = 'manager'
   where id = (select id from auth.users where email = 'manager@example.com');
   ```

## Configure this app

1. Copy `.env.example` to `.env.local`.
2. Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` from the Supabase project's API settings. The publishable/anon key is intended for browser use; database row-level security protects the data.
3. Run `npm run dev` and open `http://127.0.0.1:5173/`.

Customers sign in with their phone and SMS code. The manager signs in with the email/password created above. Orders are stored centrally, customers can read only their own orders, and only managers can update order status.

## Before taking live orders

The menu is still rendered from static HTML, so the submitted subtotal is a customer-side estimate and must be confirmed by the restaurant. For production, validate item names and prices on a trusted server before treating an order total as final. Deploy the site over HTTPS and configure the same environment variables and allowed URLs on the hosting provider. SMS delivery may require a paid provider account.