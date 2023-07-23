--- Create Database
CREATE DATABASE LibraryManagementSystem;

USE LibraryManagementSystem;

GO

CREATE TABLE Member (
	MemberId int IDENTITY(1,1) PRIMARY KEY,
	Username nvarchar(50) NOT NULL,
	Password nvarchar(50) NOT NULL,
	FirstName nvarchar (100) NOT NULL,
	MiddleName nvarchar (100) NOT NULL,
	LastName nvarchar (100) NOT NULL,
	Address1 nvarchar(50) NOT NULL, 
	Address2 nvarchar(50) NOT NULL,
	Dateofbirth date NOT NULL,
	EmailAddress nvarchar(50) NULL,
	ContactNumber nvarchar(50) NOT NULL,
	MembershipEndDate date NOT NULL
);

CREATE TABLE Item (
	ItemId int PRIMARY KEY,
	ItemTitle nvarchar(50) NOT NULL,
	ItemType nvarchar(50) NOT NULL,
	Author nvarchar(50) NOT NULL,
	YearOfPublication date NOT NULL,
	Status nvarchar(50) NOT NULL,
	ISBN nvarchar(50) NOT NULL,
	ItemAddedDate date NOT NULL
);

CREATE TABLE Loan (
	LoanId int PRIMARY KEY,
	MemberId int NOT NULL,
	ItemId int NOT NULL,
	ItemBorrowedDate date NOT NULL,
	ItemDueDate date NOT NULL,
	ItemReturnedDate date NULL,
	OverdueRate decimal(10, 2) NOT NULL DEFAULT 0.00,
	FOREIGN KEY (MemberId) REFERENCES Member(MemberId),
	FOREIGN KEY (ItemId) REFERENCES Item(ItemId)
);

CREATE TABLE Overdue (
   OverdueId int PRIMARY KEY,
   MemberId int NOT NULL,
   ItemId int NOT NULL,
   OverdueDateTime datetime NOT NULL,
   OverdueTotalAmount decimal(10, 2) NOT NULL,
   FOREIGN KEY (MemberId) REFERENCES Member(MemberId),
   FOREIGN KEY (ItemId) REFERENCES Item(ItemId)
);

CREATE TABLE Repayment (
	RepaymentId int PRIMARY KEY,
	OverdueId int NOT NULL,
	RepaymentDateTime datetime NOT NULL,
	RepaymentAmount decimal(10, 2) NOT NULL,
	PaymentMethod nvarchar(50) NOT NULL,
	FOREIGN KEY (OverdueId) REFERENCES Overdue(OverdueId)
);

--- PART 2A
---Stored procedures for matching character strings by title.
go
CREATE PROCEDURE SearchCatalogueByTitle
    @searchString nvarchar(50)
AS
BEGIN
    SELECT *
    FROM Item
    WHERE ItemTitle LIKE '%' + @searchString + '%'
    ORDER BY YearOfPublication DESC
END

--- Execute this stored procedure by calling
EXEC SearchCatalogueByTitle 'last_dance'

---PART 2B
---Stored procedure to return a full list of all items currently on loan which have a due date of less than five days from the current date  
CREATE PROCEDURE GetItemsDueSoon
AS
BEGIN
    SELECT *
    FROM Loan
    JOIN Item ON Loan.ItemId = Item.ItemId
    JOIN Member ON Loan.MemberId = Member.MemberId
    WHERE ItemReturnedDate IS NULL
        AND DATEDIFF(day, GETDATE(), ItemReturnedDate) < 5
END

---You can execute this stored procedure by executing:
EXEC GetItemsDueSoon


--- PART 2C
--- Stored procedures or user-defined functions to Insert a new member into the database
GO
CREATE PROCEDURE InsertNewMember
    @Username nvarchar(50),
    @Password nvarchar(50),
    @FirstName nvarchar(100),
    @MiddleName nvarchar(100),
    @LastName nvarchar(100),
    @Address1 nvarchar(50),
    @Address2 nvarchar(50),
    @DateOfBirth date,
    @EmailAddress nvarchar(50),
    @ContactNumber nvarchar(50),
    @MembershipEndDate date
