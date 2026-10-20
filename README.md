# Northstar — Private CAD/USD Finance Tracker

A free static website with a private Supabase database. Includes email/password login, CAD/USD exchange rates, multiple bank accounts, expense/income transactions, monthly budgets, transfers, and editable categories.

## 1. Create a free Supabase project

1. Go to https://supabase.com and create a free account and project. Store the **database password** somewhere safe.
2. Open **SQL Editor** > **New query**, paste the entire contents of `schema.sql`, and click **Run**. This creates your tables and Row Level Security policies.
3. Go to **Authentication** > **Providers** > **Email**. Keep Email enabled. Turn **off** "Allow new users to sign up" (wording may vary by dashboard version). You will create your own user manually.
4. Under **Authentication** > **Users**, click **Add user** > **Create new user**. Enter your email and a strong, unique password; select **Auto confirm** if offered. Do not use a password you reuse elsewhere. (If manual creation isn't available, temporarily enable signups, create your account, then immediately disable signups.)
5. Under **Project Settings** > **API Keys** (or **Connect** in newer dashboards), copy your **Project URL** and **publishable key** (`sb_publishable_...`) or legacy **anon public** key. Never use the secret/service_role key.

## 2. Configure the website

Open `config.js` in a text editor. Replace the two PASTE_... strings with your project URL and publishable/anon key. Save the file. These two values are intended for browser use; security comes from Supabase authentication and RLS, **not** from hiding the key.

## 3. Publish with GitHub Pages for free

1. Sign in at https://github.com, click **New repository**, name it `northstar-finances`, choose **Public**, then **Create repository**.
2. Click **Add file** > **Upload files** and upload `index.html`, `style.css`, `app.js`, `config.js` and `schema.sql` (README optional). Commit changes. Never upload passwords, bank login credentials, or Supabase secret keys.
3. In repository **Settings** > **Pages**, choose **Deploy from a branch**, branch **main**, folder **/(root)**, and Save.
4. Wait a few minutes. GitHub will show a URL like `https://YOUR-USERNAME.github.io/northstar-finances/`.
5. Open the URL, sign in with the email and password you created in Supabase.

**Important:** The GitHub repository and source code are public, but your account balances and transactions are stored in Supabase with per-user database access rules. Your finance data is NOT stored in the GitHub repository. This is appropriate for a personal tracker, not for storing bank passwords, SSNs, or payment-card numbers.

## 4. Start tracking

1. Click **Edit mode** > **+ Account**. Create your U.S. and Canadian accounts with their currencies and their balances as of your starting date.
2. In Edit mode add categories such as Rent, Groceries, Transport, Insurance, Entertainment, Paycheck and Other Income. Select expense/income correctly.
3. Select the budget month, then use **Set budget** on each expense category to enter a monthly USD limit.
4. Click **Add transaction** for income or spending. Choose the actual account; its currency is applied automatically. Each transaction stores the USD equivalent at the *latest available reference rate at entry time*, not necessarily the historical rate on its date.
5. Use **Transfer** when moving funds between your own accounts, including USD↔CAD conversions. Enter the actual amount sent and received. Transfers change balances but don't count toward monthly income/expenses.
6. Switch **Display USD / Display CAD** any time. The overall account total uses the latest available exchange rate, while monthly transaction budget totals use saved USD values.

## Notes / limitations

- Frankfurter (https://frankfurter.dev) publishes reference exchange rates that are typically updated on business days, not streaming live prices. Actual Wise/bank rates and fees differ. If offline, the most recent rate cached in that browser is used. Without any available rate, CAD entries can't be saved.
- The tracker is **manual**; it does not connect to your banks or automatically import transactions.
- Monthly budget limits are stored in USD. Switching display currency converts them for display.
- A transaction is recorded in the account's currency. For a historical CAD transaction, the tracker stores the reference rate available **when you enter/edit it**, not necessarily the rate on the transaction date.
- Editing account opening balances changes calculated balances; do not count transfers as income.
- Deleting an account that has transactions/transfers is blocked to protect history. Deleting a category leaves its historical transactions uncategorized.
- Free plans can have limits, pause inactive projects, and change terms. Export/back up your data periodically using Supabase dashboard's database export/backup options where available. This starter version does not include an in-app export.
- This is not bank-grade financial software and should not store sensitive account identifiers or passwords.
