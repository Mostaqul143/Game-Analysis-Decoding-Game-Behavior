-- Rename table level_details2 to ld
ALTER TABLE level_details2 RENAME TO ld;

-- Drop the column 'myunknowncolumn' from the ld table
ALTER TABLE ld DROP COLUMN myunknowncolumn;

-- Change the data type of 'timestamp' column to datetime and rename it to 'start_datetime'
ALTER TABLE ld CHANGE COLUMN timestamp start_datetime DATETIME;

-- Modify the data type of 'Dev_Id' column to varchar(10)
ALTER TABLE ld MODIFY COLUMN Dev_Id VARCHAR(10);

-- Modify the data type of 'Difficulty' column to varchar(15)
ALTER TABLE ld MODIFY COLUMN Difficulty VARCHAR(15);

-- Add a composite primary key consisting of P_ID, Dev_id, and start_datetime columns to the ld table
ALTER TABLE ld ADD PRIMARY KEY(P_ID, Dev_id, start_datetime);



-- Rename table player_details to pd
ALTER TABLE player_details RENAME TO pd;

-- Drop the column 'myunknowncolumn' from the pd table
ALTER TABLE pd DROP COLUMN myunknowncolumn;

-- Modify the data type of 'L1_Status' column to varchar(30)
ALTER TABLE pd MODIFY COLUMN L1_Status VARCHAR(30);

-- Modify the data type of 'L2_Status' column to varchar(30)
ALTER TABLE pd MODIFY COLUMN L2_Status VARCHAR(30);

-- Modify the data type of 'P_ID' column to int and add it as the primary key
ALTER TABLE pd MODIFY COLUMN P_ID INT PRIMARY KEY;


-- -------------------------------------------------------- QUESTIONS & SOLUTIONS --------------------------------------------------------



-- Q1) Extract P_ID, Dev_ID, PName, and Difficulty_level of all players at level 0

SELECT 
    ld.P_ID, 
    ld.Dev_ID, 
    pd.PName, 
    ld.Difficulty
FROM 
    ld
JOIN 
    pd ON ld.P_ID = pd.P_ID
WHERE 
    ld.Level = 0;
    
    

-- Q2) Find Level1_code wise Avg_Kill_Count where lives_earned is 2 and at least 3 stages are crossed

SELECT 
    pd.L1_Code, 
    ROUND(AVG(ld.Kill_count), 2) AS Avg_Kill
FROM 
    ld
JOIN 
    pd ON ld.P_ID = pd.P_ID
WHERE 
    ld.lives_earned = 2
    AND ld.Stages_crossed >= 3
GROUP BY 
    pd.L1_Code;
    
    

-- Q3) Find the total number of stages crossed at each difficulty level where for Level2 with players use zm_series devices. Arrange the result in decreasing order of the total number of stages crossed.

SELECT 
    ld.Difficulty,
    COUNT(ld.Stages_crossed) AS Total_Stages_Crossed
FROM 
    ld
JOIN 
    pd ON ld.P_ID = pd.P_ID
WHERE 
    ld.Level = 2 
    AND ld.Dev_ID LIKE 'zm_%'
GROUP BY 
    ld.Difficulty
ORDER BY 
    Total_Stages_Crossed DESC;
    
    
-- Q4) Extract P_ID and the total number of unique dates for those players who have played games on multiple days.

SELECT 
    ld.P_ID,
    COUNT(DISTINCT ld.start_datetime) AS Total_Unique_Dates
FROM 
    ld
GROUP BY 
    ld.P_ID
HAVING 
    Total_Unique_Dates > 1
ORDER BY 
    Total_Unique_Dates DESC;
    
    

-- Q5) Find P_ID and level-wise sum of kill_counts where kill_count is greater than the average kill count for the Medium difficulty.

SELECT 
    ld.P_ID, 
    ld.Level, 
    SUM(ld.kill_Count) AS Total
FROM 
    ld
WHERE 
    ld.kill_Count > (
        SELECT AVG(ld.kill_Count)
        FROM ld
        WHERE ld.Difficulty = 'Medium'
    )
GROUP BY 
    ld.P_ID, ld.Level
ORDER BY 
    ld.Level;
    
    

-- Q6) Find Level and its corresponding Level code wise sum of lives earned excluding level 0. Arrange in ascending order of the level.

SELECT 
    ld.Level,
    CASE
        WHEN ld.level = 1 THEN pd.l1_code
        WHEN ld.level = 2 THEN pd.l2_code
        ELSE NULL
    END AS Level_Code,
    SUM(ld.Lives_Earned) AS Total_Lives_Earned
FROM 
    ld
JOIN 
    pd ON ld.P_ID = pd.P_ID
WHERE 
    ld.Level > 0
GROUP BY 
    ld.Level, Level_Code
ORDER BY 
    ld.Level;



-- Q7) Find Top 3 scores based on each dev_id and rank them in increasing order using Row_Number. Display difficulty as well.

SELECT 
    dev_id, 
    score, 
    difficulty, 
    rn