AS
BEGIN
    INSERT INTO Member (Username, Password, FirstName, MiddleName, LastName, Address1, Address2, DateOfBirth, EmailAddress, ContactNumber, MembershipEndDate)
    VALUES (@Username, @Password, @FirstName, @MiddleName, @LastName, @Address1, @Address2, @DateOfBirth, @EmailAddress, @ContactNumber, @MembershipEndDate);
END;

GO
--- Execute this stored procedure of the above code by calling
EXEC InsertNewMember 'jdoe', 'mypassword', 'John', 'F', 'Donald', '145 LLoyd St', '', '1992-03-01', 'johndonald@email.com', '133-428-6830', '2024-06-20';

---PART 2D
---Stored procedures to update the details for an existing member
CREATE PROCEDURE UpdateMemberDetails
    @memberId int,
	@Username nvarchar(50),
    @Password nvarchar(50),
    @firstName nvarchar(100),
    @middleName nvarchar(100),
    @lastName nvarchar(100),
    @address1 nvarchar(50),
    @address2 nvarchar(50),
    @dateOfBirth date,
    @emailAddress nvarchar(50),
    @contactNumber nvarchar(50),
    @membershipEndDate date
AS
BEGIN
    UPDATE Member
	SET Username =@Username,
        Password = @Password,
        FirstName = @firstName,
        MiddleName = @middleName,
        LastName = @lastName,
        Address1 = @address1,
        Address2 = @address2,
        DateOfBirth = @dateOfBirth,
        EmailAddress = @emailAddress,
        ContactNumber = @contactNumber,
        MembershipEndDate = @membershipEndDate
    WHERE MemberId = @memberId
END


--- Execute this stored procedure by calling
EXEC UpdateMemberDetails 1234, 'new_username', 'new_password', 'Jude', 'Isioma', 'Oseme', '245 lloyd St', 'Apt 10', '1990-05-05', 'judeoseme@email.com', '+234-8356', '2024-06-30'


--- QUESTION 3
---A view showing all previous and currentloans including details of the item borrowed, borrowed date, due date and any associated fines for each loan.
CREATE VIEW LoanHistory AS
SELECT TOP 100 PERCENT
    Member.FirstName + ' ' + Member.LastName AS MemberName,
    Item.ItemTitle,
    Item.Author,
    Loan.ItemBorrowedDate,
    Loan.ItemReturnedDate,
    Loan.OverdueRate,
    CASE
        WHEN Loan.ItemReturnedDate IS NULL AND Loan.ItemReturnedDate < GETDATE() THEN DATEDIFF(day, Loan.ItemDueDate, GETDATE()) * Loan.OverdueRate
        ELSE 0
    END AS Fine
FROM Loan
INNER JOIN Member ON Loan.MemberId = Member.MemberId
INNER JOIN Item ON Loan.ItemId = Item.ItemId
ORDER BY MemberName, Loan.ItemBorrowedDate DESC;

---You can query this updated view using the same query as before:
SELECT * FROM LoanHistory

---QUESTION 4
--- Create a trigger so that the current status of an item automatically updates to Available when the book is returned.
CREATE TRIGGER trLoan_Returned
ON Loan
AFTER UPDATE
AS
BEGIN
	IF UPDATE(ItemReturnedDate)
	BEGIN
		UPDATE Item
		SET Status = 'Available'
		FROM Item
		INNER JOIN inserted ON Item.ItemId = inserted.ItemId
		WHERE inserted.ItemReturnedDate IS NULL
	END
END

---QUESTION 5
--- query that will retrieve the total number of loans made on a specified date:
SELECT COUNT(*) AS TotalLoans
FROM Loan
WHERE ItemBorrowedDate = '2023-04-12';

