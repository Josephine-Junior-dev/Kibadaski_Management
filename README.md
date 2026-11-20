# Kibadaski Management

A universal, mobile-first business management system for small businesses: kibandas, cafés, food vendors, mini-shops, salons, service providers and other owner-operated businesses.

## Product direction
The Mwende kibanda workflow is our first real-world use case, not the limit of the product. Each customer configures their own business name, business type, currency, products/services, categories and prices.

## Core modules
- Business setup and profile
- Dashboard with sales, cash received, credit sales, outstanding customer balances, purchases and expenses
- Product/service catalogue with editable prices and optional cost/stock tracking
- Fast sales entry with multiple line items and cash, partial-payment or customer-credit workflows
- Named customer accounts, running balances, payment history and statements
- Purchases and supplier records
- Business expenses
- Daily, weekly, monthly and custom-date reports
- Printable reports and customer statements
- Mobile-first interface
- Supabase Auth and Row Level Security

## Architecture
- Frontend: HTML, CSS and JavaScript (GitHub Pages-compatible)
- Backend: Supabase
- Database tables use the `km_` prefix and are isolated from other apps in the shared Supabase project.
- Every business record is scoped to a business and protected by RLS.
- Browser code uses only the Supabase anon/publishable key. Never expose a service-role key.

## Initial setup
1. Run `schema.sql` in the SQL Editor of the chosen Supabase project.
2. Copy the Supabase project URL and anon/publishable key into `config.js`.
3. Enable Email authentication in Supabase.
4. Publish the static frontend using GitHub Pages.
5. Create the first owner account and complete business setup.

## Product principles
- Make routine sale entry possible in a few taps.
- Keep cash sales, credit sales and credit repayments separate.
- Calculate each customer's balance from their ledger, not from manually typed totals.
- Keep business data private between different business owners.
- Avoid claiming accounting profit unless cost-of-goods data is configured accurately.
- Make advanced stock, staff permissions, subscriptions and integrations modular additions.

## Status
Foundation repository. Build and test the onboarding, core sales ledger, customer credit ledger and reports before onboarding paying businesses.
