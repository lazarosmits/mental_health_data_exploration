
------------------------------------------------------------------------
------------------- GLOBAL MENTAL HEALTH DATA EXPLORATION---------------
------------------------------------------------------------------------

--The following code contains SQL queries aimed to explore data from 2 tables: 
--                              a) Mental Illnesses Prevalence
--                              b) DALY rates representing burden from each mental illess

-- After initial inspections, I take closer looks at the data from specific countries. 
-- Then, I calculate some descriptive statistics, and I compare data from the 2 tables
-- as well as data across countries

----------------------Prevalence of mental illneses--------------------

--Inspect the entire table for prevalence of mental illnesses
SELECT *
FROM mental_health_project.dbo.[mental-illnesses-prevalence]


--validate prevalence data by counting number of rows per country (years measurements are taken)
SELECT
    Entity AS Country,
    COUNT(Entity) AS [Number of Measurements]
FROM mental_health_project.dbo.[mental-illnesses-prevalence]
GROUP BY Entity
ORDER BY Entity;


-- Let's have a look at prevalence data taken from the UK
SELECT *
FROM mental_health_project.dbo.[mental-illnesses-prevalence]
WHERE Entity = 'United Kingdom'


-- Depressive disorders are increasingly the subject of news stories 
-- So let's have a more focused look on prevalence of Depressive disorders for a few countries

--Starting with some southern Europe countries
SELECT Entity AS Countries, Depressive_disorders
from mental_health_project.dbo.[mental-illnesses-prevalence]
WHERE Entity IN ('Greece', 'Italy', 'Spain', 'Cyprus', 'Portugal', 'Croatia')

-- and then some countries from northern Europe
SELECT Entity AS Countries, Depressive_disorders
from mental_health_project.dbo.[mental-illnesses-prevalence]
WHERE Entity IN ('United Kingdom', 'France', 'Germany', 'Denmark', 'Netherlands', 'Sweden','Norway')

-- Suppose we want to get a compehensive view of prevalence data for Northern Europe countries
-- Let's calculate some decsriptive statistics
SELECT
    Entity AS Countries,
    AVG(Depressive_disorders) AS [Depressive Disorders prevalence: Average],
	STDEV(Depressive_disorders) AS [Depressive Disorders prevalence: Standard Deviation],
	MIN(Depressive_disorders) AS [Depressive Disorders prevalence: Minimum],
	MAX(Depressive_disorders) AS [Depressive Disorders prevalence: Maximum]
FROM mental_health_project.dbo.[mental-illnesses-prevalence]
WHERE Entity IN ('United Kingdom', 'France', 'Germany', 'Denmark', 'Netherlands', 'Sweden','Norway')
GROUP BY Entity
ORDER BY Entity DESC


-- Now let's do some cross regional comparisons. 
-- Descriptive statistics for Depressive disorders for Northern Europe against Southern Europe
SELECT
    CASE
        WHEN Entity IN ('United Kingdom', 'France', 'Germany', 'Denmark', 'Netherlands', 'Sweden','Norway')
			THEN 'Northern Europe'
        WHEN Entity IN ('Greece', 'Italy', 'Spain', 'Cyprus', 'Portugal', 'Croatia') THEN 'Southern Europe'
		ELSE 'Other'
    END AS Region,
    AVG(Depressive_disorders) AS [Depressive Disorders prevalence: Average],
	STDEV(Depressive_disorders) AS [Depressive Disorders prevalence: Standard Deviation],
	MIN(Depressive_disorders) AS [Depressive Disorders prevalence: Minimum],
	MAX(Depressive_disorders) AS [Depressive Disorders prevalence: Maximum]
FROM
    mental_health_project.dbo.[mental-illnesses-prevalence]
GROUP BY
    CASE
        WHEN Entity IN ('United Kingdom', 'France', 'Germany', 'Denmark', 'Netherlands', 'Sweden','Norway')
			THEN 'Northern Europe'
        WHEN Entity IN ('Greece', 'Italy', 'Spain', 'Cyprus', 'Portugal', 'Croatia') THEN 'Southern Europe'
		ELSE 'Other'
    END;

