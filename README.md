# CloudDesk SaaS Analytics — dbt Pipeline (ALY6600 Mini Project 2)

## 1. Business Context
CloudDesk is a B2B SaaS platform whose customer accounts hold subscriptions, register users, and open customer support tickets. This dbt project transforms four raw BigQuery tables (`parabolic-eon-481321-m3.mp2`) into a clean, tested, and documented three-layer analytics pipeline plus an SCD Type 2 subscription snapshot.

## 2. Three-Layer Architecture & Layer Boundaries
All model dependencies use `{{ source(...) }}` in staging/snapshots and `{{ ref(...) }}` in intermediate, marts, and tests—there are zero hardcoded table names.

| Layer | Materialization | Models | Responsibility |
| :--- | :--- | :--- | :--- |
| **Staging** (`models/staging/`) | `view` | `stg_accounts`, `stg_subscriptions`, `stg_users`, `stg_tickets` | Cleaning, renaming, and type casting only: normalizes casing (`status`, `role`, `priority`), converts blank strings to `NULL`, and isolates the 17 sentinel `mrr = 99999` outliers into `is_mrr_outlier`. |
| **Intermediate** (`models/intermediate/`) | `view` | `int_account_rollup`, `int_tickets_enriched` | Carries joining and grain reshaping: aggregates 1-to-many subscriptions (70 rows) and users (301 rows) to 1 row per `account_id` (60 rows) to prevent fan-out; calculates ticket `resolution_hours`, `sla_target_hours`, and `is_sla_met`. |
| **Marts** (`models/marts/`) | `table` | `dim_accounts`, `fct_tickets` | Thin, query-ready star-schema tables materialized in BigQuery for BI consumption (60 accounts, 600 tickets). |
| **Snapshot** (`snapshots/`) | `table` | `snp_subscriptions` | Tracks SCD Type 2 history of `plan`, `seats`, `mrr`, and normalized `status` per `subscription_id`. |

## 3. Snapshot Strategy Rationale (`check` vs `timestamp`)
`snp_subscriptions` uses `strategy='check'` on `['plan', 'seats', 'mrr', 'status']` with `unique_key='subscription_id'` rather than `strategy='timestamp'`. Although the raw `subscriptions` table contains an `updated_at` column, profiling revealed **8 of 70 rows have `updated_at < started_at`** (e.g., `subscription_id = 2` has `started_at = 2024-07-10` and `updated_at = 2024-01-04`), proving `updated_at` is not reliably maintained by the upstream source. Using `check` guarantees that plan upgrades, seat changes, MRR updates, and churn events are captured reliably even when `updated_at` fails to advance, while lowercasing `status` in the snapshot query avoids false Type 2 versions from `active` vs `Active`.

## 4. Annotated Data Quality Tests
The suite covers all five required test types (`unique`, `not_null`, `accepted_values`, `relationships`, and custom SQL tests), placed where the CloudDesk pipeline is most vulnerable:

| Test | Model & Column | Why It Matters Here & Downstream Impact If Broken |
| :--- | :--- | :--- |
| `unique` + `not_null` | `dim_accounts.account_id`, `int_account_rollup.account_id`, `fct_tickets.ticket_id`, `stg_users.email` | Guards table grain against 1-to-many subscription/user fan-out (24 accounts have multiple subscriptions) and duplicate user identities; failure double-counts ticket volume, active MRR, or total users in marts. |
| `accepted_values` | `stg_subscriptions.subscription_status`, `stg_users.user_role`, `fct_tickets.priority`, `fct_tickets.ticket_status` | Catches raw casing defects (`active`/`Active`, `admin`/`Admin`, `High`/`high`/`URGENT`, `closed`/`Closed`). Failure causes metrics using exact filters (`active_mrr`, `admin_users`, `sla_target_hours`) to drop rows or assign wrong SLA targets. |
| `relationships` | `stg_subscriptions.account_id` -> `stg_accounts`, `fct_tickets.account_id` -> `dim_accounts` | Prevents orphaned subscriptions or tickets from silently disappearing in BI inner joins or account rollups. |
| `not_null` | `fct_tickets.opened_at` | Protects SLA anchor timestamps while intentionally leaving `closed_at` nullable for the 170 open tickets. |
| Custom SQL (`assert_ticket_resolution_timeline.sql`) | `fct_tickets` | Enforces that `open` tickets have `closed_at IS NULL` and `closed`/`resolved` tickets have `closed_at >= opened_at`; protects `resolution_hours` and `is_sla_met` from negative or missing durations. |
| Custom SQL (`assert_valid_subscription_mrr.sql`) | `stg_subscriptions` | Enforces valid MRR bounds (`0 < mrr < 99999` when non-null); prevents the 17 raw `99999` sentinel rows from leaking into `dim_accounts.active_mrr`. |

## 5. How to Run
```bash
dbt debug
dbt snapshot
dbt run
dbt test
dbt docs generate && dbt docs serve
```
