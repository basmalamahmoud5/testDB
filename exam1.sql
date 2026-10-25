USE UniversityResearchSystem;
GO
-- q1
SELECT r.Id AS ResearcherId,CONCAT(r.FirstName,' ',r.MiddleName,' ',r.LastName) AS ResearcherName,p.Id AS ProjectId,p.Title AS ProjectTitle
FROM dbo.Researcher r
LEFT JOIN dbo.WorksOn w ON r.Id=w.ResearcherId
LEFT JOIN dbo.ResearchProject p ON w.ProjectId=p.Id
ORDER BY r.Id;
GO
-- q2
SELECT p.Id AS ProjectId,p.Title,CONCAT(r.FirstName,' ',r.LastName) AS LeaderName,r.Email
FROM dbo.ResearchProject p
JOIN dbo.Researcher r ON p.LeaderId=r.Id
WHERE EXISTS(SELECT 1 FROM dbo.Funds f WHERE f.ProjectId=p.Id);
GO
-- q3
SELECT r.Id AS ResearcherId,CONCAT(r.FirstName,' ',r.LastName) AS ResearcherName,p.Id AS PublicationId,p.Title
FROM dbo.Researcher r
CROSS JOIN dbo.Publication p;
GO
-- q4
SELECT s.SupervisorId,CONCAT(sup.FirstName,' ',sup.LastName) AS SupervisorName,s.SupervisedId,CONCAT(sub.FirstName,' ',sub.LastName) AS SupervisedResearcher,s.SupervisionStartDate,s.Role
FROM dbo.Supervises s
JOIN dbo.Researcher sup ON s.SupervisorId=sup.Id
JOIN dbo.Researcher sub ON s.SupervisedId=sub.Id
ORDER BY s.SupervisorId,s.SupervisedId;
GO
-- q5
SELECT r.Id,CONCAT(r.FirstName,' ',r.LastName) AS ResearcherName
FROM dbo.Researcher r
WHERE EXISTS(SELECT 1 FROM dbo.Publishes pu WHERE pu.ResearcherId=r.Id)
AND NOT EXISTS(SELECT 1 FROM dbo.WorksOn w JOIN dbo.ResearchProject p ON w.ProjectId=p.Id WHERE w.ResearcherId=r.Id AND p.Status='Active');
GO
-- q6
SELECT TOP 5 WITH TIES Id,Title,CitationCount,Type
FROM dbo.Publication
ORDER BY CitationCount DESC;
GO
-- q7
SELECT Id,FirstName,LastName,Email
FROM dbo.Researcher
ORDER BY LastName,FirstName,Id
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
GO
-- q8
SELECT TOP 3 Id,LastName,FirstName
FROM dbo.Researcher
ORDER BY LastName,FirstName,Id;
GO
SELECT Id,LastName,FirstName
FROM dbo.Researcher
ORDER BY LastName,FirstName,Id
OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY;
GO
-- q9
SELECT Id,FirstName,LastName,Building,DateOfBirth,ROW_NUMBER() OVER(PARTITION BY Building ORDER BY DateOfBirth,Id) AS RowNum
FROM dbo.Researcher;
GO
-- q10
SELECT Id,Title,Type,CitationCount,RANK() OVER(PARTITION BY Type ORDER BY CitationCount DESC) AS CitationRank
FROM dbo.Publication
WHERE Type IN('Journal','Conference')
ORDER BY Type,CitationRank;
GO
-- q11
SELECT Id,Title,Status,Budget,RANK() OVER(PARTITION BY Status ORDER BY Budget DESC) AS BudgetRank,DENSE_RANK() OVER(PARTITION BY Status ORDER BY Budget DESC) AS DenseBudgetRank
FROM dbo.ResearchProject
ORDER BY Status,Budget DESC;
GO
-- q12
WITH ResearcherPublicationCounts AS
(
    SELECT r.Id,r.FirstName,r.LastName,COUNT(DISTINCT pu.PublicationId) AS PublicationCount
    FROM dbo.Researcher r
    LEFT JOIN dbo.Publishes pu ON r.Id=pu.ResearcherId
    GROUP BY r.Id,r.FirstName,r.LastName
)
SELECT Id,FirstName,LastName,PublicationCount,NTILE(4) OVER(ORDER BY PublicationCount DESC,Id) AS Quartile
FROM ResearcherPublicationCounts;
GO
-- q13
SELECT Building,COUNT(*) AS ResearcherCount
FROM dbo.Researcher
GROUP BY Building
HAVING COUNT(*)>3
ORDER BY ResearcherCount DESC;
GO
-- q14
SELECT ResearcherId,COUNT(DISTINCT ProjectId) AS ProjectCount
FROM dbo.WorksOn
GROUP BY ResearcherId
HAVING COUNT(DISTINCT ProjectId)>2;
GO
-- q15
SELECT Id,CONCAT(FirstName,' ',MiddleName,' ',LastName) AS FullName,LOWER(Email) AS LowercaseEmail,DATEDIFF(YEAR,DateOfBirth,GETDATE())-CASE WHEN DATEADD(YEAR,DATEDIFF(YEAR,DateOfBirth,GETDATE()),DateOfBirth)>GETDATE() THEN 1 ELSE 0 END AS Age
FROM dbo.Researcher;
GO
-- q16
SELECT Id,Title,StartDate,EndDate,DATEDIFF(DAY,StartDate,COALESCE(EndDate,CAST(GETDATE() AS DATE))) AS ProjectDurationDays,MONTH(StartDate) AS StartMonth,YEAR(StartDate) AS StartYear
FROM dbo.ResearchProject;
GO
-- q17
SELECT Id,Email
FROM dbo.Researcher
WHERE Email IS NOT NULL AND CHARINDEX('@',Email)>0 AND LOWER(SUBSTRING(Email,CHARINDEX('@',Email)+1,LEN(Email)))='university.edu';
GO
-- q18
SELECT Id,FirstName,COALESCE(NULLIF(MiddleName,''),'N/A') AS MiddleName,LastName,COALESCE(NULLIF(RoomNumber,''),'N/A') AS RoomNumber
FROM dbo.Researcher;
GO
-- q19
SELECT Id,Title,Budget,CASE WHEN Budget<50000 THEN 'Small' WHEN Budget<=150000 THEN 'Medium' ELSE 'Large' END AS BudgetCategory
FROM dbo.ResearchProject;
GO
-- q20
SELECT r.Id,CONCAT(r.FirstName,' ',r.LastName) AS LeaderName,COALESCE(SUM(p.Budget),0) AS TotalProjectBudget
FROM dbo.Researcher r
LEFT JOIN dbo.ResearchProject p ON r.Id=p.LeaderId
GROUP BY r.Id,r.FirstName,r.LastName
ORDER BY TotalProjectBudget DESC;
GO
-- q21
SELECT Building,COUNT(*) AS ResearcherCount
FROM dbo.Researcher
GROUP BY Building
HAVING COUNT(*)>3;
GO
-- q22
SELECT Type,AVG(CAST(CitationCount AS DECIMAL(10,2))) AS AverageCitations,SUM(CitationCount) AS TotalCitations,COUNT(*) AS PublicationCount
FROM dbo.Publication
GROUP BY Type
HAVING AVG(CAST(CitationCount AS DECIMAL(10,2)))>50;
GO
-- q23
SELECT ResearcherId,COUNT(DISTINCT ProjectId) AS ProjectCount,SUM(HoursPerWeek) AS TotalWeeklyHours
FROM dbo.WorksOn
GROUP BY ResearcherId
HAVING COUNT(DISTINCT ProjectId)>2 AND SUM(HoursPerWeek)>60;
GO
-- q24
SELECT Id,Title,Budget
FROM dbo.ResearchProject
WHERE Budget>(SELECT AVG(Budget) FROM dbo.ResearchProject);
GO
-- q25
WITH ResearcherPublicationCounts AS
(
    SELECT r.Id,r.Building,COUNT(DISTINCT pu.PublicationId) AS PublicationCount
    FROM dbo.Researcher r
    LEFT JOIN dbo.Publishes pu ON r.Id=pu.ResearcherId
    GROUP BY r.Id,r.Building
),
BuildingAverages AS
(
    SELECT Building,AVG(CAST(PublicationCount AS DECIMAL(10,2))) AS AveragePublications
    FROM ResearcherPublicationCounts
    GROUP BY Building
)
SELECT rpc.Id,rpc.Building,rpc.PublicationCount,ba.AveragePublications
FROM ResearcherPublicationCounts rpc
JOIN BuildingAverages ba ON rpc.Building=ba.Building OR (rpc.Building IS NULL AND ba.Building IS NULL)
WHERE rpc.PublicationCount>ba.AveragePublications;
GO
-- q26
SELECT r.Id,r.FirstName,r.LastName
FROM dbo.Researcher r
WHERE EXISTS(SELECT 1 FROM dbo.Supervises s WHERE s.SupervisorId=r.Id);
GO
-- q27
SELECT p.Id,p.Title,(SELECT COUNT(DISTINCT w.ResearcherId) FROM dbo.WorksOn w WHERE w.ProjectId=p.Id) AS ResearcherCount
FROM dbo.ResearchProject p
ORDER BY p.Id;
GO
-- q28
SELECT MAX(Budget) AS SecondHighestDistinctBudget
FROM dbo.ResearchProject
WHERE Budget<(SELECT MAX(Budget) FROM dbo.ResearchProject);
GO
-- q29
SELECT Email AS ContactInformation
FROM dbo.Researcher
WHERE Email IS NOT NULL
UNION ALL
SELECT FundingAgency AS ContactInformation
FROM dbo.Grants
WHERE FundingAgency IS NOT NULL;
GO
-- q30
SELECT DISTINCT r.Id,CONCAT(r.FirstName,' ',r.LastName) AS ResearcherName
FROM dbo.Researcher r
JOIN dbo.WorksOn w ON r.Id=w.ResearcherId
WHERE NOT EXISTS(SELECT 1 FROM dbo.Publishes pu WHERE pu.ResearcherId=r.Id);
GO
-- q31
SELECT DISTINCT r.Id,CONCAT(r.FirstName,' ',r.LastName) AS ResearcherName
FROM dbo.Researcher r
WHERE EXISTS(SELECT 1 FROM dbo.Supervises s WHERE s.SupervisorId=r.Id)
AND EXISTS(SELECT 1 FROM dbo.ResearchProject p WHERE p.LeaderId=r.Id);
GO
-- q32
WITH ResearcherHours AS
(
    SELECT ResearcherId,SUM(HoursPerWeek) AS TotalWeeklyHours
    FROM dbo.WorksOn
    GROUP BY ResearcherId
)
SELECT r.Id,CONCAT(r.FirstName,' ',r.LastName) AS ResearcherName,rh.TotalWeeklyHours
FROM ResearcherHours rh
JOIN dbo.Researcher r ON rh.ResearcherId=r.Id
WHERE rh.TotalWeeklyHours>40;
GO
-- q33
WITH LeaderBudgets AS
(
    SELECT LeaderId,SUM(Budget) AS TotalBudget
    FROM dbo.ResearchProject
    GROUP BY LeaderId
),
ResearcherPublicationCounts AS
(
    SELECT ResearcherId,COUNT(DISTINCT PublicationId) AS PublicationCount
    FROM dbo.Publishes
    GROUP BY ResearcherId
)
SELECT r.Id,CONCAT(r.FirstName,' ',r.LastName) AS ResearcherName,lb.TotalBudget,rpc.PublicationCount
FROM LeaderBudgets lb
JOIN dbo.Researcher r ON lb.LeaderId=r.Id
JOIN ResearcherPublicationCounts rpc ON rpc.ResearcherId=r.Id
WHERE lb.TotalBudget>100000 AND rpc.PublicationCount>=3;
GO
-- q34
CREATE OR ALTER FUNCTION dbo.GetProjectDuration(@ProjectId VARCHAR(50))
RETURNS INT
AS
BEGIN
    DECLARE @Duration INT;
    SELECT @Duration=DATEDIFF(DAY,StartDate,COALESCE(EndDate,CAST(GETDATE() AS DATE)))
    FROM dbo.ResearchProject
    WHERE Id=@ProjectId;
    RETURN @Duration;
