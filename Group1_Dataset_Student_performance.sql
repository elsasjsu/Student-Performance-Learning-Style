CREATE DATABASE group1_dataset;
USE group1_dataset;
CREATE TABLE student_performance (
    Student_ID VARCHAR(10) PRIMARY KEY,
    Age INT,
    Gender VARCHAR(10),
    Study_Hours_per_Week INT,
    Preferred_Learning_Style VARCHAR(50),
    Online_Courses_Completed INT,
    Participation_in_Discussions VARCHAR(5),
    Assignment_Completion_Rate INT,
    Exam_Score INT,
    Attendance_Rate INT,
    Use_of_Educational_Tech VARCHAR(5),
    Self_Reported_Stress_Level VARCHAR(10),
    Time_Spent_on_Social_Media INT,
    Sleep_Hours_per_Night INT,
    Final_Grade CHAR(1)
);

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/Users/hp/Downloads/archive/student_performance_large_dataset.csv'
INTO TABLE student_performance
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    Student_ID,
    Age,
    Gender,
    Study_Hours_per_Week,
    Preferred_Learning_Style,
    Online_Courses_Completed,
    Participation_in_Discussions,
    Assignment_Completion_Rate,
    Exam_Score,
    Attendance_Rate,
    Use_of_Educational_Tech,
    Self_Reported_Stress_Level,
    Time_Spent_on_Social_Media,
    Sleep_Hours_per_Night,
    Final_Grade
);
##Which learning styles are most common among high-performing students?##
SELECT Preferred_Learning_Style,
COUNT(*) AS Student_Count
FROM student_performance
WHERE Final_Grade = 'A'
GROUP BY Preferred_Learning_Style
ORDER BY Student_Count DESC;

##Trigger to alert high score##

DELIMITER $$

CREATE TRIGGER alert_high_scorer
AFTER INSERT ON student_performance
FOR EACH ROW
BEGIN
  IF NEW.Exam_Score >= 85 THEN
    INSERT INTO alerts (student_id, message, created_at)
    VALUES (NEW.Student_ID, 'New high-performing student identified', CURRENT_TIMESTAMP);
  END IF;
END$$

DELIMITER ;


#Business Question 
#1. Do certain learning styles correlate with higher scores in specific subjects?##

SELECT Preferred_Learning_Style,
AVG(Exam_Score) AS Average_Exam_Score,
COUNT(*) AS Student_Count
FROM student_performance
GROUP BY Preferred_Learning_Style
ORDER BY Average_Exam_Score DESC;

##Business Question
#6. Which students are consistently underperforming across subjects?##

SELECT Student_ID,
Exam_Score, Assignment_Completion_Rate,
Attendance_Rate, Final_Grade
FROM student_performance
WHERE Exam_Score < 50 AND
Assignment_Completion_Rate < 60 AND
Attendance_Rate < 60;

##6.Trigger to Alerting underperforming students##

DELIMITER $$
CREATE TRIGGER alert_underperformer
AFTER INSERT ON student_performance
FOR EACH ROW
BEGIN
  IF NEW.Exam_Score < 50 
     AND NEW.Assignment_Completion_Rate < 60 
     AND NEW.Attendance_Rate < 60 THEN
     
    INSERT INTO alerts (student_id, message, created_at)
    VALUES (
        NEW.Student_ID, 
        'Underperforming student identified. Consider intervention.', 
        CURRENT_TIMESTAMP
    );
  END IF;
END$$

DELIMITER ;

###Business Question
#2. Do students who study more hours per week tend to have higher GPAs?##

SELECT Study_Hours_per_Week, 
Final_Grade
FROM student_performance;
    

##3. Can we automate assigning remarks like 'Excellent', 'Needs Improvement', etc.? 

DELIMITER $$
CREATE PROCEDURE assign_remarks()
BEGIN
  UPDATE student_performance
  SET remark = CASE Final_Grade
    WHEN 'A' THEN 'Excellent'
    WHEN 'B' THEN 'Excellent'
    WHEN 'C' THEN 'Average'
    WHEN 'D' THEN 'Needs Improvement'
    ELSE 'Needs Improvement'
  END;
END$$
DELIMITER ;

##10. Participation by age group or learning style##

SELECT 
  Preferred_Learning_Style AS learning_style,
  age_group,
  COUNT(*) AS total_students,
  SUM(CASE WHEN Participation_in_Discussions = 'Yes' THEN 1 ELSE 0 END) AS total_participation
FROM (
  SELECT *, 
         CASE 
           WHEN Age < 20 THEN 'Under 20'
           WHEN Age BETWEEN 20 AND 24 THEN '20-24'
           ELSE '25+'
         END AS age_group
  FROM student_performance
) AS sub
GROUP BY Preferred_Learning_Style, age_group
ORDER BY total_participation DESC;

