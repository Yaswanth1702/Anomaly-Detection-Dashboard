------------MAIN----------------
-- Step 1: Drop the Main table if it already exists
DROP TABLE IF EXISTS Main;

-- Step 2: Create the Main temporary table (simplified structure)
CREATE TABLE Main ( 
   StoreID INT,
   FranID INT,
   PeriodID INT,
   AccountID INT,
   Amount DECIMAL(18,2),
   PercentCol DECIMAL(18,2),
   PRIMARY KEY CLUSTERED (StoreID, FranID, PeriodID, AccountID)
);


-- Step 3: Insert data into Main from Final.MainData ----------------------
INSERT INTO Main (StoreID, FranID, PeriodID, AccountID, Amount, PercentCol)
SELECT
   StoreID,
   FranID,
   REPLACE(PeriodID, '-', '') PeriodID,
   AccountID,
   Amount,
   0.0 AS PercentCol -- Initialize PercentCol to 0.0
FROM Final.MainData;
--WHERE StoreID = 100031; -- Filter by StoreID if needed


-- Step 4: AccountCalc data ------------------------------------------------
INSERT INTO Main (FranID, periodId, AccountID, Amount, PercentCol, StoreID)
SELECT
    A.FranID,
    A.periodID,
    B.DestAccountID,
    SUM(A.Amount * B.Multiplier) AS SumCol,
    0.0 AS AccountCalcPercent,
    A.StoreID
FROM Main A
JOIN Final.AccountCalc B
    ON A.AccountID = B.SourceAccountID
WHERE A.StoreID is not null
GROUP BY
    A.FranID,
    A.periodID,
    B.DestAccountID,
    A.StoreID


-- Step 5: Sales -----------------------------------------------------------
INSERT INTO Main (FranID, periodId, StoreID, AccountID, Amount, PercentCol)
SELECT
    A.FranID,
    A.periodID,
    A.StoreID,
    -10 as AccountID,
    B.Sales as Amount,
    0.0 AS PercentCol
FROM (SELECT DISTINCT
        FranID, StoreID, PeriodId
        FROM Main) A
JOIN Final.POSSales B
    ON A.StoreID = B.StoreID
    AND A.periodId = REPLACE(B.PeriodID, '-', '') 
GROUP BY
    A.FranID,
    A.periodID,
    A.StoreID,
    B.Sales


-- Step 6: Insert zeros into missing values ---------------------------------
INSERT INTO Main (FranID, periodId, StoreID, AccountID, Amount, PercentCol)
SELECT
    M.FranID,
    M.periodID,
    M.StoreID,
    A.AccountID,
    0 as Amount,
    0.0 AS PercentCol
FROM
    (select distinct
        FranID, StoreID, periodID
        FROM Main) M
JOIN Final.Accounts A
    ON 1=1
WHERE Not Exists (
    Select *
    FROM Main x
    WHERE
        m.FranID = x.FranID
        AND m.storeID = x.StoreID
        AND m.PeriodID = x.periodId
        AND A.accountID = x.AccountID
)


-- Step 7: Calculate and update percentages ---------------------------------
-- Firsty, calculating total amounts for each FranID and PeriodID then update the PercentCol in Main
UPDATE A
SET A.PercentCol = (A.Amount / B.TotalAmount) * 100 -- Calculate percentage
FROM Main A
JOIN (
   SELECT
       FranID,
       PeriodID,
       SUM(Amount) AS TotalAmount
   FROM Main
   Where StoreID is not null
   GROUP BY FranID, PeriodID
) B ON A.FranID = B.FranID AND A.PeriodID = B.PeriodID;


-- Step 8: Verify final data in Main ---------------------------------------
SELECT * FROM Main
ORDER BY AccountID, FranID, PeriodID;



------------------------Validations---------------------------
-- Step 1: Drop validations tables if they already exist
DROP TABLE Validations;

-- Step 2: Create validations Table
CREATE TABLE Validations (
    ValidationID INT IDENTITY(1,1) PRIMARY KEY,
    FranchiseeID INT,
    StoreID INT,
    PeriodID INT,
    RuleID INT,
    ErrorMessage NVARCHAR(500),
    Severity INT
);

