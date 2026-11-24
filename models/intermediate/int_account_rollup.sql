with accounts as (

    select *
    from {{ ref('stg_accounts') }}

),

subscription_metrics as (

    select
        account_id,
        count(*) as total_subscriptions,
        countif(subscription_status = 'active') as active_subscriptions,
        countif(subscription_status = 'churned') as churned_subscriptions,
        countif(is_mrr_outlier) as mrr_outlier_subscriptions,
        coalesce(sum(case when subscription_status = 'active' then seats else 0 end), 0) as active_seats,
        coalesce(sum(case when subscription_status = 'active' then coalesce(mrr, 0) else 0 end), 0) as active_mrr,
        min(started_date) as first_subscription_date
    from {{ ref('stg_subscriptions') }}
    group by account_id

),

user_metrics as (

    select
        account_id,
        count(*) as total_users,
        countif(user_role = 'admin') as admin_users,
        countif(last_login_date is not null) as users_with_login
    from {{ ref('stg_users') }}
    group by account_id

)

select
    a.account_id,
    a.company_name,
    coalesce(a.industry, 'Unknown') as industry,
    a.region,
    a.signup_date,
    coalesce(s.total_subscriptions, 0) as total_subscriptions,
    coalesce(s.active_subscriptions, 0) as active_subscriptions,
    coalesce(s.churned_subscriptions, 0) as churned_subscriptions,
    coalesce(s.mrr_outlier_subscriptions, 0) as mrr_outlier_subscriptions,
    coalesce(s.active_subscriptions, 0) > 0 as has_active_subscription,
    coalesce(s.active_seats, 0) as active_seats,
    coalesce(s.active_mrr, 0) as active_mrr,
    s.first_subscription_date,
    coalesce(u.total_users, 0) as total_users,
    coalesce(u.admin_users, 0) as admin_users,
    coalesce(u.users_with_login, 0) as users_with_login
from accounts as a
left join subscription_metrics as s
    on a.account_id = s.account_id
left join user_metrics as u
    on a.account_id = u.account_id
