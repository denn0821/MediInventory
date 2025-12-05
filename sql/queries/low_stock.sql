-- low_stock.sql
-- Summarize current stock per medication and flag low-stock items.

WITH batch_stock AS (
    SELECT
        b.batch_id,
        b.med_id,
        m.med_name,
        m.generic_name,
        m.form,
        m.strength,
        SUM(
            CASE
                WHEN t.tx_type = 'IN'     THEN t.quantity
                WHEN t.tx_type = 'OUT'    THEN -t.quantity
                WHEN t.tx_type = 'ADJUST' THEN t.quantity
                ELSE 0
            END
        ) AS current_quantity
    FROM InventoryBatches b
    JOIN Medications m  ON b.med_id = m.med_id
    JOIN Transactions t ON b.batch_id = t.batch_id
    GROUP BY
        b.batch_id,
        b.med_id,
        m.med_name,
        m.generic_name,
        m.form,
        m.strength
),

med_stock AS (
    SELECT
        med_id,
        med_name,
        generic_name,
        form,
        strength,
        SUM(current_quantity) AS total_current_quantity
    FROM batch_stock
    GROUP BY
        med_id,
        med_name,
        generic_name,
        form,
        strength
)

SELECT
    med_id,
    med_name,
    generic_name,
    form,
    strength,
    total_current_quantity
FROM med_stock
WHERE total_current_quantity < 50        -- 🔧 change this threshold if needed
ORDER BY
    total_current_quantity ASC,
    med_name;
