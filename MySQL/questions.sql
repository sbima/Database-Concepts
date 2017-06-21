rem Authors: Shivani Bimavarapu and Bhavani Manthena
rem SQL Assignment, Fall 2015
rem ===================================================================
rem Question 1. Retrieve the first and last names and department
rem number and name of all employees directly supervised by James 
rem Borg. Show results in ascending alpha order (by last name and then 
rem first name). 
rem ===================================================================
SELECT fname,lname,dno as DNUMBER,dname FROM employee,department
where superssn = 
      (SELECT ssn FROM employee where fname='James' 
      AND lname='Borg') 
AND dno=dnumber
ORDER BY lname,fname;
rem ===================================================================
rem Question 2. Retrieve the names of employees who work on
rem exactly one project that is controlled by their department. (It 
rem does not matter how many non-departmental projects they work on.) 
rem Also show the department name, and the project name and location. 
rem Show results in ascending alpha order (by last name 
rem and then first name)
rem ===================================================================
SELECT fname, lname, dname, pname, plocation FROM employee 
JOIN works_on
ON ssn=essn
JOIN project
ON pno=pnumber
JOIN department
ON dno=dnumber
where 1=(SELECT COUNT(ESSN) FROM works_on,project
        WHERE pno=pnumber AND dno=dnum AND ssn=essn
        GROUP BY ESSN,DNUM) 
        AND dno=dnum
ORDER BY lname,fname;
rem ===================================================================
rem Question 4. Retrieve the names of employees who work on
rem projects controlled by their departments and do not work on
rem projectsthat are controlled by other departments. Show their names,
rem departments, and the number of projects on which they work. Show
rem results in ascending alpha order (by last name and then first
rem name).
rem ===================================================================
SELECT fname,lname,dname,count(project.pnumber) as NUM_PROJ 
FROM 
      (SELECT ssn FROM works_on,project,employee
      WHERE pno=pnumber AND dno=dnum AND ssn=essn 
      MINUS
      SELECT ssn FROM works_on,project,employee
      WHERE pno=pnumber AND dno!=dnum AND ssn=essn) A
JOIN employee
      ON employee.ssn=A.ssn
JOIN department
      ON dno=dnumber
JOIN works_on
      ON A.ssn=works_on.essn
JOIN project
      ON works_on.pno=project.pnumber 
      AND employee.dno=project.dnum
GROUP BY lname,fname,dname
ORDER BY lname,fname;
rem ===================================================================
rem Question 5. Retrieve the first and last names of any employees who
rem work on every company project. Show results in ascending alpha
rem order (by last name and then first name). [Note that an employee
rem should be on the list if and only if he or she works on every
rem project.]
rem ===================================================================
with a as
    (SELECT count(pnumber) as count 
    from project),
b as(SELECT ssn,count(pno) as count1 from works_on 
    join employee 
    on works_on.essn= employee.ssn
    group by ssn),
c as(SELECT * from b 
    join  a
    on b.count1 = a.count)
SELECT fname,lname from employee
join c
on c.ssn= employee.ssn
order by lname,fname;
rem ===================================================================
rem Question 6. Retrieve the project name and number of projects
rem which use more than the average number of employees. (Note: projects
rem that do not use any employees are to be included in the average.)
rem Display the project names, the number of employees they use, and
rem the average number of employees. (The same average should be 
rem repeated in each row.) Show results in project number order. [The 
rem average number of employees is the average number of employees 
rem used per project.] 
rem ===================================================================
WITH totalemp as 
    (SELECT count(*) as empcount FROM works_on),
totalprj as 
    (SELECT count(*) as prjcount FROM project),
average as 
    (SELECT (empcount/prjcount) AS average FROM totalemp,totalprj)
SELECT PNAME,PNO as PNUMBER,count as NUM_EMPS,AVERAGE AS EMP_AVG 
FROM (SELECT count(essn) as count,PNAME,PNO
      FROM works_on,project
      WHERE pno=pnumber
      GROUP BY PNAME,PNO) A, average
where count>average
ORDER BY PNO;
rem ===================================================================
rem Question 7. For each department, show the location that has
rem the most projects that the department controls. Also show the number
rem of department projects at that location. If more than one location
rem has the maximum number of projects, show them all. NOTE: if a
rem department has no projects, num_proj should be 0 and plocation should
rem be blank. Show results in ascending alpha order by department and
rem then location.
rem ===================================================================
with pcount as 
      (select DNAME,PLOCATION,count(pnumber) as p_count 
      from department left join project on dnum=department.dnumber 
      GROUP BY DNAME,PLOCATION),
