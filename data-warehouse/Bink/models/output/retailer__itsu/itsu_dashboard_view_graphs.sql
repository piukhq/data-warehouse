/*
Created by:         Christopher Mitchell
Created date:       2023-10-02
Last modified by:   Christopher Mitchell
Last modified date: 2024-01-08

Description:
    Datasource to produce tableau dashboard for itsu graphs
Parameters:
    source_object       - lc__links_joins__monthly_retailer
                        - trans__trans__monthly_retailer
                        - trans__avg__monthly_retailer
                        - user__transactions__monthly_retailer
*/
with
lc_metric as (
    select
        *,
        'JOINS' as category
    from {{ ref("lc__links_joins__daily_retailer") }}
    where loyalty_plan_company = 'itsu'
),

txn_metrics as (
    select
        *,
        'SPEND' as category
    from {{ ref("trans__trans__daily_retailer") }}
    where loyalty_plan_company = 'itsu'
),

combine_all as (
    select
        date,
        category,
        loyalty_plan_name,
        loyalty_plan_company,
        lc067__successful_loyalty_card_joins__daily_retailer__csum,
        lc047__successful_loyalty_card_joins__daily_retailer__count,
        null as t027__spend__daily_retailer__csum,
        null as t033__spend__daily_retailer__sum
    from lc_metric
    union all
    select
        date,
        category,
        loyalty_plan_name,
        loyalty_plan_company,
        null as lc067__successful_loyalty_card_joins__daily_retailer__csum,
        null as lc047__successful_loyalty_card_joins__daily_retailer__count,
        t027__spend__daily_retailer__csum,
        t033__spend__daily_retailer__sum
    from txn_metrics
)

select *
from combine_all
