/*
Created by:         Anand Bhakta
Created date:       2023-08-03
Last modified by:    
Last modified date: 

Description:
    Datasource to produce tableau dashboard for Viator 12 month rolling datasource
Parameters:
    source_object       - viator_dashboard_view
*/
with
    unpivot as (
        {{
            dbt_utils.unpivot(
                relation=ref("viator_dashboard_view"),
                cast_to="number(38,2)",
                exclude=[
                    "date",
                    "category",
                    "loyalty_plan_company",
                    "loyalty_plan_name",
                ],
                field_name="metric",
                value_name="value",
            )
        }}
    ),
    refs as (
        select *
        from {{ ref("src__retailer_lookups_viator_metrics_ref") }}
        where dashboard = '12_MONTH_ROLLING'
    ),
    rename as (
        select
            date,
            u.category,
            u.loyalty_plan_company,
            u.loyalty_plan_name,
            u.metric,
            r.metric_name,
            u.value
        from unpivot u
        left join refs r on r.metric_ref = u.metric
        where value is not null
    )

select *
from rename