------------------------------MainPivot--------------------------------
-- Step 1:  Drop temporary tables if they already exist
DROP TABLE MainPivot;

DROP TABLE AccountTmp;


-- Step 2: Create the MainPivot table
CREATE TABLE MainPivot (
    StoreID INT,
    FranID INT,
    PeriodID INT,
    IsExpected TINYINT, -- New column
    IsSubmitted TINYINT, -- New column
    PRIMARY KEY CLUSTERED (
        StoreID, FranID, PeriodID
    )
);

-- Step 3: Create the AccountTmp table
CREATE TABLE AccountTmp (
    SeqID INT IDENTITY(1,1),
    AccountID INT,
    PRIMARY KEY CLUSTERED (
        AccountID
    )
);

-- Step 4: Insert unique AccountID values into AccountTmp
INSERT INTO AccountTmp (AccountID)
SELECT DISTINCT
    AccountID
FROM Main;

-- Step 5: Insert base data into MainPivot
INSERT INTO MainPivot (
    StoreID, FranID, PeriodID, IsExpected, IsSubmitted
)
SELECT DISTINCT 
    StoreID,
    FranID,
    PeriodID,
    0 AS IsExpected, -- Initialize IsExpected to 0
    0 AS IsSubmitted -- Initialize IsSubmitted to 0
FROM Main;


-- Step 6: Declare variables for dynamic SQL
DECLARE @SQL NVARCHAR(MAX);
DECLARE @i INT = 1;
-- Loop through each AccountID in AccountTmp
WHILE (@i <= (SELECT MAX(SeqID) FROM AccountTmp))
BEGIN
    -- Add Nominal column for AccountID
    SET @SQL = 'ALTER TABLE MainPivot ADD [' + (SELECT CONVERT(NVARCHAR, AccountID) FROM AccountTmp WHERE SeqID = @i) + '] MONEY';
    EXEC sp_executesql @SQL;

    -- Add Percentage column for AccountID
    SET @SQL = 'ALTER TABLE MainPivot ADD [' + (SELECT CONVERT(NVARCHAR, AccountID) FROM AccountTmp WHERE SeqID = @i) + '_Pct] FLOAT';
    EXEC sp_executesql @SQL;

    -- Update Nominal and Percentage columns
    SET @SQL = '
        UPDATE A
        SET A.[' + (SELECT CONVERT(NVARCHAR, AccountID) FROM AccountTmp WHERE SeqID = @i) + '] = B.Amount,
            A.[' + (SELECT CONVERT(NVARCHAR, AccountID) FROM AccountTmp WHERE SeqID = @i) + '_Pct] = B.PercentCol
        FROM MainPivot A
        JOIN Main B
            ON A.StoreID = B.StoreID
            AND A.FranID = B.FranID
            AND A.PeriodID = B.PeriodID
        WHERE B.AccountID = ' + (SELECT CONVERT(NVARCHAR, AccountID) FROM AccountTmp WHERE SeqID = @i);
    EXEC sp_executesql @SQL;

    -- Increment counter
    SET @i = @i + 1;
END;

-- Step 7: Update IsExpected and IsSubmitted columns
UPDATE MainPivot
SET 
    IsExpected = 0.0, -- (example logic)
    IsSubmitted = 0.0 -- (example logic)
WHERE 
    StoreID IN (SELECT DISTINCT StoreID FROM Main) -- Example condition
    AND FranID IN (SELECT DISTINCT FranID FROM Main); -- Example condition

--Step 8: Verify the final MainPivot
SELECT * FROM MainPivot;


----------------------------Rules-----------------------------
-- Step 1: Drop Rules tables if they already exist
DROP TABLE Rules;

