CREATE SCHEMA [identity];
GO

CREATE SCHEMA [Operations];
GO

CREATE SCHEMA [Catalog];
GO  
CREATE SCHEMA [Trading];
GO
-- 1. City


CREATE TABLE [identity].City
(
    City_ID INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_City PRIMARY KEY,

    City_Name NVARCHAR(60) NOT NULL,

    Country_Code VARCHAR(2) NOT NULL
        CONSTRAINT CK_City_Country
        CHECK (Country_Code IN ('EG', 'SA', 'AE')),

    CONSTRAINT UQ_City
        UNIQUE (City_Name, Country_Code)
);


-- 2. Member


CREATE TABLE [identity].Member
(
    Member_ID UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT DF_Member_ID DEFAULT NEWID()
        CONSTRAINT PK_Member PRIMARY KEY,

    City_ID INT NOT NULL,

    Invited_By_Member_ID UNIQUEIDENTIFIER NULL,

    Full_Name NVARCHAR(100) NOT NULL,

    Email VARCHAR(254) NOT NULL
        CONSTRAINT UQ_Member_Email UNIQUE,

    Mobile VARCHAR(16) NOT NULL,

    National_ID VARCHAR(20) NOT NULL
        CONSTRAINT UQ_Member_NationalID UNIQUE,

    Birth_Date DATE NOT NULL,

    Is_Verified BIT NOT NULL
        CONSTRAINT DF_Member_Verified DEFAULT 0,

    Registered_At DATETIME2(3) NOT NULL
        CONSTRAINT DF_Member_Registered DEFAULT SYSUTCDATETIME(),

    CONSTRAINT CK_Member_NotSelfInvite
        CHECK (Invited_By_Member_ID <> Member_ID)
);

-- 3. Wallet


CREATE TABLE [identity].Wallet
(
    Member_ID UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT PK_Wallet PRIMARY KEY,

    Balance DECIMAL(12,2) NOT NULL
        CONSTRAINT DF_Wallet_Balance DEFAULT 0
        CONSTRAINT CK_Wallet_Balance CHECK (Balance >= 0),

    Amount_On_Hold DECIMAL(12,2) NOT NULL
        CONSTRAINT DF_Wallet_AmountOnHold DEFAULT 0
        CONSTRAINT CK_Wallet_AmountOnHold_Positive
        CHECK (Amount_On_Hold >= 0),

    Currency VARCHAR(3) NOT NULL
        CONSTRAINT DF_Wallet_Currency DEFAULT 'EGP',

    Updated_At DATETIME2(3) NOT NULL
        CONSTRAINT DF_Wallet_Updated DEFAULT SYSUTCDATETIME(),

    CONSTRAINT CK_Wallet_Hold_Within_Balance
        CHECK (Amount_On_Hold <= Balance)
);


-- 4. Warehouse


CREATE TABLE [Operations].Warehouse
(
    Warehouse_ID INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Warehouse PRIMARY KEY,

    Name NVARCHAR(80) NOT NULL
        CONSTRAINT UQ_Warehouse_Name UNIQUE,

    Capacity INT NOT NULL
        CONSTRAINT CK_Warehouse_Capacity CHECK (Capacity > 0),

    City_ID INT NOT NULL,

    Latitude FLOAT NOT NULL
        CONSTRAINT CK_Warehouse_Latitude
        CHECK (Latitude BETWEEN -90 AND 90),

    Longitude FLOAT NOT NULL
        CONSTRAINT CK_Warehouse_Longitude
        CHECK (Longitude BETWEEN -180 AND 180),

    Manager_ID UNIQUEIDENTIFIER NULL
        CONSTRAINT UQ_Warehouse_Manager UNIQUE,

    Manager_Since DATE NULL
);


-- 5. Employee


CREATE TABLE [Operations].Employee
(
    Member_ID UNIQUEIDENTIFIER NOT NULL
        CONSTRAINT PK_Employee PRIMARY KEY,

    Warehouse_ID INT NOT NULL
);


