-- Car information tables (normalized to avoid repetition)
CREATE TABLE Make (
    MakeID INT IDENTITY(1,1) PRIMARY KEY,
    MakeName NVARCHAR(50) NOT NULL,
    CONSTRAINT UQ_MakeName UNIQUE (MakeName)
);

CREATE TABLE Model (
    ModelID INT IDENTITY(1,1) PRIMARY KEY,
    MakeID INT NOT NULL,
    ModelName NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_Model_Make FOREIGN KEY (MakeID) REFERENCES Make(MakeID),
    CONSTRAINT UQ_MakeModel UNIQUE (MakeID, ModelName)
);

CREATE TABLE SubModel (
    SubModelID INT IDENTITY(1,1) PRIMARY KEY,
    ModelID INT NOT NULL,
    SubModelName NVARCHAR(50) NOT NULL,
    CONSTRAINT FK_SubModel_Model FOREIGN KEY (ModelID) REFERENCES Model(ModelID),
    CONSTRAINT UQ_ModelSubModel UNIQUE (ModelID, SubModelName)
);

CREATE TABLE ZipCode (
    ZipCodeID INT IDENTITY(1,1) PRIMARY KEY,
    ZipCode NVARCHAR(10) NOT NULL,
    CONSTRAINT UQ_ZipCode UNIQUE (ZipCode)
);

-- Buyer information
CREATE TABLE Buyer (
    BuyerID INT IDENTITY(1,1) PRIMARY KEY,
    BuyerName NVARCHAR(100) NOT NULL,
    CONSTRAINT UQ_BuyerName UNIQUE (BuyerName)
);

-- Status definitions
CREATE TABLE Status (
    StatusID INT IDENTITY(1,1) PRIMARY KEY,
    StatusName NVARCHAR(50) NOT NULL,
    RequiresStatusDate BIT NOT NULL DEFAULT 0,
    CONSTRAINT UQ_StatusName UNIQUE (StatusName)
);

-- Car listing table
CREATE TABLE CarListing (
    CarListingID INT IDENTITY(1,1) PRIMARY KEY,
    SubModelID INT NOT NULL,
    CarYear INT NOT NULL,
    ZipCodeID INT NOT NULL,
    CurrentBuyerID INT NULL,
    CurrentStatusID INT NOT NULL,
    ListingDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_CarListing_SubModel FOREIGN KEY (SubModelID) REFERENCES SubModel(SubModelID),
    CONSTRAINT FK_CarListing_ZipCode FOREIGN KEY (ZipCodeID) REFERENCES ZipCode(ZipCodeID),
    CONSTRAINT FK_CarListing_Buyer FOREIGN KEY (CurrentBuyerID) REFERENCES Buyer(BuyerID),
    CONSTRAINT FK_CarListing_Status FOREIGN KEY (CurrentStatusID) REFERENCES Status(StatusID),
    CONSTRAINT CHK_CarYear CHECK (CarYear BETWEEN 1900 AND YEAR(GETDATE()) + 1)
);

-- Buyer quotes per zip code
CREATE TABLE BuyerZipCodeQuote (
    BuyerZipCodeQuoteID INT IDENTITY(1,1) PRIMARY KEY,
    BuyerID INT NOT NULL,
    ZipCodeID INT NOT NULL,
    QuoteAmount DECIMAL(10, 2) NOT NULL,
    IsCurrentQuote BIT NOT NULL DEFAULT 0,
    CONSTRAINT FK_BuyerZipCodeQuote_Buyer FOREIGN KEY (BuyerID) REFERENCES Buyer(BuyerID),
    CONSTRAINT FK_BuyerZipCodeQuote_ZipCode FOREIGN KEY (ZipCodeID) REFERENCES ZipCode(ZipCodeID),
    CONSTRAINT UQ_BuyerZipCode UNIQUE (BuyerID, ZipCodeID),
    CONSTRAINT CHK_QuoteAmount CHECK (QuoteAmount > 0)
);

-- Status history tracking
CREATE TABLE StatusHistory (
    StatusHistoryID INT IDENTITY(1,1) PRIMARY KEY,
    CarListingID INT NOT NULL,
    StatusID INT NOT NULL,
    ChangedBy NVARCHAR(100) NOT NULL,
    StatusDate DATETIME NOT NULL DEFAULT GETDATE(),
    Notes NVARCHAR(500) NULL,
    CONSTRAINT FK_StatusHistory_CarListing FOREIGN KEY (CarListingID) REFERENCES CarListing(CarListingID),
    CONSTRAINT FK_StatusHistory_Status FOREIGN KEY (StatusID) REFERENCES Status(StatusID)
);

-- Set RequiresStatusDate for "Picked Up" status
INSERT INTO Status (StatusName, RequiresStatusDate)
VALUES 
    ('Pending Acceptance', 0),
    ('Accepted', 0),
    ('Picked Up', 1);
	
	
	
	
	
	
	SELECT 
    c.CarListingID,m.MakeName,md.ModelName,sm.SubModelName,c.CarYear,z.ZipCode,b.BuyerName AS CurrentBuyer,bzq.QuoteAmount AS CurrentQuote,s.StatusName AS CurrentStatus,sh.StatusDate AS StatusDate
FROM 
    CarListing c
    INNER JOIN SubModel sm ON c.SubModelID = sm.SubModelID
    INNER JOIN Model md ON sm.ModelID = md.ModelID
    INNER JOIN Make m ON md.MakeID = m.MakeID
    INNER JOIN ZipCode z ON c.ZipCodeID = z.ZipCodeID
    INNER JOIN Status s ON c.CurrentStatusID = s.StatusID
    INNER JOIN StatusHistory sh ON c.CarListingID = sh.CarListingID 
        AND c.CurrentStatusID = sh.StatusID
        AND sh.StatusDate = (
            SELECT MAX(StatusDate) 
            FROM StatusHistory 
            WHERE CarListingID = c.CarListingID AND StatusID = c.CurrentStatusID
        )
    LEFT JOIN Buyer b ON c.CurrentBuyerID = b.BuyerID
    LEFT JOIN BuyerZipCodeQuote bzq ON b.BuyerID = bzq.BuyerID 
        AND c.ZipCodeID = bzq.ZipCodeID 
        AND bzq.IsCurrentQuote = 1;
	
	
	
	
	
	
	
	