-- Step 2: Create Rules Table
CREATE TABLE Rules (
    RuleID INT PRIMARY KEY,
    RuleType NVARCHAR(50),
    RuleMetric NVARCHAR(50),
    ValidCondition NVARCHAR(500),
    ErrorMessage NVARCHAR(500),
    Severity INT,
    Lvl NVARCHAR(50),
);
-- Step 3: Insert rules (from spreadsheet)
INSERT INTO Rules (RuleID, RuleType, RuleMetric, ValidCondition, ErrorMessage, Severity, Lvl)
VALUES
(1, 'Comparison', '$', '[10160] != [10350]', 'Total Assets ([10160]) does NOT match Total Liabilities + Equity ([10350]).', 1, 'Organization'),
(2, 'Threshold', '$', '[10] <= 0', 'Product Sales ([10]) is negative.', 3, 'Store'),
(3, 'Threshold', '$', '[330] <= 0', 'Non-Product Sales ([330]) is negative.', 3, 'Store'),
(4, 'Percentage', '%', '([20] / NULLIF([50],0)) >= 0.85', 'Food Costs ([20]) exceeds 85% of Total Costs ([50]).', 2, 'Franchisee'),
(5, 'Percentage', '%', '([30] / NULLIF([50],0)) <= 0.35', 'Paper Costs ([30]) does NOT exceed 35% of Total Costs ([50]).', 2, 'Franchisee'),
(6, 'Comparison', '$', '[10] - [50] != [60]', 'Gross Profit ([60]) does NOT equal Product Sales ([10]) - Total Sales ([50]).', 1, 'Organization'),
(7, 'Comparison', '$', '[60] - [90] != [100]', 'Profit Before Taxes ([100]) does NOT equal Gross Profit ([60]) - Expenses ([90]).', 1, 'Organization'),
(8, 'Comparison', '$', '[100] - [110] != [120]', 'Net Income ([120]) does NOT equal Profit Before Taxes ([100]) - Taxes ([110]).', 1, 'Organization'),
(9, 'Comparison', '$', '[10310] + [10340] != [10160]', 'Total Assets ([10160]) does NOT equal Liabilities ([10310]) + Equity ([10340]).', 1, 'Organization'),
(10, 'Comparison', '$', '[10320] + [10330] + [10310] != [10340]', 'Equity ([10340]) does NOT match sum of Profit ([10320]) + Dividends ([10330]) + Retained Earnings ([10310]).', 1, 'Organization'),
(11, 'Threshold', '$', '[60] <= 0', 'Gross Profit ([60]) is negative.', 2, 'Franchisee'),
(12, 'Threshold', '$', '[100] <= 0', 'Profit Before Taxes ([100]) is negative.', 2, 'Franchisee'),
(13, 'Percentage', '%', '([50] / NULLIF([10],0)) NOT BETWEEN 0.10 AND 0.50', 'The Cost of Sales ([50]) over Product Sales ([10]) ratio is greater than 50% or less than 10%.', 2, 'Franchisee');

-- Step 4: Simple Rules Validation 
GO 
DECLARE @SQL as NVARCHAR(MAX) 
DECLARE @i AS INT
SET @SQL = ''
SET @i = 10
--DECLARE @i INT = 1;
DECLARE @MaxRuleID INT = (SELECT MAX(RuleID) FROM Rules)
--DECLARE @SQL NVARCHAR(MAX); 
WHILE @i <= @MaxRuleID
BEGIN
    -- Now insert validation results (using your pattern)
    SET @SQL = N'
    INSERT INTO Validations
    (FranchiseeID, StoreID, PeriodID, RuleID, ErrorMessage, severity)
    SELECT
        f.FranID AS FranchiseeID,
        f.StoreID,
        f.PeriodID AS FiscalYearID,
        r.RuleID,
        r.ErrorMessage AS MSG,
        r.Severity
    FROM MainPivot f
    CROSS JOIN Rules r
    WHERE r.RuleID = ' + CONVERT(nVarChar,@i) + N'
    AND ' + (SELECT ValidCondition FROM Rules WHERE RuleID = @i)
    
    -- Execute dynamic SQL with properly passed parameters
    --EXEC sp_executesql @SQL, N'@RuleID INT', @i
    --print @SQL 
    EXEC sp_executesql @SQL
    
    SET @i = @i + 1
END
 SELECT * From Validations;