--6. Category


CREATE TABLE [Catalog].Category
(
    Category_Code INT NOT NULL
        CONSTRAINT PK_Category PRIMARY KEY,

    Parent_Category_Code INT NULL,

    Name_EN VARCHAR(50) NOT NULL
        CONSTRAINT UQ_Category_Name_EN UNIQUE,

    Name_AR NVARCHAR(50) NULL,

    Commission_Pct DECIMAL(4,2) NOT NULL
        CONSTRAINT CK_Category_Commission
        CHECK (Commission_Pct BETWEEN 0 AND 30)
);

--7. Item

CREATE TABLE [Catalog].Item
(
    Item_ID INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Item PRIMARY KEY,

    Title NVARCHAR(150) NOT NULL,

    Description NVARCHAR(MAX) NULL,

    Condition_Score TINYINT NOT NULL
        CONSTRAINT CK_Item_ConditionScore
        CHECK (Condition_Score BETWEEN 1 AND 10),

    Specifications NVARCHAR(MAX) NOT NULL
        CONSTRAINT CK_Item_Specifications
        CHECK (ISJSON(Specifications) = 1),

    Seller_ID UNIQUEIDENTIFIER NOT NULL,

    Category_Code INT NOT NULL,

    Warehouse_ID INT NULL,

    Inspector_ID UNIQUEIDENTIFIER NOT NULL,

    Listed_At DATETIME2(3) NOT NULL,

    CONSTRAINT CK_Item_Seller_Inspector
        CHECK (Seller_ID <> Inspector_ID)
);
--8. Item_Photo


CREATE TABLE [Catalog].Item_Photo
(
    Item_ID INT NOT NULL,

    Position TINYINT NOT NULL
        CONSTRAINT CK_ItemPhoto_Position
        CHECK (Position BETWEEN 1 AND 20),

    URL VARCHAR(500) NOT NULL,

    Is_Main BIT NOT NULL
        CONSTRAINT DF_ItemPhoto_IsMain DEFAULT 0,

    CONSTRAINT PK_Item_Photo
        PRIMARY KEY (Item_ID, Position)
);
--9. Auction

CREATE TABLE [Trading].Auction
(
    Auction_ID INT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Auction PRIMARY KEY,

    Item_ID INT NOT NULL,

    Starting_Price DECIMAL(12,2) NOT NULL
        CONSTRAINT CK_Auction_StartingPrice
        CHECK (Starting_Price > 0),

    Reserve_Price DECIMAL(12,2)  NULL,

    Bid_Increment DECIMAL(12,2) NOT NULL
        CONSTRAINT DF_Auction_BidIncrement DEFAULT 50,

    Starts_At DATETIMEOFFSET(0) NOT NULL,

    Ends_At DATETIMEOFFSET(0) NOT NULL,

    Status VARCHAR(10) NOT NULL
        CONSTRAINT DF_Auction_Status DEFAULT 'draft'
        CONSTRAINT CK_Auction_Status
        CHECK (Status IN ('draft', 'live', 'ended', 'canceled')),

    CONSTRAINT CK_Auction_Dates
        CHECK (Ends_At > Starts_At),
    CONSTRAINT CK_Auction_ReservePrice
        CHECK (Reserve_Price >= Starting_Price)
);
--10. Bid


CREATE TABLE [Trading].Bid
(
    Bid_ID BIGINT IDENTITY(1,1) NOT NULL
        CONSTRAINT PK_Bid PRIMARY KEY,

    Auction_ID INT NOT NULL,

    Member_ID UNIQUEIDENTIFIER NOT NULL,

    Amount DECIMAL(12,2) NOT NULL
        CONSTRAINT CK_Bid_Amount CHECK (Amount > 0),

    Placed_At DATETIME2(3) NOT NULL,

    IP_Address VARCHAR(45) NOT NULL,

    CONSTRAINT UQ_Bid_Auction_Member
        UNIQUE (Auction_ID, Member_ID)
);
--11. Follow


