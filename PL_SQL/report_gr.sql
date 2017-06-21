CREATE OR REPLACE PROCEDURE report_gr is 
	i_num  NUMBER := 0; -- primary key

	v_fname varchar2(15);  -- The first name of the employee.
	v_lname varchar2(15);  -- last name of the employee.
	v_ssn char(9);         -- social security number of the employee.
	v_dname varchar2(15);  -- name of the department.
	v_sup_name varchar2(25); -- employee's supervisor name.
	v_salary number(8,2); -- annual salary.
	v_n_deps number(2);  -- number of dependents the employee has
	v_d_proj_num number(2); -- number of projects to which the employee is assigned that are controlled by the employee's own department
	v_d_proj_hrs number(5,2); -- total number of hours for which the employee is assigned to those in-department projects.
	v_d_proj_cost number(7,2); -- cost is calculated from the employee's salary by the formula.
	v_nd_proj_num number(2); -- number of projects to which the employee is assigned that are NOT controlled by the employee's own department.
	v_nd_proj_hrs number(5,2); -- total number of hours for which the employee is assigned to those out-of-department projects.
	v_nd_proj_cost number(7,2); --  cost of those hours.
	v_under number(5,2); -- total number of hours for which the employee is assigned is less than 40.
	v_over number(5,2); -- total number of hours for which the employee is assigned is greater than 40.
	v_other_depts varchar2(50); -- names of departments to whose projects the employee is assigned
	v_user_name varchar2(10) := 'rvajrapu';  -- user name.
	v_insert_number number(4);

cursor emp is
select e1.ssn, e1.fname, e1.lname, e1.dno, e1.salary, 
	   e2.fname || ' ' || e2.minit || ' ' || e2.lname as sup_name 
from employee e1 left join employee e2
on e1.superssn = e2.ssn
order by ssn;
c_emp emp%rowtype;

-- create a cursor to get the number of projects, project hours, salary to which the employee is assigned that are controlled by the employee's own department
cursor own_dept is
	select ssn,count(ssn) as d_proj_num, sum(hours) as d_proj_hrs, sum(hours)*salary/2000 as d_proj_cost
	from employee
	join works_on
	on ssn = essn
	join department
	on dno=dnumber
	join project
	on dnum=dnumber and pnumber=pno
	where ssn = c_emp.ssn
	group by ssn, salary;
c_own_dept own_dept%rowtype;

-- create a cursor to get the number of projects, project hours, salary to which the employee is assigned that are not controlled by the employee's own department
cursor not_own_dept is
	select ssn,count(ssn) as nd_proj_num, sum(hours) as nd_proj_hrs, sum(hours)*salary/2000 as nd_proj_cost
	from employee
	join works_on
	on ssn = essn
	join department
	on dno<>dnumber
	join project
	on dnum=dnumber and pnumber=pno
	where ssn = c_emp.ssn
	group by ssn, salary;
c_not_own_dept not_own_dept%rowtype;

-- create a cursor to get the names of departments to whose projects the employee is assigned that are not his department, in alphabetical order.
cursor othdepts is	
    select dname
	from employee
	join works_on
	on ssn = essn
	join department
	on dno!=dnumber
	join project
	on dnum=dnumber and pnumber=pno
	where ssn =c_emp.ssn
	group by ssn, dname;
c_othdepts othdepts%rowtype;


-- get the department names of employee based on dno.
function get_dept_name(department_number department.dnumber%type)
return department.dname%type
is result department.dname%type;
	begin
		select dname into result from department where dnumber = department_number;
		return result;
	end;

-- get number of dependents the employee has based upon his ssn.
function get_dependent_number(ssn employee.ssn%type)
return number
is result number;
   begin
   	  select count(*) into result from dependent where essn = ssn; 
   	  return  result;
   end;

-- get the total number of hours for which the employee is assigned is less than 40.
function get_under(param_ssn employee.ssn%type)
return number
is result number;
	begin
		select 40-sum(hours) into result
		from employee left join works_on
		on ssn=essn
		where ssn = param_ssn;
                if result > 0 then 
                   return result;
                else 
                   return 0; 
                end if;
	end;

-- get the total number of hours for which the employee is assigned is greater than 40.
function get_over(param_ssn employee.ssn%type)
return number
is result number;
	begin
		select sum(hours)-40 into result
		from employee left join works_on
		on ssn=essn
		where ssn = param_ssn;
                if result > 0 then 
                   return result;
                else 
                   return 0; 
                end if;
	end;

BEGIN
	for locemp in emp loop
	 	i_num := i_num + 1;
		v_insert_number := i_num;
		v_ssn := locemp.ssn;
		v_fname := locemp.fname;
		v_lname := locemp.lname;
		v_salary := locemp.salary;
		v_n_deps := get_dependent_number(locemp.ssn);
		v_dname := get_dept_name(locemp.dno);
		v_d_proj_num := 0;
		v_d_proj_hrs := 0;
		v_d_proj_cost := 0;		
		v_nd_proj_num := 0;
		v_nd_proj_hrs := 0;
		v_nd_proj_cost := 0;
		v_under := get_under(locemp.ssn);
		v_over := get_over(locemp.ssn);		
		v_other_depts := '';
	    c_emp.dno := locemp.dno;
		c_emp.ssn := locemp.ssn;

		-- trim the values and check the variables have null value. If so replace them by 0.
		if trim(locemp.sup_name) is null then
			v_sup_name := 'NONE';
		else 
			v_sup_name := locemp.sup_name;
		end if;

		if v_n_deps is null then
			v_n_deps := 0;
		end if;

		if v_dname is null then
			v_dname := 'NONE';
		end if;	

		--  concat the departments names of the employees using , seperator. Make them into a single string.
 		for i in othdepts loop
			if v_other_depts is null then
				v_other_depts := i.dname;
			else
				v_other_depts := v_other_depts || ', ' || i.dname;
			end if;
		end loop; 
		if v_other_depts is null then
			v_other_depts := 'NONE';
		end if;	

		open own_dept;
			fetch own_dept into c_own_dept;
		if own_dept%found then
			if (c_own_dept.d_proj_hrs is not null) then
				v_d_proj_hrs := c_own_dept.d_proj_hrs;
				v_d_proj_cost := c_own_dept.d_proj_cost;	
			end if;
			if c_own_dept.d_proj_num is not null then
				v_d_proj_num := c_own_dept.d_proj_num;
			end if;
		end if;
		close own_dept;			
		
		open not_own_dept;
			fetch not_own_dept into c_not_own_dept;
		if not_own_dept%found then
			if (c_not_own_dept.nd_proj_hrs is not null) then
				v_nd_proj_hrs := c_not_own_dept.nd_proj_hrs;
				v_nd_proj_cost := c_not_own_dept.nd_proj_cost;	
			end if;
			if c_not_own_dept.nd_proj_num is not null then
				v_nd_proj_num := c_not_own_dept.nd_proj_num;
			end if;
		end if;
		close not_own_dept;	

		-- Insert into the database using the predefined stored procedure.
		cs450.ins_emp_summary(
			   v_fname,
			   v_lname,
			   v_ssn,
			   v_dname,
			   v_sup_name,
			   v_salary,
			   v_n_deps,
			   v_d_proj_num,
			   v_d_proj_hrs,
			   v_d_proj_cost,
			   v_nd_proj_num,
			   v_nd_proj_hrs,
			   v_nd_proj_cost,
			   v_under,
			   v_over,
			   v_other_depts,
			   v_user_name,
			   v_insert_number);
	end loop; 
END;
/

