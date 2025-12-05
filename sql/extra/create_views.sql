CREATE OR REPLACE VIEW vw_current_stock AS
WITH batch_stock AS (
    SELECT 
        b.batch_id,
        b.medication_id,
        b.location_id,
        b.lot_number,
        b.expiry_date,
        b.received_date,
        SUM(
            CASE 
                WHEN t.transaction_type = 'IN' THEN t.quantity
                WHEN t.transaction_type = 'OUT' THEN -t.quantity
                WHEN t.transaction_type = 'ADJUST' THEN t.quantity
                ELSE 0
            END
        ) AS current_quantity
    FROM InventoryBatches b
    LEFT JOIN Transactions t ON b.batch_id = t.batch_id
    GROUP BY 
        b.batch_id, b.medication_id, b.location_id, 
        b.lot_number, b.expiry_date, b.received_date
)
SELECT 
    m.medication_name,
    m.generic_name,
    m.form,
    m.strength,
    l.location_name,
    b.lot_number,
    b.expiry_date,
    b.received_date,
    b.current_quantity
FROM batch_stock b
JOIN Medications m ON b.medication_id = m.medication_id
JOIN Locations l ON b.location_id = l.location_id
ORDER BY m.medication_name, l.location_name, b.expiry_date;

CREATE OR REPLACE VIEW vw_low_stock AS
WITH batch_stock AS (
    SELECT 
        b.batch_id,
        b.medication_id,
        SUM(
            CASE 
                WHEN t.transaction_type = 'IN' THEN t.quantity
                WHEN t.transaction_type = 'OUT' THEN -t.quantity
                WHEN t.transaction_type = 'ADJUST' THEN t.quantity
                ELSE 0
            END
        ) AS current_quantity
    FROM InventoryBatches b
    LEFT JOIN Transactions t ON b.batch_id = t.batch_id
    GROUP BY b.batch_id, b.medication_id
),
med_total AS (
    SELECT 
        m.medication_id,
        m.medication_name,
        SUM(b.current_quantity) AS total_current_quantity
    FROM batch_stock b
    JOIN Medications m ON b.medication_id = m.medication_id
    GROUP BY m.medication_id, m.medication_name
)
SELECT *
FROM med_total
WHERE total_current_quantity < 50   -- threshold (adjustable)
ORDER BY total_current_quantity ASC;

CREATE OR REPLACE VIEW vw_expiry_risk AS
WITH batch_stock AS (
    SELECT 
        b.batch_id,
        b.medication_id,
        b.location_id,
        b.lot_number,
        b.expiry_date,
        SUM(
            CASE 
                WHEN t.transaction_type = 'IN' THEN t.quantity
                WHEN t.transaction_type = 'OUT' THEN -t.quantity
                WHEN t.transaction_type = 'ADJUST' THEN t.quantity
                ELSE 0
            END
        ) AS current_quantity
    FROM InventoryBatches b
    LEFT JOIN Transactions t ON b.batch_id = t.batch_id
    GROUP BY 
        b.batch_id, b.medication_id, b.location_id, 
        b.lot_number, b.expiry_date
)
SELECT
    m.medication_name,
    l.location_name,
    b.lot_number,
    b.expiry_date,
    b.current_quantity,
    CASE 
        WHEN b.expiry_date < CURRENT_DATE THEN 'Expired'
        WHEN b.expiry_date < CURRENT_DATE + INTERVAL '30 days' THEN 'High'
        WHEN b.expiry_date < CURRENT_DATE + INTERVAL '60 days' THEN 'Medium'
        WHEN b.expiry_date < CURRENT_DATE + INTERVAL '90 days' THEN 'Low'
        ELSE 'OK'
    END AS expiry_risk_level
FROM batch_stock b
JOIN Medications m ON b.medication_id = m.medication_id
JOIN Locations l ON b.location_id = l.location_id
WHERE b.current_quantity > 0
  AND b.expiry_date < CURRENT_DATE + INTERVAL '90 days'
ORDER BY expiry_risk_level, b.expiry_date;

CREATE OR REPLACE VIEW vw_usage_trend AS
WITH usage_raw AS (
    SELECT 
        m.medication_name,
        m.generic_name,
        DATE_TRUNC('month', t.transaction_date) AS usage_month,
        CASE 
            WHEN t.transaction_type = 'OUT' THEN t.quantity
            WHEN t.transaction_type = 'ADJUST' AND t.quantity < 0 THEN ABS(t.quantity)
            ELSE 0
        END AS quantity_used
    FROM Transactions t
    JOIN InventoryBatches b ON t.batch_id = b.batch_id
    JOIN Medications m ON b.medication_id = m.medication_id
)
SELECT 
    medication_name,
    generic_name,
    usage_month,
    SUM(quantity_used) AS total_quantity_used
FROM usage_raw
WHERE quantity_used > 0
GROUP BY medication_name, generic_name, usage_month
ORDER BY usage_month, medication_name;