CREATE TABLE [Trading].Follow
(
    Member_ID UNIQUEIDENTIFIER NOT NULL,

    Auction_ID INT NOT NULL,

    Followed_At DATETIME2(3) NOT NULL,

    CONSTRAINT PK_Follow
        PRIMARY KEY (Member_ID, Auction_ID)
);
-- Member -> City
ALTER TABLE [identity].Member
ADD CONSTRAINT FK_Member_City
FOREIGN KEY (City_ID)
REFERENCES [identity].City(City_ID);

-- Member -> Member (Self Reference)
ALTER TABLE [identity].Member
ADD CONSTRAINT FK_Member_InvitedBy
FOREIGN KEY (Invited_By_Member_ID)
REFERENCES [identity].Member(Member_ID);

-- Wallet -> Member
ALTER TABLE [identity].Wallet
ADD CONSTRAINT FK_Wallet_Member
FOREIGN KEY (Member_ID)
REFERENCES [identity].Member(Member_ID);

-- Warehouse -> City
ALTER TABLE [Operations].Warehouse
ADD CONSTRAINT FK_Warehouse_City
FOREIGN KEY (City_ID)
REFERENCES [identity].City(City_ID);

-- Employee -> Member
ALTER TABLE [Operations].Employee
ADD CONSTRAINT FK_Employee_Member
FOREIGN KEY (Member_ID)
REFERENCES [identity].Member(Member_ID);

-- Employee -> Warehouse
ALTER TABLE [Operations].Employee
ADD CONSTRAINT FK_Employee_Warehouse
FOREIGN KEY (Warehouse_ID)
REFERENCES [Operations].Warehouse(Warehouse_ID);

-- Warehouse -> Employee (Manager)
ALTER TABLE [Operations].Warehouse
ADD CONSTRAINT FK_Warehouse_Manager
FOREIGN KEY (Manager_ID)
REFERENCES [Operations].Employee(Member_ID);


-- Category -> Category (Parent Category)
ALTER TABLE [Catalog].Category
ADD CONSTRAINT FK_Category_Parent
FOREIGN KEY (Parent_Category_Code)
REFERENCES [Catalog].Category(Category_Code);

-- Item -> Member (Seller)
ALTER TABLE [Catalog].Item
ADD CONSTRAINT FK_Item_Seller
FOREIGN KEY (Seller_ID)
REFERENCES [identity].Member(Member_ID);

-- Item -> Category
ALTER TABLE [Catalog].Item
ADD CONSTRAINT FK_Item_Category
FOREIGN KEY (Category_Code)
REFERENCES [Catalog].Category(Category_Code);

-- Item -> Warehouse
ALTER TABLE [Catalog].Item
ADD CONSTRAINT FK_Item_Warehouse
FOREIGN KEY (Warehouse_ID)
REFERENCES [Operations].Warehouse(Warehouse_ID);

-- Item -> Employee (Inspector)
ALTER TABLE [Catalog].Item
ADD CONSTRAINT FK_Item_Inspector
FOREIGN KEY (Inspector_ID)
REFERENCES [Operations].Employee(Member_ID);

-- Item_Photo -> Item
ALTER TABLE [Catalog].Item_Photo
ADD CONSTRAINT FK_ItemPhoto_Item
FOREIGN KEY (Item_ID)
REFERENCES [Catalog].Item(Item_ID)
ON DELETE CASCADE; --هنا cascade عشان قال انه لازم لو مسحت ال item ال item_Photo الخاصه بيه تتمسح



-- Auction -> Item
ALTER TABLE [Trading].Auction
ADD CONSTRAINT FK_Auction_Item
FOREIGN KEY (Item_ID)
REFERENCES [Catalog].Item(Item_ID);

-- Bid -> Auction
ALTER TABLE [Trading].Bid
ADD CONSTRAINT FK_Bid_Auction
FOREIGN KEY (Auction_ID)
REFERENCES [Trading].Auction(Auction_ID);

