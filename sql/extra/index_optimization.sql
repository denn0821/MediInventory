CREATE INDEX idx_batch_medication ON InventoryBatches(medication_id);
CREATE INDEX idx_batch_expiry ON InventoryBatches(expiry_date);
CREATE INDEX idx_transactions_batch ON Transactions(batch_id);
CREATE INDEX idx_transactions_type ON Transactions(transaction_type);