---QUESTION 6
--- procedure to insert member
CREATE PROCEDURE InsertMember
    @Username nvarchar(50),
    @Password nvarchar(50),
	@FirstName nvarchar(100),
	@MiddleName nvarchar(100),
	@LastName nvarchar(100),
	@Address1 nvarchar(50),
	@Address2 nvarchar(50),
	@DateOfBirth date,
	@EmailAddress nvarchar(50),
	@ContactNumber nvarchar(50),
	@MembershipEndDate date
AS
BEGIN
	INSERT INTO Member (Username, Password, FirstName, MiddleName, LastName, Address1, Address2, DateOfBirth, EmailAddress, ContactNumber, MembershipEndDate)
	VALUES (@Username, @Password, @FirstName, @MiddleName, @LastName, @Address1, @Address2, @DateOfBirth, @EmailAddress, @ContactNumber, @MembershipEndDate)
END

--- Insert data into the Member table
INSERT INTO Member (Username, Password, FirstName, MiddleName, LastName, Address1, Address2, DateOfBirth, EmailAddress, ContactNumber, MembershipEndDate)
VALUES('Jude_Oseme', 'Password111', 'Jude', 'Isioma', 'Oseme', '245 lloyd St', 'Apt 10', '1990-05-05', 'jude.oseme@gmail.com', '+234-8356', '2023-06-30'),
    ('Jackson_Paul', 'Password222', 'Jackson', 'Daniel', 'Paul', '112 Hulme St', 'Suite 6', '1996-03-20', 'jackson.paul@gmail.com', '+44-6336', '2024-08-25'),
    ('Mary_John', 'Password123', 'Mary', 'Hannah', 'John', '225 Morrison st', 'Apt 2', '2000-02-15', 'Mary.john@gmail.com', '+888-2567', '2023-09-10'),
	('Mart_Luth', 'Password348', 'Martins', 'James', 'Luther','205 Bridge Close', 'Flat 1', '2000-07-09', 'Martins.Luther@gmail.com', '+809-445','2023-04-09'),
	('thomas_jefferson', 'democracy2', 'Thomas', 'Bob', 'Jefferson', '234 Monticello Ave', 'Apt 6', '1993-04-13', 'tjefferson@usa.gov', '+447-1776', '2025-09-10'),
	('george_Kenneth', 'Manchester1', 'George', 'Karim', 'Kenneth', '1 London Street', 'Suite 2', '1974-02-22', 'GeorgeKen@usa.gov', '555-1776', '2024-02-22'),
	('Mercy_David', 'Password002', 'Mercy', 'Halim', 'David', 'John Lester Court', 'Flat 10', '1994-01-01', 'Mercy.David@yahoo.com', '+234- 369', '2026-03-07'),
	('John_Stone',  'Chelsea004', 'John', 'Don', 'Stone', 'Eddie Colman Courts', 'Apt 6', '1993-02-02', 'Johnstone@gmail.com', '+234-345', '2023-05-20'),
	('Jim_Iyke', 'Password011', 'Jim', 'clinton', 'ikye', '39 Robertson Road', 'Suite 1', '1989-03-02', 'Jimiyke@yahoo.com', '+447-062', '2023-07-15'),
	('Robert_Clay', 'United05', 'Robert', 'Andrew', 'Clay', '85 Salford drive', 'Flat 3', '1999-09-06', 'RobertClay@gmail.com', '+777-093', '2023-06-07');

	SELECT * From Member 

