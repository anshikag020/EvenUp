## Users table
1. user id
2. username
3. name
4. email
5. password

## Groups table
1. group id
2. group name
3. group type (OTS, Grey Group, normal group, private-split)
4. Invite link (Unique invite code)
5. Invite link expiry time
6. Admin\

## OTS groups participants
1. group id
2. user name
3. confirmed (0/1)

## Expenses table
1. expense id
2. group id
3. description
4. tag
5. added by
6. timestamp
7. amount

## Bill Split Table
1. expense id
2. user id
3. amount contributed
4. amount owed

## group participants table
1. group id
2. participant id

## Transactions table   
if a transaction is settled from any side then we add the transaction here
1. transaction id
2. sender id
3. receiver id
4. amount
5. group id     (dont set as cascade)
6. sender_status : 0/1 (0: pending, 1: settled)
7. receiver_status : 0/1 (0: pending, 1: settled)

## Balances table
1. group id
2. username 1
3. username 2
4. balance
(ig we need this)


## Settled transactions table
1. transaction id
2. group id     (dont set as cascade)
3. sender id
4. receiver id
5. amount


else: *******
## Balances table
1. group id
2. sender
3. receiver
4. amount

## Intermediate transactions table
1. transaction id
2. group id
3. sender
4. receiver
5. amount
6. confirmed from whose side sender or receiver (0/1)

## Completed transactions
1. transaction id
2. group id
3. sender
4. receiver
5. amount


---
### Profile page
1. For displaying the profile of a person: we access the user table.

### Groups page
2. For displaying the groups of a person: we access the group participants table and then the groups table. we return group id and group name.
3. For displaying the private splits of a person: we access the group participants table -> to get the group id -> then the groups table to find which are the private splits -> then the group participant table to get the other participant username. We return other participant username and group id.
4. If a group is deleted by the admin: we delete the group from the group table and also delete the group from the group participants table. We will have to remove all other related data also.\
not this: Another way to handle this can be to just have another column that tells if the group is active or not.
(cascade)
******

### Expenses page

5. to display all the expenses of a group, we access the expenses table. (return expense id, description, tag, timestamp, amount).\
In case of Grey group, first check if the current user is involved in the expense or not. If yes, then return the expense.

### Add expense
6. We add the expense in the expenses table. We also add the bill split in the bill split table. We also do the socket thing and notify only the people involved in the expense. Then update the balances accordingly, and optimise the balances thing.


### Edit expense
7. We edit the expense in the expenses table. We also edit the bill split in the bill split table. We also do the socket thing and notify only the people who were involved or are now involved in the expense. Then update the balances accordingly, and optimise the balances thing.

### Delete expense
8. We delete the expense from the expenses table. We also delete the bill split from the bill split table. We also do the socket thing and notify all the people involved in the expense. Then we add opposite edges in the balances table and optimise the balances thing. (We also make sure no outstanding balances or pending transactions are there)

### Join group
9. An invite link will be generated. The link will have an expiry. The user can join the group using the link. We add the user to the group participants table.

### Exit group
10. Remove the row from group participants table.

### Display logs (transaction history)
11. Show  completely settled transactions. refer completed transactions table.\


Logs will only display the expenses that are settled up by atleast one party. Display using the transactions table.



### Display Friends section
Display using the balances table ig.
In case of OTS group, make sure all the expenses are added by all the people. Then only display here.

## Display Intermediate transactions
Display using the intermediate transactions table. If the user accessing has settled then disable the settle up button. Give, settle up and reject options here.\
If user rejects, then add the transaction to the balances table. and remove from current table.\
If user settles, then add the transaction to the settled transactions table. and remove from current table.


### Settle up
If the user settles up, then the transaction is removed from the balances table and added to the next table in the stage.

### Displaying the balances

