-- Run this entire file once in Supabase > SQL Editor > New query.
-- Every table is protected by Row Level Security (RLS).
create table if not exists public.accounts (
 id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 name text not null, currency text not null check(currency in ('USD','CAD')),
 opening_balance numeric(14,2) not null default 0, created_at timestamptz not null default now()
);
create table if not exists public.categories (
 id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 name text not null, kind text not null check(kind in ('expense','income')),
 created_at timestamptz not null default now(), unique(user_id,name,kind)
);
create table if not exists public.transactions (
 id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 account_id uuid not null references public.accounts(id) on delete restrict,
 category_id uuid references public.categories(id) on delete set null,
 kind text not null check(kind in ('expense','income')),
 amount numeric(14,2) not null check(amount > 0), currency text not null check(currency in ('USD','CAD')),
 usd_amount numeric(14,2) not null check(usd_amount >= 0),
 fx_rate numeric(18,8) not null check(fx_rate > 0),
 occurred_on date not null, note text not null default '', created_at timestamptz not null default now()
);
create table if not exists public.budgets (
 id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 category_id uuid not null references public.categories(id) on delete cascade,
 month text not null check(month ~ '^\d{4}-(0[1-9]|1[0-2])$'),
 limit_usd numeric(14,2) not null check(limit_usd >= 0), unique(user_id,category_id,month)
);
create table if not exists public.transfers (
 id uuid primary key default gen_random_uuid(), user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
 from_account_id uuid not null references public.accounts(id) on delete restrict,
 to_account_id uuid not null references public.accounts(id) on delete restrict,
 from_amount numeric(14,2) not null check(from_amount > 0),
 to_amount numeric(14,2) not null check(to_amount > 0),
 occurred_on date not null, note text not null default '', created_at timestamptz not null default now(),
 check(from_account_id <> to_account_id)
);
-- Prevent cross-user foreign key references, including via a crafted API call.
create or replace function public.finance_validate_ownership() returns trigger language plpgsql set search_path = public as $$
begin
 if TG_TABLE_NAME='transactions' then
  if not exists(select 1 from public.accounts a where a.id=new.account_id and a.user_id=new.user_id and a.currency=new.currency) then raise exception 'Account/currency mismatch'; end if;
  if new.category_id is not null and not exists(select 1 from public.categories c where c.id=new.category_id and c.user_id=new.user_id and c.kind=new.kind) then raise exception 'Invalid category'; end if;
 elsif TG_TABLE_NAME='budgets' then
  if not exists(select 1 from public.categories c where c.id=new.category_id and c.user_id=new.user_id and c.kind='expense') then raise exception 'Invalid budget category'; end if;
 elsif TG_TABLE_NAME='transfers' then
  if not exists(select 1 from public.accounts a where a.id=new.from_account_id and a.user_id=new.user_id) or not exists(select 1 from public.accounts a where a.id=new.to_account_id and a.user_id=new.user_id) then raise exception 'Invalid transfer accounts'; end if;
 end if;
 return new;
end $$;
drop trigger if exists check_transactions_owner on public.transactions;
create trigger check_transactions_owner before insert or update on public.transactions for each row execute function public.finance_validate_ownership();
drop trigger if exists check_budgets_owner on public.budgets;
create trigger check_budgets_owner before insert or update on public.budgets for each row execute function public.finance_validate_ownership();
drop trigger if exists check_transfers_owner on public.transfers;
create trigger check_transfers_owner before insert or update on public.transfers for each row execute function public.finance_validate_ownership();
-- Enforce user ownership even if a client attempts to change user_id.
create or replace function public.finance_force_user() returns trigger language plpgsql set search_path=public as $$
begin
 if auth.uid() is null then raise exception 'Authentication required'; end if;
 new.user_id := auth.uid();
 return new;
end $$;
do $$ declare t text; begin foreach t in array array['accounts','categories','transactions','budgets','transfers'] loop
 execute format('drop trigger if exists force_user on public.%I',t);
 execute format('create trigger force_user before insert or update on public.%I for each row execute function public.finance_force_user()',t);
 execute format('alter table public.%I enable row level security',t);
 execute format('drop policy if exists own_rows on public.%I',t);
 execute format('create policy own_rows on public.%I for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()))',t);
 end loop; end $$;