-- The above descriptive statistics are good for providing a sense of general trends in the data.
-- However, since measurements have been taken from 1990 to 2019, it is good to ask: How did the 
-- prevalence of Depressive disorders change throughout the years?

-- Let's create a Common table expression (CTE) to calculate yearly differences in prevalence
WITH YearlyDifferences AS (
    SELECT
        Entity,
        [Year],
        Depressive_disorders,
        LEAD(Depressive_disorders) OVER (PARTITION BY Entity ORDER BY Year) AS NextYearPrevalence
		-- and use window functions to specify a set of rows for the aggregation
    FROM
        mental_health_project.dbo.[mental-illnesses-prevalence]
)
-- with that defined, now let's take the sum of these yearly differences
SELECT
    Entity,
    SUM(NextYearPrevalence - Depressive_disorders) AS SumYearlyDifference
FROM
    YearlyDifferences
WHERE
	Entity IN ('United Kingdom', 'France', 'Germany', 'Denmark', 'Netherlands', 'Sweden','Norway')
    And NextYearPrevalence IS NOT NULL -- Exclude the last year since it has no next year to compare
GROUP BY Entity
ORDER BY Entity DESC


----------------------DALY burden from mental illnesses--------------------

-- now let's inspect the DALY rate table that represents burden from mental illnesses
SELECT *
from mental_health_project.dbo.[burden-disease-from-each-mental-illness]

--validate number of rows per country (years measurements are taken)
SELECT Entity AS Countries, count(entity) AS [Number of measurements]
from mental_health_project.dbo.[burden-disease-from-each-mental-illness]
group by entity
order by Entity asc

-- Let's look at Descriptive statistics of DALY rates for northern European countries
SELECT
    Entity AS Countries,
    AVG(DALYs_rate_Depressive_disorders) AS [Depressive Disorders DALY rate: Average],
	STDEV(DALYs_rate_Depressive_disorders) AS [Depressive Disorders DALY rate: Standard Deviation],
	MIN(DALYs_rate_Depressive_disorders) AS [Depressive Disorders DALY rate: Minimum],
	MAX(DALYs_rate_Depressive_disorders) AS [Depressive Disorders DALY rate: Maximum]
FROM
    mental_health_project.dbo.[burden-disease-from-each-mental-illness]
WHERE
    Entity IN ('United Kingdom', 'France', 'Germany', 'Denmark', 'Netherlands', 'Sweden','Norway')
GROUP BY Entity
order by Entity desc

-- Now let's shift our focus on the UK again and compare the data from the two tables
-- in order to get a sense of how prevalence and DALY rates are related and maybe 
-- discover similar trends.

-- To do that we have to join the 2 tables for data in the UK
SELECT
    p.[Year] AS [Year],
    p.Depressive_disorders AS UK_Prevalence_Depressive_Disorders,
    d.DALYs_rate_Depressive_disorders AS UK_DALY_Depressive_Disorders
FROM
    mental_health_project.dbo.[mental-illnesses-prevalence] p
INNER JOIN
    mental_health_project.dbo.[burden-disease-from-each-mental-illness] d
    ON p.[Year] = d.[Year] -- Matching rows by year
WHERE
    p.Entity = 'United Kingdom'
    AND d.Entity = 'United Kingdom'

-- The data from these tables are on different scales but they might exhibit a correlation
-- There might also be seasonal trends across decades

WITH DecadeData AS (
    SELECT
        p.[Year],
        p.Depressive_disorders AS Prevalence,
        d.DALYs_rate_Depressive_disorders AS DALY,
        (p.[Year] / 10) * 10 AS Decade
    FROM
        mental_health_project.dbo.[mental-illnesses-prevalence] p
    INNER JOIN
        mental_health_project.dbo.[burden-disease-from-each-mental-illness] d
        ON p.[Year] = d.[Year] AND p.Entity = d.Entity
    WHERE
        p.Entity = 'United Kingdom'
        AND d.Entity = 'United Kingdom'
)

SELECT
    Decade,
    AVG(Prevalence) AS Depressive_Disorders_Avg_Prevalence_UK,
    AVG(DALY) AS Depressive_Disorders_Avg_DALY_UK
FROM
    DecadeData
GROUP BY
    Decade
ORDER BY
    Decade;