FROM (
    SELECT 
        ld.Dev_ID, 
        ld.Score, 
        ld.Difficulty, 
        ROW_NUMBER() OVER (PARTITION BY ld.dev_id ORDER BY ld.score DESC) AS rn
    FROM 
        ld
) AS t
WHERE 
    rn <= 3;



-- Q8) Find the first_login datetime for each device id

SELECT 
    ld.Dev_ID, 
    MIN(ld.start_datetime) AS First_Login
FROM 
    ld
GROUP BY 
    ld.Dev_ID
ORDER BY 
    First_Login;



-- Q9) Find the Top 5 scores based on each difficulty level and rank them in increasing order using Rank. Display dev_id as well.

SELECT 
    Difficulty, 
    score, 
    dev_id, 
    rn
FROM (
    SELECT 
        ld.Difficulty, 
        ld.Score, 
        ld.Dev_ID, 
        RANK() OVER (PARTITION BY ld.Difficulty ORDER BY ld.Score DESC) AS rn
    FROM 
        ld
) AS t
WHERE 
    rn <= 5
ORDER BY 
    Difficulty, rn;



-- Q10) Find the device ID that is first logged in (based on start_datetime) for each player(p_id). 
-- Output should contain player id, device id, and first login datetime.

SELECT 
    ld.P_ID, 
    ld.Dev_ID, 
    MIN(ld.start_datetime) AS First_Login
FROM 
    ld
GROUP BY 
    ld.P_ID, ld.Dev_ID;
    
    

-- Q11) For each player and date, determine how many `kill_counts` were played by the player so far.

-- a) Using window functions

SELECT 
    ld.P_ID, 
    ld.start_datetime, 
    SUM(ld.Kill_Count) OVER (PARTITION BY ld.p_id ORDER BY ld.start_datetime) AS total_kills_so_far
FROM 
    ld;
    
    
    
-- b) Without window functions

SELECT 
    ld1.P_ID,
    ld1.start_datetime,
    SUM(ld1.Kill_Count) AS total_kills_so_far
FROM
    ld ld1
        JOIN
    ld ld2 ON ld1.P_ID = ld2.P_ID
        AND ld1.start_datetime >= ld2.start_datetime
GROUP BY ld1.P_ID , ld1.start_datetime



-- Q12) Find the cumulative sum of stages crossed over `start_datetime` for each `P_ID`, excluding the most recent `start_datetime`.

SELECT
    ld.P_ID,
    ld.start_datetime,
    ld.Stages_crossed,
    SUM(ld.Stages_crossed) OVER (
        PARTITION BY ld.p_id
        ORDER BY ld.start_datetime
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ) AS cumulative_sum
FROM
    ld;
    
    
-- Q13) Extract the top 3 highest sums of scores for each `Dev_ID` and the corresponding `P_ID`.

SELECT 
    dev_id, 
    p_id, 
    total, 
    rn
FROM (
    SELECT 
        ld.Dev_ID, 
        ld.P_ID, 
        SUM(ld.Score) AS Total,
        RANK() OVER (PARTITION BY ld.Dev_ID ORDER BY SUM(ld.Score) DESC) AS rn
    FROM 
        ld
    GROUP BY 
        ld.Dev_ID, ld.P_ID
) AS t
WHERE 
    rn <= 3;
    
    
    
-- Q14) Find players who scored more than 50% of the average score scored by the sum of scores for each player_id

SELECT 
    P_ID, 
    SUM(Score) AS Total_Score
FROM 
    ld
GROUP BY 
    P_ID
HAVING 
    SUM(Score) > (
        SELECT 0.5 * AVG(Score)
        FROM ld
    )
ORDER BY 
    Total_Score DESC;
    
    

-- Q15) Create a stored procedure to find top n headshots_count based on each dev_id and rank them in increasing order using Row_Number. Display difficulty as well.

DELIMITER $$
CREATE PROCEDURE Top_N_Headshots(
    IN n INT
)
BEGIN
    SELECT 
        dev_id, 
        headshots_count, 
        difficulty, 
        ranking
    FROM (
        SELECT 
            dev_id, 
            headshots_count, 
            difficulty, 
            ROW_NUMBER() OVER (PARTITION BY dev_id ORDER BY headshots_count DESC) AS ranking
        FROM 
            ld
    ) AS ranked
    WHERE 
        ranking <= n;
END$$
DELIMITER ;

-- Call the stored procedure Top_N_Headshots to retrieve the top N headshots count based on each dev_id
-- The parameter '3' specifies that the top 3 headshots counts will be returned for each dev_id

CALL Top_N_Headshots(3);



-- Q16) Create a function to return the sum of Score for a given player_id.

DELIMITER $$
CREATE FUNCTION Total_Score(
    playerId INT
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE totalScore INT;
    
    SELECT 
        SUM(Score) INTO totalScore
    FROM 
        ld
    WHERE 
        P_ID = playerId;
    
    RETURN totalScore;
END$$
DELIMITER ;


-- Call the Total_Score function to calculate the total score for the player with ID 683

SELECT Total_Score(683);


    
    
    









    