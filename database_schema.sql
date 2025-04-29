CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users (
    username VARCHAR(255) UNIQUE PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password TEXT NOT NULL,
    dark_mode BOOLEAN DEFAULT FALSE,
    email_verified BOOLEAN DEFAULT FALSE
);


CREATE TABLE groups (
    group_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_name VARCHAR(255) NOT NULL,
    group_description varchar(255) NOT NULL,
    -- group_type mapping: 0 = OTS, 1 = Grey Group, 2 = Normal Group, 3 = Private-Split
    group_type INT CHECK (group_type IN (0, 1, 2, 3)) NOT NULL,
    invite_code VARCHAR(10) UNIQUE,
    admin_username VARCHAR(255) REFERENCES users(username)
);

CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.group_type IN (0, 1, 2) THEN
        NEW.invite_code := LEFT(encode(digest(gen_random_uuid()::TEXT, 'sha256'), 'base64'), 8);
    ELSE
        NEW.invite_code := NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_invite_code
BEFORE INSERT ON groups
FOR EACH ROW
EXECUTE FUNCTION generate_invite_code();

CREATE TABLE ots_group_participants (
    group_id UUID REFERENCES groups(group_id) ON DELETE CASCADE,
    user_name VARCHAR(255) NOT NULL,
    confirmed BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (group_id, user_name)
);

CREATE TABLE expenses (
    expense_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES groups(group_id) ON DELETE CASCADE,
    description VARCHAR(255) NOT NULL,
    -- tag mapping: 0 = food, 1 = transport, 2 = entertainment, 3 = shopping, 4 = bills, 5 = other
    tag INT CHECK (tag IN (0, 1, 2, 3, 4, 5)) DEFAULT 5,
    added_by VARCHAR(255) REFERENCES users(username),   -- TODO: should i change added by to last modified by? yes
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10,2) NOT NULL
);

CREATE TABLE bill_split (
    expense_id UUID REFERENCES expenses(expense_id) ON DELETE CASCADE,
    username VARCHAR(255) REFERENCES users(username),
    amount_contributed DECIMAL(10,2) NOT NULL,
    amount_owed DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (expense_id, username)
);

CREATE TABLE group_participants (
    group_id UUID REFERENCES groups(group_id) ON DELETE CASCADE,
    participant VARCHAR(255) REFERENCES users(username),
    PRIMARY KEY (group_id, participant)
);

CREATE TABLE balances (
    group_id UUID REFERENCES groups(group_id) ON DELETE CASCADE,
    sender VARCHAR(255) REFERENCES users(username),
    receiver VARCHAR(255) REFERENCES users(username),
    amount DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (group_id, sender, receiver)
);

CREATE TABLE intermediate_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES groups(group_id) ON DELETE CASCADE,
    sender VARCHAR(255) REFERENCES users(username),
    receiver VARCHAR(255) REFERENCES users(username),
    amount DECIMAL(10,2) NOT NULL,
    confirmed BOOLEAN DEFAULT FALSE   -- TODO: ig this is not required, since it is assumed that the sender is the one who confirmed
);

CREATE TABLE completed_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES groups(group_id) ON DELETE CASCADE,
    sender VARCHAR(255) REFERENCES users(username),
    receiver VARCHAR(255) REFERENCES users(username),
    amount DECIMAL(10,2) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP   
);


-- used to check if there is anyone in the group. If there is no one, delete the group

CREATE OR REPLACE FUNCTION delete_empty_group()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if there are no participants in the group
    IF NOT EXISTS (SELECT 1 FROM group_participants WHERE group_id = OLD.group_id) THEN
        -- Delete the group if no participants exist
        DELETE FROM groups WHERE group_id = OLD.group_id;
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger to call the function after deleting a participant
CREATE TRIGGER check_empty_group
AFTER DELETE ON group_participants
FOR EACH ROW
EXECUTE FUNCTION delete_empty_group();




-- INSERT INTO users (username, name, email, password) VALUES
-- ('user1', 'Alice Smith', 'alice@example.com', crypt('password123', gen_salt('bf'))),
-- ('user2', 'Bob Johnson', 'bob@example.com', crypt('securepass', gen_salt('bf'))),
-- ('user3', 'Charlie Brown', 'charlie@example.com', crypt('mypassword', gen_salt('bf')));

-- INSERT INTO groups (group_name, group_type, admin_username) VALUES
-- ('Trip to Paris', 0, 'user1'),
-- ('Weekend Getaway', 1, 'user2'),
-- ('Office Party', 2, 'user3');

-- INSERT INTO group_participants (group_id, participant) VALUES
-- ((SELECT group_id FROM groups WHERE group_name = 'Trip to Paris'), 'user2'),
-- ((SELECT group_id FROM groups WHERE group_name = 'Trip to Paris'), 'user3');

-- INSERT INTO group_participants (group_id, participant) VALUES
-- ((SELECT group_id FROM groups WHERE group_name = 'Weekend Getaway'), 'user1'),
-- ((SELECT group_id FROM groups WHERE group_name = 'Weekend Getaway'), 'user3'),
-- ((SELECT group_id FROM groups WHERE group_name = 'Office Party'), 'user1'),
-- ((SELECT group_id FROM groups WHERE group_name = 'Office Party'), 'user2');


-- DELETE FROM groups WHERE group_name = 'Office Party';