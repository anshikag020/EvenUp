# API Routes Documentation

### **User Routes**

#### **User Registration**
- **Method:** `POST`
- **Route:** `/users/register`
- **Parameters (JSON Body):**  
  - `username` (string) - Unique username
  - `name` (string)
  - `email` (string) - User email address
  - `password` (string) - Secure password
- **Description:** Registers a new user and stores credentials securely.
- **Response:**
  - Success: JSON with user ID and confirmation message.
  - Failure: Error message indicating registration failure.

#### **User Login**
- **Method:** `POST`
- **Route:** `/users/login`
- **Parameters (JSON Body):**
  - `username` (string)
  - `password` (string)
- **Description:** Authenticates the user credentials and returns a session token (JWT or session-based).
- **Response:**
  - Success: JSON with session token and user details.
  - Failure: Error message indicating incorrect credentials.

#### **Fetch User Profile**
- **Method:** `GET`
- **Route:** `/users/profile/:username`
- **Description:** Retrieves the profile details of a user.
- **Response:**
  - Success: JSON with user profile details.
  - Failure: Error message if user not found.

---

### **Group Routes**

#### **Create Group**
- **Method:** `POST`
- **Route:** `/groups`
- **Parameters (JSON Body):**
  - `group_name` (string)
  - `group_type` (string)
  - `admin username` (string)
- **Description:** Creates a new group.
- **Response:**
  - Success: JSON with group details.
  - Failure: Error message if creation fails.

#### **Fetch User Groups and private splits**
- **Method:** `GET`
- **Route:** `/groups/:username`
- **Description:** Retrieves all groups for a user.
- **Response:**
  - Success: JSON with a list of groups.
  - Failure: Error message if no groups found.

#### **Fetch Group Details**
- **Method:** `GET`
- **Route:** `/groups/details/:groupId`
- **Description:** Fetches details of a specific group.
- **Response:**
  - Success: JSON with group information.
  - Failure: Error message if group not found.

#### **Delete Group**
- **Method:** `DELETE`
- **Route:** `/groups/:groupId`
- **Description:** Deletes a group (admin only).
- **Response:**
  - Success: Confirmation message.
  - Failure: Error message if deletion fails.

#### **Join Group via Invite Code**
- **Method:** `POST`
- **Route:** `/groups/join/:inviteCode`
- **Description:** Allows a user to join a group using an invite code.
- **Response:**
  - Success: JSON confirming user joined.
  - Failure: Error message if invite is invalid or expired.

#### **Leave Group**
- **Method:** `DELETE`
- **Route:** `/groups/leave/:groupId/:userId`
- **Description:** Removes a user from a group.
- **Response:**
  - Success: Confirmation message.
  - Failure: Error message if removal fails.

---

### **Expense Routes**

#### **Add Expense**
- **Method:** `POST`
- **Route:** `/expenses`
- **Parameters (JSON Body):**
  - `group_id` (int)
  - `description` (string)
  - `amount` (float)
  - `added_by` (int)
  - `amount contributed by each person` (list or something)
  - `amount owed by each person` (list or something)
- **Description:** Adds a new expense.
- **Response:**
  - Success: JSON with expense details.
  - Failure: Error message if creation fails.

#### **Get Group Expenses**
- **Method:** `GET`
- **Route:** `/expenses/:groupId`
- **Description:** Retrieves all expenses for a group.
- **Response:**
  - Success: JSON with expense list.
  - Failure: Error message if no expenses found.

#### **Edit Expense**
- **Method:** `PUT`
- **Route:** `/expenses/:expenseId`
- **Parameters:**
  - `group_id` (int)
  - `description` (string)
  - `amount` (float)
  - `amount contributed by each person` (list or something)
  - `amount owed by each person` (list or something)
- **Description:** Edits an existing expense.
- **Response:**
  - Success: Confirmation message.
  - Failure: Error message if update fails.

#### **Delete Expense**
- **Method:** `DELETE`
- **Route:** `/expenses/:expenseId`
- **Description:** Deletes an expense.
- **Response:**
  - Success: Confirmation message.
  - Failure: Error message if deletion fails.

---

### **Bill Split Routes**

#### **Get Bill Split Details**
- **Method:** `GET`
- **Route:** `/billsplit/:expenseId`
- **Description:** Retrieves the bill split details for an expense.
- **Response:**
  - Success: JSON with bill split information.
  - Failure: Error message if not found.
<!-- 
#### **Add Bill Split**
- **Method:** `POST`
- **Route:** `/billsplit`
- **Description:** Adds bill split details.
- **Response:**
  - Success: Confirmation message.
  - Failure: Error message if creation fails.

#### **Update Bill Split**
- **Method:** `PUT`
- **Route:** `/billsplit/:expenseId`
- **Description:** Updates bill split details.
- **Response:**
  - Success: Confirmation message.
  - Failure: Error message if update fails. -->

---

### **Transaction Routes**

#### **Get User Transactions**
- **Method:** `GET`
- **Route:** `/transactions/:userId`
- **Description:** Retrieves transaction history of a user.
- **Response:**
  - Success: JSON with transaction list.
  - Failure: Error message if no transactions found.

#### **Settle Transaction**
- **Method:** `POST`
- **Route:** `/transactions/settle`
- **Description:** Settles a transaction.
- **Response:**
  - Success: Confirmation message.
  - Failure: Error message if settlement fails.

---

### **Balance Routes**

#### **Get User Balances**
- **Method:** `GET`
- **Route:** `/balances/:userId`
- **Description:** Retrieves the balance details of a user.
- **Response:**
  - Success: JSON with balance details.
  - Failure: Error message if not found.

#### **Settle Balances**
- **Method:** `POST`
- **Route:** `/balances/settle`
- **Description:** Settles balances between users.
- **Response:**
  - Success: Confirmation message.
  - Failure: Error message if settlement fails.

---

### **Invite Link Routes**

#### **Generate Invite Link**
- **Method:** `POST`
- **Route:** `/groups/invite/:groupId`
- **Description:** Generates an invite link for a group.
- **Response:**
  - Success: JSON with invite link.
  - Failure: Error message if generation fails.

#### **Validate Invite Link**
- **Method:** `GET`
- **Route:** `/groups/invite/:inviteCode`
- **Description:** Validates an invite link.
- **Response:**
  - Success: JSON confirming valid invite.
  - Failure: Error message if invalid or expired.


### **Send Reminder Routes**


