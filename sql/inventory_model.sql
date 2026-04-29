WITH monthly_assembly_shipments AS (
-- groups assemblies sold by month
SELECT
    assembly_internal_id AS shipment_assembly_internal_id,
    item_name AS assembly,
    SUM(quantity_shipped) AS quantity
FROM item_fulfillments
GROUP BY assembly, assembly_internal_id ) ,

assembly_to_bom AS (
-- matches the assembly's internal ID to a BOM record and threfore its components
-- THIS IMPLICITLY EXCLUDES ANYTHING WITHOUT A BOM RECORD ATTACHED TO IT
SELECT
    *
FROM monthly_assembly_shipments mas
INNER JOIN assembly_bom_match abm ON abm.assembly_internal_id = shipment_assembly_internal_id
INNER JOIN bom_data bd ON bd.bom_internal_id = abm.bom_internal_id) ,

fulfillment_aggregation AS (
SELECT
    component_name,
    SUM(bom_quantity * quantity) AS quantity_shipped
FROM assembly_to_bom
GROUP BY component_name
UNION ALL
-- finds anything without a BOM record attached to it and displays shipments by month
SELECT
    af.item_name AS component_name,
    SUM(af.quantity_shipped) AS quantity_shipped
FROM item_fulfillments af
LEFT JOIN assembly_bom_match abm ON abm.assembly_internal_id = af.assembly_internal_id
LEFT JOIN component_lead_times clt ON clt.part_number = af.item_name
WHERE abm.assembly_internal_id IS NULL
GROUP BY component_name) ,

date_range AS(
SELECT
    MAX(shipment_date) - MIN(shipment_date) AS shipping_days
FROM item_fulfillments af) ,

formula_parts AS (
SELECT
    fa.component_name,
    ROUND((SUM(fa.quantity_shipped) / dr.shipping_days) , 2) AS avg_daily_demand,
	clt.avg_lead_time,
	clt.variability,
	clt.is_critical,
	CASE
		WHEN is_critical = 'true' THEN 2.05
		ELSE 1.28 END AS z_score
FROM fulfillment_aggregation fa
CROSS JOIN date_range dr
INNER JOIN component_lead_times clt ON fa.component_name = clt.part_number
GROUP BY component_name, shipping_days, clt.avg_lead_time, clt.variability, clt.is_critical
ORDER BY (SUM(quantity_shipped) / shipping_days) DESC) ,

safety_stock_calculation AS (
SELECT
	component_name,
	avg_daily_demand,
	avg_lead_time,
	variability,
	is_critical,
	z_score,
	ROUND((z_score * avg_daily_demand * (variability/2)) , 0) AS safety_stock
FROM formula_parts )

SELECT
	ssc.component_name,
	cs.current_stock,
	ssc.avg_daily_demand,
	ROUND(ssc.safety_stock, -1) AS safety_stock,
	ROUND( (ssc.avg_daily_demand * ssc.avg_lead_time) + ssc.safety_stock , -1) AS reorder_point
FROM safety_stock_calculation ssc
INNER JOIN current_stock cs ON cs.part_number = ssc.component_name