END;
GO
-- q35
CREATE OR ALTER FUNCTION dbo.GetResearcherProjects(@ResearcherId VARCHAR(50))
RETURNS TABLE
AS
RETURN
(
    SELECT p.Id AS ProjectId,p.Title AS ProjectTitle,w.Role,w.HoursPerWeek
    FROM dbo.WorksOn w
    JOIN dbo.ResearchProject p ON w.ProjectId=p.Id
    WHERE w.ResearcherId=@ResearcherId
);
GO
-- q36
CREATE OR ALTER FUNCTION dbo.GetResearcherStats(@ResearcherId VARCHAR(50))
RETURNS @Stats TABLE(ProjectCount INT,PublicationCount INT,TotalWeeklyHours INT,AverageCitations DECIMAL(10,2))
AS
BEGIN
    INSERT INTO @Stats(ProjectCount,PublicationCount,TotalWeeklyHours,AverageCitations)
    SELECT
        (SELECT COUNT(DISTINCT ProjectId) FROM dbo.WorksOn WHERE ResearcherId=@ResearcherId),
        (SELECT COUNT(DISTINCT PublicationId) FROM dbo.Publishes WHERE ResearcherId=@ResearcherId),
        (SELECT COALESCE(SUM(HoursPerWeek),0) FROM dbo.WorksOn WHERE ResearcherId=@ResearcherId),
        (SELECT AVG(CAST(p.CitationCount AS DECIMAL(10,2))) FROM dbo.Publishes pu JOIN dbo.Publication p ON pu.PublicationId=p.Id WHERE pu.ResearcherId=@ResearcherId);
    RETURN;
