{{ config(materialized='table') }}

select
    account_id,
    company_name,
    industry,
    region,
    signup_date,
    total_subscriptions,
    active_subscriptions,
    churned_subscriptions,
    mrr_outlier_subscriptions,
    has_active_subscription,
    active_seats,
    active_mrr,
    first_subscription_date,
    total_users,
    admin_users,
    users_with_login
from {{ ref('int_account_rollup') }}