--- Insert data into the Item table
INSERT INTO Item (ItemId, ItemTitle, ItemType, Author, YearOfPublication, Status, ISBN, ItemAddedDate)
VALUES
    (1, 'Last Dance', 'Book', 'Mark Smith', '1975-04-10', 'Available', '3252259870165', '2022-01-10'),
    (2, 'The Great Mystery', 'Book', 'H. Arnold Lugard', '1966-10-11', 'Lost', '6348235798835', '2023-03-09'),
    (3, 'Music for the Soul', 'Book', 'Stella Maris ', '1995-04-28', 'Available', '9235443278564', '2023-05-02'),
    (4, 'Africa Colonization', 'Book', 'Jim  Peter', '1982-07-09', 'Overdue', '7348862155432', '2021-08-08'),
	(5, 'Digital Industralization', 'Journal', 'Jones David', '1999-09-07','OnLoan', '6231773856249','2023-01-05'),
	(6, 'Love Birds', 'DVD', 'Marie Sally', '2006-07-12', 'Lost', '6774552371689', '2022-08-11'),
	(7, 'The Physics fundamentals', 'Journal', 'Ramsey Mark', '1983-09-03', 'Lost', '2318799068345', '2023-02-13'),
	(8, 'Data world', 'DVD', 'Luggard Smith', '1970-10-11', 'Available', '2239067354332', '2023-03-05'),
	(9, 'Engineering Mathematics','Book', 'Richard Kent', '1999-05-09', 'On Loan', '6330933380567', '2023-09-05'),
	(10, 'The Secrets of  Success', 'DVD', 'Alex Ramos', '2005-06-18', 'Removed', '4632891425648', '2023-02-05');

	SELECT * From Item

--- Insert data into the Loan table
INSERT INTO Loan (LoanId, MemberId, ItemId, ItemBorrowedDate, ItemDueDate, ItemReturnedDate, OverdueRate)
VALUES
(1, 3, 2, '2023-03-01', '2023-03-03', '2023-04-28', 0.10),
(3, 4, 3, '2023-02-10', '2023-02-15', '2023-02-27', 0.10),
(2, 5, 4, '2023-04-05', '2023-04-10', '2023-04-08', 0.00),
(5, 2, 1, '2023-04-10', '2023-05-10', '2023-05-01', 0.00),
(4, 3, 6, '2023-04-20', '2023-05-20', '2023-05-26', 0.10),
(6, 3, 1, '2023-05-10', '2023-05-25', '2023-05-23', 0.00),
(7, 5, 8, '2023-04-18', '2023-04-25', '2023-04-23', 0.00),
(8, 6, 2, '2023-03-20', '2023-04-12', '2023-04-20', 0.10),
(9, 1, 4, '2023-04-01', '2023-04-05', '2023-04-03', 0.00);

SELECT * From Loan

--- Insert data into the Overdue table
INSERT INTO Overdue (OverdueId, MemberId, ItemId, OverdueDateTime, OverdueTotalAmount)
VALUES
    (1, 2, 1, '2023-04-16 10:00:22', 1.50),
    (3, 1, 2, '2023-04-15 09:05:02', 1.20),
    (6, 4, 2, '2023-04-20 13:15:06', 2.00),
	(4, 2, 3, '2023-05-22 15:00:10', 3.00),
	(7, 4, 3, '2023-01-13 08:30:52', 1.00),
	(9, 2, 7, '2023-02-17 10:27:17', 2.50),
	(2, 8, 4, '2023-03-09 11:30:43', 4.50),
	(5, 3, 6, '2023-02-03 09:30:37', 6.20),
	(8, 5, 4, '2023-02-22 12:05:15', 3.00);

	SELECT * From Overdue


INSERT INTO Repayment (RepaymentId, OverdueId, RepaymentDateTime, RepaymentAmount, PaymentMethod)
VALUES 
(1, 3, '2023-03-01 10:15:00', 3.00, 'Credit Card'),
(3, 5, '2023-07-01 11:30:00', 1.00, 'Debit Card'),
(5, 2, '2023-05-15 14:00:00', 5.00, 'Cash'),
(4, 3, '2023-06-05 09:45:00', 8.75, 'credit card'),
(2, 4, '2023-04-23 08:20:33', 4.25, 'Cash'),
(6, 1, '2023-02-12 13:25:42', 2.00, 'Cash'),
(7, 5, '2023-03-07 12:30:20', 3.50, 'Debit Card'),
(8, 7, '2023-04-15 13:05:15', 2.50, 'Cash'),
(9, 6, '2023-06-12 15:10:45', 3.00, 'Cash');

select * From Repayment