END;
GO
-- q37
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_ResearchProject_Status_StartDate' AND object_id=OBJECT_ID('dbo.ResearchProject'))
    CREATE NONCLUSTERED INDEX IX_ResearchProject_Status_StartDate ON dbo.ResearchProject(Status,StartDate);
GO
-- q38
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_Researcher_Email' AND object_id=OBJECT_ID('dbo.Researcher'))
    CREATE NONCLUSTERED INDEX IX_Researcher_Email ON dbo.Researcher(Email) INCLUDE(FirstName,LastName);
GO
-- q39
CREATE OR ALTER VIEW dbo.ActiveProjectSummary
AS
SELECT p.Id AS ProjectId,p.Title AS ProjectTitle,CONCAT(r.FirstName,' ',r.LastName) AS LeaderName,COUNT(DISTINCT w.ResearcherId) AS TeamMemberCount,COALESCE(SUM(w.HoursPerWeek),0) AS TotalWeeklyHours,p.Budget AS TotalBudget
FROM dbo.ResearchProject p
JOIN dbo.Researcher r ON p.LeaderId=r.Id
LEFT JOIN dbo.WorksOn w ON p.Id=w.ProjectId
WHERE p.Status='Active'
GROUP BY p.Id,p.Title,r.FirstName,r.LastName,p.Budget;
GO
-- q40
IF EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_ResearcherPublicationStats' AND object_id=OBJECT_ID('dbo.ResearcherPublicationStats'))
    DROP INDEX IX_ResearcherPublicationStats ON dbo.ResearcherPublicationStats;