maxcount as 
      (select DNAME,PLOCATION,MAX(p_count) as m_count 
      from pcount GROUP BY DNAME,PLOCATION)
select p.dname as DNAME,p.plocation as PLOCATION, p_count as NUM_PROJ from pcount p,maxcount m
where p.dname=m.dname
      AND p.plocation=m.plocation
      AND p_count = m_count
ORDER BY DNAME,PLOCATION;
rem ===================================================================
rem Question 8. Retrieve the average salary of supervisors in each
rem department showing the department name and the average supervisor
rem salary. Show results in ascending alpha order. [A supervisor is
rem considered to be in a department if his/her DNO matches that of 
rem the department. He/she may supervise employees outside the 
rem department.]
rem ===================================================================
WITH suprssn as 
      (SELECT A.superssn,B.dno,B.salary FROM employee A,employee B
      where A.superssn = B.ssn)
SELECT DNAME,AVG(SALARY) as AVG_SAL FROM suprssn,department
WHERE dno=dnumber
GROUP BY DNO,DNAME
ORDER BY DNAME;
rem ===================================================================
rem Question 9. Retrieve the first and last names of all employee
rem supervisors who have no dependents. Show results in ascending
rem alpha order (by last name and then first name).
rem ===================================================================
with a as
      (select superssn from employee
      minus
      select essn from dependent)
select fname, lname from employee
join a
on a.superssn = employee.ssn
order by lname, fname;
rem ===================================================================
rem Question 10. Retrieve the names and numbers of projects which
rem use at least one employee for more than 15 hours. Show results
rem in ascending alpha order. 
rem ===================================================================
SELECT distinct pname,pnumber
FROM works_on,project
WHERE pno=pnumber
      AND hours>15
ORDER BY PNAME;
rem ===================================================================
rem GROUP 2
rem ===================================================================
rem Question 12. EMPLOYEES. Write a query of the Oracle data
rem dictionary that will retrieve the column names, data types, and data
rem lengths of the table CS450.EMPLOYEE. You may NOT use 'describe' (or
rem 'desc') for this answer. Your query must begin with SELECT. Show
rem results in ascending alpha order of column name.
rem ===================================================================
select COLUMN_NAME as COLNAME,
      DATA_TYPE as DTYPE,
      DATA_LENGTH as DLENGTH
FROM ALL_TAB_COLUMNS
WHERE owner='CS450'
      AND table_name='EMPLOYEE'
ORDER BY COLNAME;
rem ===================================================================
rem Question 13. PRIMARY KEY. Write a query which retrieves the
rem columns in the primary key of CS450.WORKS_ON from the Oracle data
rem dictionary. It will help to know that 'CONSTRAINTS' is sometimes
rem abbreviated 'CONS' in the data dictionary table/view names. NOTE:
rem your query cannot contain the words 'ssn', 'essn', 'pno', or 
rem 'pnumber'. Show results in ascending alpha order of column name.
rem ===================================================================
select COLUMN_NAME as COLNAME 
      from ALL_CONS_COLUMNS cols, ALL_CONSTRAINTS con
where cols.OWNER = 'CS450'
      and cols.TABLE_NAME = 'WORKS_ON'
      and con.CONSTRAINT_TYPE = 'P'
      and cols.CONSTRAINT_NAME = con.CONSTRAINT_NAME
order by COLNAME;
rem ===================================================================
rem Question 14. FOREIGN KEY. Write a query which retrieves from
rem the Oracle data dictionary the names of all the tables in the CS450
rem account that contain a foreign key pointing to the CS450.EMPLOYEE 
rem table. It may help to know that 'CONSTRAINTS' is sometimes 
rem abbreviated 'CONS' in the data dictionary table/view names. Show 
rem results in ascending alpha order by table name.
rem ===================================================================
select TABLE_NAME from ALL_CONSTRAINTS con
where R_OWNER like 'CS450'
and EXISTS 
      ( select CONSTRAINT_NAME from ALL_CONSTRAINTS
      where OWNER like 'CS450'
      and   TABLE_NAME like 'EMPLOYEE'
      and CONSTRAINT_TYPE = 'P' 
      and CONSTRAINT_NAME = con.R_CONSTRAINT_NAME)
order by TABLE_NAME;
rem ===================================================================
rem All the work submitted in this file is our own work.  
rem We have not received or copied answers from anyone else.  
rem In addition, we have not given answers to anyone else 
rem or allowed anyone to copy them.