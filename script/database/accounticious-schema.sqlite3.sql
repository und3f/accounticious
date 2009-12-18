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
    -- Amount of maney in specified currency
    Amount      REAL,

    FOREIGN KEY (account) REFERENCES account(account_id),
    PRIMARY KEY (account, currency)
);

-- History
-- Record everything happend to account
CREATE TABLE history (
    account     INTEGER NOT NULL,
    currency    CHAR(3) NOT NULL,
    created     DATETIME DEFAULT CURRENT_TIMESTAMP,
    asset       TEXT NOT NULL,
    user        INTEGER NOT NULL,
    comment     TEXT,
    amount      REAL,
    FOREIGN KEY (account) REFERENCES account(account_id),
    FOREIGN KEY (user) REFERENCES user(id)
);

-- Auto update balance on updating history
--
CREATE TRIGGER update_balance
AFTER INSERT ON history
BEGIN
    SELECT NEW.account, NEW.currency;
    -- Init row
    INSERT OR IGNORE INTO balance
    VALUES( NEW.account, NEW.currency, 0.0 );

    -- Now calculate our money
    UPDATE balance
    SET
        amount    = amount + NEW.amount
    WHERE
        account   = NEW.account
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

