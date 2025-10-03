-- ----------------------------------------------------------------------------
-- SQL script for Task 8 -- MySQL version
-- Save as: sql/scripts.sql
-- ----------------------------------------------------------------------------

-- Create database
DROP DATABASE IF EXISTS internship_task8;
CREATE DATABASE internship_task8;
USE internship_task8;

-- Create table: employees
DROP TABLE IF EXISTS employees;
CREATE TABLE employees (
  emp_id INT AUTO_INCREMENT PRIMARY KEY,
  full_name VARCHAR(100) NOT NULL,
  dept VARCHAR(64) NOT NULL,
  salary DECIMAL(10,2) NOT NULL,
  join_date DATE NOT NULL
);

-- Insert sample data
INSERT INTO employees (full_name, dept, salary, join_date) VALUES
('Asha Patel', 'Engineering', 65000.00, '2019-06-10'),
('Rohan Singh', 'Engineering', 72000.00, '2021-03-05'),
('Meera Sharma', 'HR', 52000.00, '2018-01-20'),
('Saurav Kumar', 'Sales', 48000.00, '2022-09-01'),
('Priya Verma', 'Engineering', 80000.00, '2015-12-15');

-- ============================================================================
-- FUNCTIONS
-- ============================================================================
-- Function: years_with_company(emp_id) -> returns number of full years since join_date
DELIMITER $$
CREATE FUNCTION years_with_company(p_emp_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE v_join DATE;
  DECLARE v_years INT;
  SELECT join_date INTO v_join FROM employees WHERE emp_id = p_emp_id;
  IF v_join IS NULL THEN
    RETURN NULL; -- employee not found
  END IF;
  SET v_years = TIMESTAMPDIFF(YEAR, v_join, CURDATE());
  RETURN v_years;
END$$
DELIMITER ;

-- Function: calculate_bonus(emp_id) -> simple bonus rule
DELIMITER $$
CREATE FUNCTION calculate_bonus(p_emp_id INT)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
  DECLARE v_salary DECIMAL(10,2);
  DECLARE v_dept VARCHAR(64);
  DECLARE v_years INT;
  DECLARE v_pct DECIMAL(5,2);

  SELECT salary, dept INTO v_salary, v_dept FROM employees WHERE emp_id = p_emp_id;
  IF v_salary IS NULL THEN
    RETURN NULL; -- employee not found
  END IF;

  SET v_years = years_with_company(p_emp_id);
  SET v_pct = 5.0; -- base 5%

  IF v_years > 2 THEN
    SET v_pct = v_pct + LEAST(5, v_years - 2); -- +1% per year after 2, max +5
  END IF;

  IF v_dept = 'Sales' THEN
    SET v_pct = v_pct + 2.0;
  END IF;

  RETURN ROUND(v_salary * v_pct / 100.0, 2);
END$$
DELIMITER ;

-- ============================================================================
-- STORED PROCEDURES
-- ============================================================================

-- Procedure: promote_employee
DELIMITER $$
CREATE PROCEDURE promote_employee(
  IN p_emp_id INT,
  IN p_raise_pct DECIMAL(5,2),
  OUT p_new_salary DECIMAL(10,2)
)
BEGIN
  DECLARE v_old_salary DECIMAL(10,2);

  SELECT salary INTO v_old_salary FROM employees WHERE emp_id = p_emp_id;
  IF v_old_salary IS NULL THEN
    SET p_new_salary = NULL;
  ELSE
    UPDATE employees
    SET salary = salary * (1 + p_raise_pct / 100.0)
    WHERE emp_id = p_emp_id;

    SELECT salary INTO p_new_salary FROM employees WHERE emp_id = p_emp_id;
  END IF;
END$$
DELIMITER ;

-- Procedure: department_summary
DELIMITER $$
CREATE PROCEDURE department_summary(
  IN p_dept VARCHAR(64)
)
BEGIN
  SELECT
    p_dept AS department,
    COUNT(*) AS employee_count,
    ROUND(AVG(salary), 2) AS avg_salary,
    MIN(salary) AS min_salary,
    MAX(salary) AS max_salary,
    ROUND(SUM(salary), 2) AS total_payroll
  FROM employees
  WHERE dept = p_dept;
END$$
DELIMITER ;

-- ============================================================================
-- USAGE EXAMPLES
-- ============================================================================

SELECT years_with_company(1) AS years_emp1;
SELECT calculate_bonus(1) AS bonus_emp1;

CALL promote_employee(1, 10.0, @new_salary);
SELECT @new_salary AS new_salary_after_raise;

CALL department_summary('Engineering');

SELECT * FROM employees;

-- ============================================================================
-- SQLITE NOTES
-- ----------------------------------------------------------------------------
-- SQLite does not support CREATE FUNCTION or CREATE PROCEDURE in SQL itself.
-- To implement similar behavior, create functions in a host language (Python/Node)
-- and register them with the SQLite connection, or implement the logic in the app.
-- ============================================================================