###9.error Log GPA changes (audit trigger)
CREATE TABLE gpa_audit_log (
  audit_id INT AUTO_INCREMENT PRIMARY KEY,
  student_id INT,
  old_gpa DECIMAL(3,2),
  new_gpa DECIMAL(3,2),
  change_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //
CREATE TRIGGER log_gpa_update
BEFORE UPDATE ON student_profile
FOR EACH ROW
BEGIN
  IF OLD.GPA <> NEW.GPA THEN
    INSERT INTO gpa_audit_log(student_id, old_gpa, new_gpa)
    VALUES(OLD.student_id, OLD.GPA, NEW.GPA);
  END IF;
END;
//
DELIMITER ;



DELIMITER //

CREATE TRIGGER log_gpa_update
BEFORE UPDATE ON student_performance
FOR EACH ROW
BEGIN
  IF OLD.GPA <> NEW.GPA THEN
    INSERT INTO gpa_audit_log(student_id, old_gpa, new_gpa)
    VALUES (OLD.Student_ID, OLD.GPA, NEW.GPA);
  END IF;
END;
//

DELIMITER ;

##Business Question
#8. Prevent duplicate student entries

SELECT Student_ID, 
COUNT(*) AS duplicate_count
FROM student_performance
GROUP BY Student_ID
HAVING COUNT(*) > 1;
  
  ###Business Question
  #7. Can social media and stress predict performance?##
  
 SELECT
  CASE Self_Reported_Stress_Level
    WHEN 'Low' THEN 1
    WHEN 'Medium' THEN 2
    WHEN 'High' THEN 3
  END AS stress_score,
  Time_Spent_on_Social_Media AS social_hours,
  Exam_Score AS test_score
FROM student_performance
LIMIT 1000;



###error 5. Clustering to find study styles (run externally, but SQL prep here)
SELECT 
  Study_Hours_per_Week AS hours_studied_per_week,
  Self_Reported_Stress_Level AS stress_level,
  Time_Spent_on_Social_Media_hours AS social_media_hours,
  Exam_Score AS GPA
FROM 
  student_performance
LIMIT 1000;
#4. Monitor preferred learning styles course-wise to see failure trends
SELECT 
  Online_Courses_Completed,
  Preferred_Learning_Style AS learning_style,
  COUNT(*) AS total_students,
  SUM(CASE 
        WHEN GPA < 2.0 THEN 1 
        ELSE 0 
      END) AS failures
FROM 
  student_performance
GROUP BY 
  Online_Courses_Completed, Preferred_Learning_Style
ORDER BY 
  Online_Courses_Completed, failures DESC
LIMIT 1000;
  
  select * from student_performance;
DESCRIBE student_performance;

##Business Question
#4.Does assignment completion rate correlate with higher exam performance?

SELECT 
  ROUND(Assignment_Completion_Rate / 10) * 10 AS Assignment_Bracket,
  AVG(Exam_Score) AS Avg_Exam_Score,
  COUNT(*) AS Student_Count
FROM student_performance
WHERE Assignment_Completion_Rate IS NOT NULL
  AND Exam_Score IS NOT NULL
GROUP BY Assignment_Bracket
ORDER BY Assignment_Bracket
  
  #Business Question
  #5.Does the number of study hours per week affect participation in academic discussions?
  
SELECT 
  FLOOR(Study_Hours_per_Week / 5) * 5 AS Study_Hour_Group,
  COUNT(*) AS Total_Students,
  SUM(CASE WHEN Participation_in_Discussions = 'Yes' THEN 1 ELSE 0 END) AS Participants,
  ROUND(100.0 * SUM(CASE WHEN Participation_in_Discussions = 'Yes' THEN 1 ELSE 0 END) / 
  COUNT(*), 2) AS Participation_Rate
FROM student_performance
WHERE Study_Hours_per_Week IS NOT NULL
GROUP BY Study_Hour_Group
ORDER BY Study_Hour_Group;

#Business Question
#Is there a correlation between the number of study hours per week and
# students' overall academic performance?

SELECT 
    Study_Hours_per_Week AS study_hours_per_week,
    AVG(Exam_Score) AS average_score,
    COUNT(*) AS student_count
FROM student_performance
WHERE Study_Hours_per_Week IS NOT NULL
GROUP BY Study_Hours_per_Week
ORDER BY Study_Hours_per_Week;

##Business Question
#Does attendance rate influence student performance?
 #(Are students with high attendance scoring better?)
SELECT 
  CASE 
    WHEN Attendance_Rate >= 90 THEN 'Excellent (90-100%)'
    WHEN Attendance_Rate >= 75 THEN 'Good (75-89%)'
    WHEN Attendance_Rate >= 60 THEN 'Fair (60-74%)'
    ELSE 'Poor (<60%)'
  END AS attendance_category,
  AVG(Exam_Score) AS average_score,
  COUNT(*) AS student_count
FROM student_performance
WHERE Attendance_Rate IS NOT NULL
GROUP BY attendance_category
ORDER BY average_score DESC;
