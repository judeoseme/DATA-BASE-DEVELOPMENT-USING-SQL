--- Create the database

CREATE DATABASE PrescriptionsDB;

USE PrescriptionsDB;
GO

-- -- add primary key constraint to Medical_Practice table
ALTER TABLE Medical_Practice
ADD CONSTRAINT PK_Medical_Practice PRIMARY KEY (practice_code);

-- add primary key constraint to Drugs table
ALTER TABLE Drugs
ADD CONSTRAINT PK_Drugs PRIMARY KEY (BNF_CODE);

-- add primary key constraint to Prescriptions table
ALTER TABLE Prescriptions
ADD CONSTRAINT PK_Prescriptions PRIMARY KEY (PRESCRIPTION_CODE);

-- add foreign key constraint for PRACTICE_CODE
ALTER TABLE Prescriptions
ADD CONSTRAINT FK_Prescriptions_Medical_Practice
FOREIGN KEY (PRACTICE_CODE) REFERENCES Medical_Practice(practice_code);

--- add foreign key constraint for BNF_CODE
ALTER TABLE Prescriptions
ADD CONSTRAINT FK_Prescriptions_Drugs
FOREIGN KEY (BNF_CODE) REFERENCES Drugs(BNF_CODE);

--- PART 2
--- Write a query that returns details of all drugs which are in the form of tablets or capsules.

SELECT *
FROM Drugs
WHERE BNF_DESCRIPTION LIKE '%tablet%'
   OR BNF_DESCRIPTION LIKE '%capsule%';

--- PART 3
--- Write a query that returns the total quantity for each of prescriptions 
SELECT PRESCRIPTION_CODE, CAST(ROUND(SUM(CAST(QUANTITY AS FLOAT) * CAST(ITEMS AS FLOAT)), 0) AS INT) AS total_quantity
FROM Prescriptions
GROUP BY PRESCRIPTION_CODE;

--- PART 4
--- Write a query that returns a list of the distinct chemical substances which appear in the Drugs table
SELECT DISTINCT CHEMICAL_SUBSTANCE_BNF_DESCR
FROM Drugs;

--- PART 5
--- Write a query that returns the number of prescriptions for eachBNF_CHAPTER_PLUS_CODE, along with the average cost for that chapter code, and theminimum and maximum prescription costs for that chapter code
SELECT d.BNF_CHAPTER_PLUS_CODE, 
       COUNT(p.PRESCRIPTION_CODE) AS num_prescriptions, 
       AVG(p.ACTUAL_COST) AS avg_cost, 
       MIN(p.ACTUAL_COST) AS min_cost, 
       MAX(p.ACTUAL_COST) AS max_cost
FROM Prescriptions p
INNER JOIN Drugs d ON p.BNF_CODE = d.BNF_CODE
GROUP BY d.BNF_CHAPTER_PLUS_CODE;

--- PART 6
--- Write a query that returns the most expensive prescription prescribed by each practice, 
--- sorted in descending order by prescription cost (the ACTUAL_COST column in the prescription table.) 
--- Return only those rows where the most expensive prescriptionis more than £4000. 
---You should include the practice name in your result

SELECT medical_practice.practice_name, MAX(Prescriptions.ACTUAL_COST) AS max_cost
FROM Prescriptions
INNER JOIN medical_practice ON Prescriptions.PRACTICE_CODE = medical_practice.practice_code
GROUP BY medical_practice.practice_name
HAVING MAX(Prescriptions.ACTUAL_COST) > 4000
ORDER BY max_cost DESC;

--- PART 7
--- Five additional Queries
--- 1. 
--- Query to find the average cost of prescriptions for each BNF chapter:
SELECT Drugs.BNF_CHAPTER_PLUS_CODE, AVG(Prescriptions.ACTUAL_COST) AS avg_cost
FROM Drugs
INNER JOIN Prescriptions ON Drugs.BNF_CODE = Prescriptions.BNF_CODE
GROUP BY Drugs.BNF_CHAPTER_PLUS_CODE
ORDER BY avg_cost DESC;

--- 2.
---Query to find all drugs that have been prescribed by a specific practice:
SELECT DISTINCT Drugs.BNF_DESCRIPTION
FROM Drugs
INNER JOIN Prescriptions ON Drugs.BNF_CODE = Prescriptions.BNF_CODE
WHERE Prescriptions.PRACTICE_CODE IN (
  SELECT medical_practice.practice_code
  FROM medical_practice
  WHERE medical_practice.practice_name = 'BOLTON COMMUNITY PRACTICE'
);


--- 3.
--- Query using the ROUND function to round a numerical column to a specific number of decimal places:
SELECT BNF_DESCRIPTION, ROUND(AVG(actual_cost), 2) AS avg_cost
FROM prescriptions
INNER JOIN drugs ON prescriptions.bnf_code = drugs.bnf_code
GROUP BY BNF_DESCRIPTION
ORDER BY avg_cost DESC;

--- 4.
--- Return the names of all medical practices in Bolton that have not prescribed any drug in the "06: Endocrine system" BNF chapter code
SELECT practice_name
FROM medical_practice
WHERE NOT EXISTS (
  SELECT *
  FROM prescriptions
  INNER JOIN drugs ON prescriptions.BNF_CODE = drugs.BNF_CODE
  WHERE prescriptions.PRACTICE_CODE = medical_practice.PRACTICE_CODE
    AND drugs.BNF_CHAPTER_PLUS_CODE = '06'
)

--- 5.
--- Query to get the average cost of prescriptions for each medical practice in the Medical_Practice table, ordered by the average cost in ascending order:
SELECT 
    practice_name, 
    AVG(ACTUAL_COST) AS avg_cost
FROM 
    Medical_Practice 
    JOIN Prescriptions ON Medical_Practice.practice_code = Prescriptions.practice_code
GROUP BY 
    practice_name 
HAVING 
    AVG(ACTUAL_COST) < 10
ORDER BY 
    avg_cost ASC;


