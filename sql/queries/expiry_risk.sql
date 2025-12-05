-- expiry_risk.sql
-- List batches that are expired or expiring soon, with risk level.

WITH batch_stock AS (
    SELECT
        b.batch_id,
        m.med_name,
        m.generic_name,
        m.form,
        m.strength,
        l.location_name,
        b.lot_number,
        b.expiry_date,
        b.received_date,
        SUM(
            CASE
                WHEN t.tx_type = 'IN'     THEN t.quantity
                WHEN t.tx_type = 'OUT'    THEN -t.quantity
                WHEN t.tx_type = 'ADJUST' THEN t.quantity  -- signed adjustment
                ELSE 0
            END
        ) AS current_quantity
    FROM InventoryBatches b
    JOIN Medications m  ON b.med_id = m.med_id
    JOIN Locations  l   ON b.location_id = l.location_id
    JOIN Transactions t ON b.batch_id = t.batch_id
    GROUP BY
        b.batch_id,
        m.med_name,
        m.generic_name,
        m.form,
        m.strength,
        l.location_name,
        b.lot_number,
        b.expiry_date,
        b.received_date
)

SELECT
    batch_id,
    med_name,
    generic_name,
    form,
    strength,
    location_name,
    lot_number,
    expiry_date,
    current_quantity,
    CASE
        WHEN expiry_date < CURRENT_DATE THEN 'Expired'
        WHEN expiry_date < CURRENT_DATE + INTERVAL '30 days' THEN 'High'
        WHEN expiry_date < CURRENT_DATE + INTERVAL '60 days' THEN 'Medium'
        WHEN expiry_date < CURRENT_DATE + INTERVAL '90 days' THEN 'Low'
        ELSE 'OK'
    END AS expiry_risk_level
FROM batch_stock
WHERE
    current_quantity > 0
    AND expiry_date < CURRENT_DATE + INTERVAL '90 days'
ORDER BY
    expiry_date,
    med_name;