GO
IF OBJECT_ID('dbo.ResearcherPublicationStats','V') IS NOT NULL
    DROP VIEW dbo.ResearcherPublicationStats;
GO
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
GO
CREATE VIEW dbo.ResearcherPublicationStats
WITH SCHEMABINDING
AS
SELECT r.Id AS ResearcherId,r.FirstName,r.LastName,COUNT_BIG(*) AS PublicationCount
FROM dbo.Researcher AS r
JOIN dbo.Publishes AS pu ON r.Id=pu.ResearcherId
GROUP BY r.Id,r.FirstName,r.LastName;
GO
CREATE UNIQUE CLUSTERED INDEX IX_ResearcherPublicationStats ON dbo.ResearcherPublicationStats(ResearcherId);
GO
-- q41
CREATE OR ALTER PROCEDURE dbo.AddResearcherToProject
    @ResearcherId VARCHAR(50),
    @ProjectId VARCHAR(50),
    @JoinDate DATE,
    @Role VARCHAR(100),
    @HoursPerWeek INT,
    @ContributionPercentage DECIMAL(5,2),
    @Result INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET @Result=-1;
    IF NOT EXISTS(SELECT 1 FROM dbo.Researcher WHERE Id=@ResearcherId)
        RETURN;
    IF NOT EXISTS(SELECT 1 FROM dbo.ResearchProject WHERE Id=@ProjectId)
        RETURN;
    IF EXISTS(SELECT 1 FROM dbo.WorksOn WHERE ResearcherId=@ResearcherId AND ProjectId=@ProjectId)
        RETURN;
    INSERT INTO dbo.WorksOn(ResearcherId,ProjectId,JoinDate,Role,HoursPerWeek,ContributionPercentage)
    VALUES(@ResearcherId,@ProjectId,@JoinDate,@Role,@HoursPerWeek,@ContributionPercentage);
    SET @Result=0;
