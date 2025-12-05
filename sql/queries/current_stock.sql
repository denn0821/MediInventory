-- current_stock_by_batch.sql

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
            WHEN t.tx_type = 'ADJUST' THEN t.quantity  -- assume signed
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
ORDER BY
    m.med_name,
    b.expiry_date;
