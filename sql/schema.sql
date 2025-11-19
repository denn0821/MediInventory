-- 1. Medications
CREATE TABLE Medications (
    med_id          SERIAL PRIMARY KEY,
    med_name        VARCHAR(100) NOT NULL,
    generic_name    VARCHAR(100),
    form            VARCHAR(50) NOT NULL,        -- tablet, capsule, syrup, etc.
    strength        VARCHAR(50),                 -- e.g., 500mg, 250mg/5mL
    unit            VARCHAR(20) NOT NULL,        -- tablet, vial, bottle, mL
    is_controlled   BOOLEAN DEFAULT FALSE,
    atc_code        VARCHAR(20),                 -- optional medical classification
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Storage Locations
CREATE TABLE Locations (
    location_id     SERIAL PRIMARY KEY,
    location_name   VARCHAR(100) NOT NULL,
    description     VARCHAR(255),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Inventory Batches
CREATE TABLE InventoryBatches (
    batch_id        SERIAL PRIMARY KEY,
    med_id          INT NOT NULL,
    location_id     INT NOT NULL,
    lot_number      VARCHAR(50),
    expiry_date     DATE,
    quantity_initial INT NOT NULL CHECK (quantity_initial >= 0),
    received_date   DATE NOT NULL DEFAULT CURRENT_DATE,

    CONSTRAINT fk_batch_med
        FOREIGN KEY (med_id)
        REFERENCES Medications(med_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_batch_loc
        FOREIGN KEY (location_id)
        REFERENCES Locations(location_id)
        ON DELETE SET NULL
);

-- 4. Transactions (Stock Movements)
CREATE TABLE Transactions (
    tx_id           SERIAL PRIMARY KEY,
    batch_id        INT NOT NULL,
    tx_date         DATE NOT NULL,
    tx_type         VARCHAR(20) NOT NULL CHECK (tx_type IN ('IN','OUT','ADJUST')),
    quantity        INT NOT NULL CHECK (quantity > 0),
    reason          VARCHAR(100),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_tx_batch
        FOREIGN KEY (batch_id)
        REFERENCES InventoryBatches(batch_id)
        ON DELETE CASCADE
);

-- 5. Suppliers
CREATE TABLE Suppliers (
    supplier_id     SERIAL PRIMARY KEY,
    supplier_name   VARCHAR(150) NOT NULL,
    contact_phone   VARCHAR(20),
    contact_email   VARCHAR(100),
    address         VARCHAR(255),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Link batches to suppliers
ALTER TABLE InventoryBatches
ADD COLUMN supplier_id INT,
ADD CONSTRAINT fk_batch_supplier
    FOREIGN KEY (supplier_id)
    REFERENCES Suppliers(supplier_id);