END;
GO
-- q42
CREATE OR ALTER PROCEDURE dbo.UpdateProjectStatus
    @ProjectId VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS(SELECT 1 FROM dbo.ResearchProject WHERE Id=@ProjectId AND Status='Pending')
       AND EXISTS(SELECT 1 FROM dbo.WorksOn WHERE ProjectId=@ProjectId)
       AND EXISTS(SELECT 1 FROM dbo.Funds WHERE ProjectId=@ProjectId)
    BEGIN
        UPDATE dbo.ResearchProject SET Status='Active' WHERE Id=@ProjectId AND Status='Pending';
    END;
END;
GO
-- q43
CREATE OR ALTER PROCEDURE dbo.GetResearcherSummary
    @ResearcherId VARCHAR(50),
    @ProjectCount INT OUTPUT,
    @PublicationCount INT OUTPUT,
    @WeeklyHours INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @ProjectCount=COUNT(DISTINCT ProjectId),@WeeklyHours=COALESCE(SUM(HoursPerWeek),0)
    FROM dbo.WorksOn
    WHERE ResearcherId=@ResearcherId;
    SELECT @PublicationCount=COUNT(DISTINCT PublicationId)
    FROM dbo.Publishes
    WHERE ResearcherId=@ResearcherId;
END;
GO
-- q44
CREATE OR ALTER TRIGGER dbo.TR_WorksOn_MaxFiveProjects
ON dbo.WorksOn
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS
    (
        SELECT w.ResearcherId
        FROM dbo.WorksOn w
        JOIN (SELECT DISTINCT ResearcherId FROM inserted) i ON w.ResearcherId=i.ResearcherId
        GROUP BY w.ResearcherId
        HAVING COUNT(DISTINCT w.ProjectId)>5
    )
    BEGIN
        ROLLBACK TRANSACTION;
        THROW 50001,'A researcher cannot work on more than five projects.',1;
    END;
END;
GO
-- q45
CREATE OR ALTER TRIGGER dbo.TR_ResearchProject_AutoComplete
ON dbo.ResearchProject
AFTER INSERT,UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE p
    SET Status='Completed'
    FROM dbo.ResearchProject p
    JOIN inserted i ON p.Id=i.Id
    WHERE i.EndDate IS NOT NULL
      AND i.EndDate<CAST(GETDATE() AS DATE)
      AND p.Status<>'Completed';
END;
GO
-- q46
IF OBJECT_ID('dbo.GrantAudit','U') IS NULL
BEGIN
    CREATE TABLE dbo.GrantAudit
    (
        AuditId INT IDENTITY(1,1) PRIMARY KEY,
        GrantId VARCHAR(50) NOT NULL,
        OldAmount DECIMAL(18,2) NULL,
        NewAmount DECIMAL(18,2) NULL,
        ModifiedBy SYSNAME NOT NULL,
        ModifiedDate DATETIME2 NOT NULL
    );
END;
GO
CREATE OR ALTER TRIGGER dbo.TR_Grants_AuditUpdate
ON dbo.Grants
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO dbo.GrantAudit(GrantId,OldAmount,NewAmount,ModifiedBy,ModifiedDate)
    SELECT i.Id,d.Amount,i.Amount,SYSTEM_USER,SYSDATETIME()
    FROM inserted i
    JOIN deleted d ON i.Id=d.Id;
END;
GO
-- q47
BEGIN TRY
    BEGIN TRANSACTION;
    IF NOT EXISTS(SELECT 1 FROM dbo.ResearchProject WHERE Id='P_NEW')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM dbo.Researcher WHERE Id='R001')
            THROW 50002,'Researcher R001 does not exist.',1;
        IF NOT EXISTS(SELECT 1 FROM dbo.Grants WHERE Id='G001')
            THROW 50003,'Grant G001 does not exist.',1;
        INSERT INTO dbo.ResearchProject(Id,Title,StartDate,EndDate,Budget,Status,LeaderId)
        VALUES('P_NEW','New Research Project',CAST(GETDATE() AS DATE),NULL,50000,'Pending','R001');
    END;
    IF NOT EXISTS(SELECT 1 FROM dbo.WorksOn WHERE ResearcherId='R001' AND ProjectId='P_NEW')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM dbo.Researcher WHERE Id='R001')
            THROW 50002,'Researcher R001 does not exist.',1;
        INSERT INTO dbo.WorksOn(ResearcherId,ProjectId,JoinDate,Role,HoursPerWeek,ContributionPercentage)
        VALUES('R001','P_NEW',CAST(GETDATE() AS DATE),'Leader',10,100);
    END;
    IF NOT EXISTS(SELECT 1 FROM dbo.Funds WHERE GrantId='G001' AND ProjectId='P_NEW')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM dbo.Grants WHERE Id='G001')
            THROW 50003,'Grant G001 does not exist.',1;
        INSERT INTO dbo.Funds(GrantId,ProjectId,AllocationAmount,AllocationDate)
        VALUES('G001','P_NEW',50000,CAST(GETDATE() AS DATE));
    END;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT>0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