-- Bid -> Member
ALTER TABLE [Trading].Bid
ADD CONSTRAINT FK_Bid_Member
FOREIGN KEY (Member_ID)
REFERENCES [identity].Member(Member_ID);

-- Follow -> Member
ALTER TABLE [Trading].Follow
ADD CONSTRAINT FK_Follow_Member
FOREIGN KEY (Member_ID)
REFERENCES [identity].Member(Member_ID);

-- Follow -> Auction
ALTER TABLE [Trading].Follow
ADD CONSTRAINT FK_Follow_Auction
FOREIGN KEY (Auction_ID)
REFERENCES [Trading].Auction(Auction_ID);



--------------------------------------------------------
-----3.2 
Alter table [identity].Member
Add Language_Type  NVARCHAR(2) NOT NULL
CONSTRAINT DF_Member_LanguageType DEFAULT 'ar'
CONSTRAINT CK_Member_LanguageType CHECK (Language_Type IN('en','ar'))

----3.3
Alter table [Catalog].Item
ADD Is_Featured VARCHAR(3) NOT NULL
CONSTRAINT DF_Item_IsFeatured DEFAULT 'No'
CONSTRAINT CK_Item_IsFeatured CHECK (Is_Featured IN('Yes','No'))
---3.4
EXEC sp_rename 'Trading.Bid.IP_Address', 'DeviceIp', 'COLUMN';

ALTER TABLE Operations.Warehouse
DROP CONSTRAINT CK_Warehouse_Capacity;   

EXEC sp_rename 'Operations.Warehouse.Capacity', 'MaxItems', 'COLUMN';

ALTER TABLE Operations.Warehouse
ADD CONSTRAINT CK_Warehouse_MaxItems CHECK (MaxItems > 0);

---3.5
ALTER TABLE [identity].Member
ALTER COLUMN Full_Name NVARCHAR(150) NOT NULL;
---3.6
ALTER TABLE Operations.Warehouse
DROP CONSTRAINT CK_Warehouse_MaxItems;

ALTER TABLE Operations.Warehouse
ALTER COLUMN MaxItems SMALLINT NOT NULL;

ALTER TABLE Operations.Warehouse
ADD CONSTRAINT CK_Warehouse_MaxItems CHECK (MaxItems > 0);

--3.7
ALTER TABLE Catalog.Category
DROP CONSTRAINT CK_Category_Commission; 

ALTER TABLE Catalog.Category
ADD CONSTRAINT CK_Category_Commission
    CHECK (Commission_Pct >= 0 AND Commission_Pct <= 25);

--3.8
ALTER TABLE Trading.Auction
DROP CONSTRAINT CK_Auction_Status;      

ALTER TABLE Trading.Auction
DROP CONSTRAINT DF_Auction_Status;     

ALTER TABLE Trading.Auction
ALTER COLUMN Status VARCHAR(13) NOT NULL;

ALTER TABLE Trading.Auction
ADD CONSTRAINT DF_Auction_Status DEFAULT 'PendingReview' FOR Status;

ALTER TABLE Trading.Auction
ADD CONSTRAINT CK_Auction_Status
    CHECK (Status IN ('PendingReview', 'Draft', 'Live', 'Ended', 'Cancelled'));

--3.9
ALTER TABLE Trading.Auction
ADD Bye_Now DECIMAL(12,2) NULL;


ALTER TABLE [Trading].Auction
WITH CHECK ADD CONSTRAINT CK_Aution_BuyNow_Above_Start
CHECK(Bye_Now>Starting_Price);
---3.10
ALTER TABLE [Identity].Member
ADD CONSTRAINT UQ_Member_Mobile Unique(Mobile);

--3.11
ALTER TABLE [identity].Member
DROP CONSTRAINT DF_Member_Verified;

ALTER TABLE [identity].Member
DROP COLUMN Is_Verified;

ALTER TABLE [identity].Member
ADD VerifiedAt DATETIME2(3) NULL;

--3.12
CREATE SCHEMA [Marketing];
GO

Alter schema [Marketing]
Transfer [Trading].Follow;
Go

    