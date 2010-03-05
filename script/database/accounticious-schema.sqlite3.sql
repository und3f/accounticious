PRAGMA ENCODING="UTF-8";

-- Account
-- Account name, id, possible something else...
CREATE TABLE account (
    account_id INTEGER PRIMARY KEY,
    account_name TEXT NOT NULL
);

-- Balance
-- Counting money on account
CREATE TABLE balance (
    account     INTEGER NOT NULL,
    currency    CHAR(3) NOT NULL,
    -- Amount of money in specified currency
    amount      REAL,

    FOREIGN KEY (account) REFERENCES account(account_id),
    PRIMARY KEY (account, currency)
);

-- History
-- Record everything happend to account
CREATE TABLE history (
    account_src INTEGER NOT NULL,
    account_dst INTEGER NOT NULL,
    currency    CHAR(3) NOT NULL,
    created     DATETIME DEFAULT CURRENT_TIMESTAMP,
    user        INTEGER NOT NULL,
    comment     TEXT,
    amount      REAL,
    FOREIGN KEY (account_src) REFERENCES account(account_id),
    FOREIGN KEY (account_dst) REFERENCES account(account_id),
    FOREIGN KEY (user) REFERENCES user(id)
);

-- Auto update balance on updating history
--
CREATE TRIGGER update_balance
AFTER INSERT ON history
BEGIN
    SELECT NEW.account_src, NEW.account_dst, NEW.currency;
    -- Init rows for source and destination
    INSERT OR IGNORE INTO balance
    VALUES( NEW.account_src, NEW.currency, 0.0 );

    INSERT OR IGNORE INTO balance
    VALUES( NEW.account_dst, NEW.currency, 0.0 );

    -- substract money from source
    UPDATE balance
    SET
        amount    = amount - NEW.amount
    WHERE
        account   = NEW.account_src
    AND
        currency  = NEW.currency;

    -- add money to destination
    UPDATE balance
    SET
        amount    = amount + NEW.amount
    WHERE
        account   = NEW.account_dst
    AND
        currency  = NEW.currency;
END;

-- User
-- Holds users data
--
CREATE TABLE user (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    password TEXT NOT NULL,
    -- Every user have it`s own account
    account INTEGER NOT NULL,
    FOREIGN KEY (account) REFERENCES account(account_id)
);

-- Create root user with password "root"
INSERT INTO account VALUES (1, "root");
INSERT INTO user VALUES( 1, "root", "3Hbp8MAAbo+RngxRXGbbujmC94U", 1 );
