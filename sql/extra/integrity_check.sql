-- Batches with negative stock
SELECT * FROM (
    SELECT b.batch_id, SUM(quantity) AS qty
    FROM Transactions t
    JOIN InventoryBatches b ON t.batch_id = b.batch_id
    GROUP BY b.batch_id
) x
WHERE qty < 0;

-- Batches with expiry before received date
SELECT * FROM InventoryBatches
WHERE expiry_date < received_date;
