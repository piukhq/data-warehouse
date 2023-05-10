WITH lc_joins_links AS (
    SELECT *
    FROM {{ref('lc_joins_links')}}
)

,lc_joins_links_snapshot AS (
    SELECT *
    FROM {{ref('lc_joins_links_snapshot')}}
)

,base_table AS (
    SELECT DISTINCT
        DATE
        ,BRAND
        ,LOYALTY_PLAN_NAME
        ,LOYALTY_PLAN_COMPANY
    FROM lc_joins_links
    UNION
    SELECT DISTINCT
        DATE
        ,BRAND
        ,LOYALTY_PLAN_NAME
        ,LOYALTY_PLAN_COMPANY
    FROM lc_joins_links_snapshot
)

,combine AS (
    SELECT
        b.DATE
        ,b.BRAND
        ,b.LOYALTY_PLAN_NAME
        ,b.LOYALTY_PLAN_COMPANY

        ,COALESCE(jl.LINK_REQUEST_PENDING, 0) AS REQUESTED_LINKS
        ,COALESCE(jl.LINK_FAILED, 0) AS FAILED_LINKS
        ,COALESCE(jl.LINK_SUCCESSFUL, 0) AS SUCCESSFUL_LINKS
        ,COALESCE(jl.LINK_DELETE, 0) AS DELETED_LINKS

        ,COALESCE(jl.JOIN_REQUEST_PENDING, 0) AS REQUESTED_JOINS
        ,COALESCE(jl.JOIN_FAILED, 0) AS FAILED_JOINS
        ,COALESCE(jl.JOIN_SUCCESSFUL, 0) AS SUCCESSFUL_JOINS
        ,COALESCE(jl.JOIN_DELETE, 0) AS DELETED_JOINS

        ,COALESCE(jls.LINK_SUCCESS_STATE, 0) AS LINK_SUCCESS_STATE
        ,COALESCE(jls.LINK_FAILED_STATE, 0) AS LINK_FAILED_STATE
        ,COALESCE(jls.LINK_PENDING_STATE, 0) AS LINK_PENDING_STATE
        ,COALESCE(jls.LINK_REMOVED_STATE, 0) AS LINK_DELETED_STATE

        ,COALESCE(jls.JOIN_SUCCESS_STATE, 0) AS JOIN_SUCCESS_STATE
        ,COALESCE(jls.JOIN_FAILED_STATE, 0) AS JOIN_FAILED_STATE
        ,COALESCE(jls.JOIN_PENDING_STATE, 0) AS JOIN_PENDING_STATE
        ,COALESCE(jls.JOIN_REMOVED_STATE, 0) AS JOIN_DELETED_STATE
    FROM
        base_table b
    LEFT JOIN lc_joins_links jl ON
        b.DATE = jl.DATE
        AND b.BRAND = jl.BRAND
        AND b.LOYALTY_PLAN_NAME = jl.LOYALTY_PLAN_NAME
    LEFT JOIN lc_joins_links_snapshot jls ON
        b.DATE = jls.DATE
        AND b.BRAND = jls.BRAND
        AND b.LOYALTY_PLAN_NAME = jls.LOYALTY_PLAN_NAME
)

SELECT *
FROM combine