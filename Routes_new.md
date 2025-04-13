### 1. SIGNUP
 **Route**: ```/api/signup```\
**METHOD**: ```POST```\
**Description**: Used for signup. Basic format checking must be done on client side.\
**Request body**:
```json
{
  "username": "string",
  "name": "string",
  "email": "string",
  "password": "string"
}
```
**Response**:
```json
{  
  "status": "bool",         // like: true: Success, false: Failure
  "message": "string"       // like: "User created successfully", "Username already used"
}
```
### 2. LOGIN
**Route**: ```/api/login```\
**METHOD**: ```POST```\
**Description**: Used for login. Basic format checking must be done on client side.\
**Request body**:
```json
{
  "username": "string",
  "password": "string"
}
```
**Response**:
```json
{  
  "status": "bool",         // like: true: Success, false: Failure
  "message": "string"       // like: "User logged in successfully", "Invalid username or password"
  // Set the cookie
	"http.SetCookie(w, &http.Cookie{
		Name:     "auth_token",
		Value:    token,
		Expires:  time.Now().Add(30 * 24 * time.Hour), // optional
		HttpOnly: true,
		Path:     "/",
        UserPreferences: "string" // like: "dark mode", "light mode"
	}"
}
```

![alt text](image.png)


We can use this to store the session values in the cookie (backend).
![alt text](image-1.png)



### 3. LOGOUT
**Route**: ```/api/logout```\
**METHOD**: ```POST```\
**Description**: Used for logout.\
**Request body**:
```json
{
  "username": "string"
  // cookie
    "http.SetCookie(w, &http.Cookie{
        Name:     "auth_token",
        Value:    token,
        Expires:  time.Now().Add(-1 * time.Hour), // optional
        HttpOnly: true,
        Path:     "/",
        UserPreferences: "string" // like: "dark mode", "light mode"
    }"
}
```
**Response**:
```json
{  
  "status": "bool",         // like: true: Success, false: Failure. status can only be true
}
```

### 4. FORGOT PASSWORD
**Route**: ```/api/forgot_password```\
**METHOD**: ```POST```\
**Description**: Used for forgot password. Basic format checking must be done on client side.\
**Request body**:
```json
{
  "username": "string",
  "email": "string"
}
```
**Response**:
```json
{  
  "status": "bool",         // like: true: Success, false: Failure
  "message": "string"       // like: "Password reset link sent to email", "Invalid username or email"
}
```

### 5. RESET PASSWORD
**Route**: ```/api/reset_password```\
**METHOD**: ```POST```\
**Description**: Used for reset password. Basic format checking must be done on client side.\
**Request body**:
```json
{
  "username": "string",
  "old_password": "string",
  "new_password": "string",
  "cookie"
}
```
**Response**:
```json
{  
  "status": "bool",         // like: true: Success, false: Failure
  "message": "string"       // like: "Password reset successfully", "Incorrect old password" 
}
```

### 6. CREATE GROUP
**Route**: ```/api/create_group```\
**METHOD**: ```PUT```\
**Description**: Used for creating a group. Basic format checking must be done on client side.\
**Request body**:
```json
{  
  "username": "string",
  "group_name": "string",
  "group_description": "string",
  "group_type": "string", // like: "OTS", "Grey Group", "Normal Group", "Private-Split",
  "cookie"
}
```
**Response**:
```json
{  
  "status": "bool",         // like: true: Success, false: Failure
  "message": "string"       // like: "Group created successfully"
}
```

### 7. CREATE PRIVATE SPLIT
**Route**: ```/api/create_private_split```\
**METHOD**: ```PUT```\
**Description**: Used for creating a private split. Basic format checking must be done on client side.\
**Request body**:
```json
{  
  "username": "string",
  "username_2": "string",
  "group_description": "string",
  "cookie"
}
```
**Response**:
```json
{  
  "status": "bool",         // like: true: Success, false: Failure
  "message": "string"       // like: "Private-Split created successfully", "User not found"
}
```

### 8. JOIN GROUP
**Route**: ```/api/join_group```\
**METHOD**: ```PUT```\
**Description**: Used for joining a group. Basic format checking must be done on client side.\
**Request body**:
```json
{  
  "username": "string",
  "invite_code": "string",
  "cookie"
}
**Response**:
```json
{  
  "status": "bool",         // like: true: Success, false: Failure
  "message": "string"       // like: "Group joined successfully", "Invalid invite code"
}
```

### 9. GET TRANSACTION HISTORY
**Route**: ```/api/get_transaction_history```\
**METHOD**: ```GET```\
**Description**: Used for getting transaction history. Basic format checking must be done on client side.\
**Request body**:
```json
{  
  "username": "string",
  "cookie"
}
```
**Response**:
```json
{  
  "status": "bool",         // like: true: Success, false: Failure
  "transactions": [
    "sender"  : "string",
    "receiver": "string",
    "amount"  : "float"
  ]
}
```

### 10. GET GROUPS
**Route**: ```/api/get_groups```\
**METHOD**: ```GET```\








1. For sending emails, use ```SendGrid```.
2. the flutter front end will know that the app has been backgrounded for more than 10 mins. So, it will send a request kind of thing to the server. and the server will close the connection. and then if the user opens the app after keeping it in background for 11 mins, then will flutter again send a request to open the web socket connection

