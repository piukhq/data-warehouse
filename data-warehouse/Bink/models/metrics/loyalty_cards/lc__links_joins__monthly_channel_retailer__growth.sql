/*
Created by:         CHRISTOPHER MITCHELL
Created date:       2023-11-15
Last modified by: Anand Bhakta
Last modified date: 2023-12-19

Description:
        Convert the lc__links_joins__monthly_channel_brand_retailer table to growth metrics.
Parameters:
    source_object       - lc__links_joins__monthly_channel_brand_retailer
*/

{{convert_to_growth("lc__links_joins__monthly_channel_brand_retailer",
                    ["DATE", "LOYALTY_PLAN_NAME", "LOYALTY_PLAN_COMPANY","CHANNEL"],
                    ["BRAND"],
                    ["LOYALTY_PLAN_NAME", "LOYALTY_PLAN_COMPANY","CHANNEL"],
                    "DATE",
                    "_BRAND" )
}}
