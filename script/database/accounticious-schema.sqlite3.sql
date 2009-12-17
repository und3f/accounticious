-- Account
-- Account name, id, possible something else...
CREATE TABLE account (
    account_id INTEGER PRIMARY KEY,
    account_name TEXT NOT NULL
);

-- Balance
-- Counting money on account
CREATE TABLE balance (
    account INTEGER NOT NULL,
    currency CHAR(3) NOT NULL,
    -- Amount of maney in specified currency
    amount REAL,

    FOREIGN KEY (account) REFERENCES account(account_id),
    PRIMARY KEY (account, currency)
);

-- History
-- Record everything happend to account
CREATE TABLE history (
    account INTEGER NOT NULL,
    currency CHAR(3) NOT NULL,
    created DATETIME NOT NULL,
    asset TEXT NOT NULL,
    comment TEXT
    FOREIGN KEY (account) REFERENCES account(account_id)
);

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