-- q48
IF DATABASE_PRINCIPAL_ID('ResearchManager') IS NULL
    CREATE USER ResearchManager WITHOUT LOGIN;
GO
GRANT CONTROL ON SCHEMA::dbo TO ResearchManager;
GO
-- q49
IF DATABASE_PRINCIPAL_ID('ResearchAssistant') IS NULL
    CREATE USER ResearchAssistant WITHOUT LOGIN;
GO
GRANT SELECT,INSERT ON dbo.Researcher TO ResearchAssistant;
GRANT SELECT,INSERT ON dbo.Publication TO ResearchAssistant;
GO
-- q50
IF DATABASE_PRINCIPAL_ID('DataAnalyst') IS NULL
    CREATE USER DataAnalyst WITHOUT LOGIN;
GO
GRANT SELECT ON dbo.ActiveProjectSummary TO DataAnalyst;
GRANT SELECT ON dbo.ResearcherPublicationStats TO DataAnalyst;
GO
-- q51
REVOKE INSERT,UPDATE ON dbo.Researcher FROM ResearchAssistant;
GO
-- q52
SELECT r.Id,r.FirstName,r.LastName
FROM dbo.Researcher r
WHERE r.Id IN(SELECT w.ResearcherId FROM dbo.WorksOn w WHERE w.ProjectId='P001');
GO
SELECT r.Id,r.FirstName,r.LastName
FROM dbo.Researcher r
WHERE EXISTS(SELECT 1 FROM dbo.WorksOn w WHERE w.ResearcherId=r.Id AND w.ProjectId='P001');
GO
-- q53
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_ResearchProject_Status_StartDateDesc' AND object_id=OBJECT_ID('dbo.ResearchProject'))
    CREATE NONCLUSTERED INDEX IX_ResearchProject_Status_StartDateDesc ON dbo.ResearchProject(Status,StartDate DESC) INCLUDE(Id,Title,LeaderId);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_WorksOn_ProjectId' AND object_id=OBJECT_ID('dbo.WorksOn'))
    CREATE NONCLUSTERED INDEX IX_WorksOn_ProjectId ON dbo.WorksOn(ProjectId) INCLUDE(ResearcherId,HoursPerWeek);
GO
IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='IX_WorksOn_ResearcherId' AND object_id=OBJECT_ID('dbo.WorksOn'))
    CREATE NONCLUSTERED INDEX IX_WorksOn_ResearcherId ON dbo.WorksOn(ResearcherId) INCLUDE(ProjectId,HoursPerWeek);
GO
SELECT p.Id AS ProjectId,p.Title,r.Id AS ResearcherId,r.FirstName,r.LastName
FROM dbo.ResearchProject p
JOIN dbo.WorksOn w ON p.Id=w.ProjectId
JOIN dbo.Researcher r ON w.ResearcherId=r.Id
WHERE p.Status='Active'
ORDER BY p.StartDate DESC;
GO
-- q54
CREATE OR ALTER PROCEDURE dbo.GetTop10Publications
AS
BEGIN
    SET NOCOUNT ON;
    WITH TopPublications AS
    (
        SELECT TOP 10 WITH TIES Id,Title,CitationCount
        FROM dbo.Publication
        ORDER BY CitationCount DESC
    )
    SELECT tp.Id AS PublicationId,tp.Title,tp.CitationCount,pa.AuthorName
    FROM TopPublications tp
    LEFT JOIN dbo.PublicationAuthor pa ON tp.Id=pa.PublicationId
    ORDER BY tp.CitationCount DESC,tp.Id,pa.AuthorName;
END;
GO