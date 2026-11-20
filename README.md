# WorkProof AI

Mobile-first job, work-evidence and payment tracking workspace for Indian service businesses.

## MVP included

- Create and manage service jobs with customer, location, amount and due date
- Workflow statuses: in progress, awaiting approval, completed
- Evidence file metadata list per job
- Track amount received and outstanding balance
- Search and filter jobs
- Export jobs as CSV and download an individual job report
- Responsive graphite dashboard for mobile and desktop

## Run locally

Requirements: Node.js 20.9+.

```bash
npm install
npm run dev
```

Open http://localhost:3000.

## Demo mode — important

The first milestone uses browser localStorage and preloaded sample jobs. Changes remain in that browser only. The evidence picker records file names and metadata; it does **not** upload file bytes. Do not enter real customer personal data or use demo records as a permanent backup.

## Supabase production foundation

The `supabase/schema.sql` file defines a tenant-owned PostgreSQL data model, Row Level Security policies and a private evidence bucket. To move beyond demo mode:

1. Create a Supabase project and run `supabase/schema.sql` in its SQL Editor.
2. Integrate Supabase Auth with server-side session verification.
3. Replace localStorage with authenticated database reads/writes.
4. Upload evidence bytes to the private Storage bucket using per-user paths.
5. Add customer approval links with expiring, single-use tokens.
6. Add payment reconciliation only after payment-provider onboarding and verified webhooks.

Never expose a Supabase secret/service-role key in browser code.

## Build

```bash
npm run build
```

WorkProof AI organizes user-submitted records. It does not independently certify job quality, prove job completion, guarantee payment, or act as an escrow service.
