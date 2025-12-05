-- usage_trend.sql
-- Track medication usage (OUT transactions) by month.

SELECT
    m.med_name,
    m.generic_name,
    DATE_TRUNC('month', t.tx_date) AS usage_month,
    SUM(
        CASE
            WHEN t.tx_type = 'OUT' THEN t.quantity
            -- If negative ADJUST represents loss/wastage, include it in usage:
            WHEN t.tx_type = 'ADJUST' AND t.quantity < 0 THEN -t.quantity
            ELSE 0
        END
    ) AS quantity_used
FROM Transactions t
JOIN InventoryBatches b ON t.batch_id = b.batch_id
JOIN Medications      m ON b.med_id = m.med_id
GROUP BY
    m.med_name,
    m.generic_name,
    DATE_TRUNC('month', t.tx_date)
HAVING
    SUM(
        CASE
            WHEN t.tx_type = 'OUT' THEN t.quantity
            WHEN t.tx_type = 'ADJUST' AND t.quantity < 0 THEN -t.quantity
            ELSE 0
        END
    ) > 0
ORDER BY
    usage_month,
    m.med_name;
