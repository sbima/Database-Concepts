<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<?
// Opening HTML and CSS printed with TopMatter()  
echo TopMatter();
if (! isset($_POST['user_name'] , $_POST['password'] ,$_POST['sid'])
    || !$_POST['user_name'] || !$_POST['password'] || !$_POST['sid']) {
       echo LoginForm();
} else {  
  # we have the values we need, so we can go to work.
   echo OverallExplanation();
   require_once 'MDB2.php';
  # make the login ID case insensitive. Should work on both lower and upper case
   $uid = strtoupper($_POST['user_name']);
  # Check if the given user ID is correct
   VerifyUID($uid);
   $con =& MakeConnection($uid);
  # Check for connection errors if any
   error_check($con,'MakeConnection');
///////////////////////////////////////////////////
// IMPORTANT NOTE:
// if your inserts are to be credited to you
// they have to have your ORACLE ID attached to them.
// In the code below, they are going to be credited to
// whoever logged in which might be you, your partner
// or your instructor, because they are passed with the
// parameter $uid.
//
// To make sure you get credit, be sure you uncomment
// the following line and replace XXXXXXXX with your
// ORACLE ID:
//
//      $uid = 'XXXXXXXX';
//
// DO NOT make this change until you are ready to submit
// this code.  The insert and clean procedures will not work
// properly for anyone except your instructor and $uid
// after you make the change, i.e., they will not work for
// your partner.
// 
// Be sure not to move this line earlier in the code
// because the orginal $uid is needed to connect the
// user and their password with the DB
///////////////////////////////////////////////////

// This sequence of functions all output text that is either
// 1. sent to standard output, or
// 2. stored in program variables
echo Approach();
$query1 = Query1();
echo ExplainQuery1($query1);
$query2 = Query2();
echo ExplainQuery2($query2);
$query3 = Query3();
echo ExplainQuery3($query3);
$query4 = Query4();
echo ExplainQuery4($query4);
$bigquery = BigQuery($query1,$query2,$query3,$query4);
echo ExplainBigQuery($bigquery);

CleanTable();

echo "<h4>Then run the query explained above</h4>";

$result =& $con->query($bigquery);
error_check($result,'querying with bigquery');
ShowTable($result,0);
  # we do not free $result since we need the results for inserting below
  # the 0 means do not free.
  # but fetchRow() is an iterator that has run off the end of the result set
  # so we have to set it back to the beginning:
$result->seek(0);

echo ExplainExtraQuery();

echo  "<h4>Insert each tuple of the results of bigquery</h4>";
$insert_number = 1;
while ($array = $result->fetchRow(MDB2_FETCHMODE_ASSOC)) {
   # you can retrieve individual fields by name from the $array hash
   # and put them in individual variables like this:
   $ssn =$array['ssn']; 
   # or use the method shown below, where they have to be enclosed
   # in curly braces
   #
   # Here we use a separate query to get the num_dept information for each row

   $query5 = Query5($ssn);
   $count_dep=0;
   $result_count_dep =& $con->query($query5);
   while ($array1 = $result_count_dep->fetchRow(MDB2_FETCHMODE_ASSOC))
   {
      $count_dep = $array1['total_depend'];
   }
  $query6 = Query6($ssn);
   $result_under =& $con->query($query6);
   while ($array_u = $result_under->fetchRow(MDB2_FETCHMODE_ASSOC))
   {
      $under_val = $array_u['result'];
   }

   $query7 = Query7($ssn);
  
   $result_over =& $con->query($query7);
   while ($array_o = $result_over->fetchRow(MDB2_FETCHMODE_ASSOC))
   {
      $over_val = $array_o['result'];
   }
   $oth_dept = $array['agg_dname'];
   if(trim($oth_dept) == "" || $oth_dept == NULL)
   {
    $oth_dept = 'NONE';
   }
      
   # if supervisor name is not found then insert null
   $sup_name = $array['sup_name'];
   if(trim($sup_name) == "" || $sup_name == NULL)
   {
      $sup_name = 'NONE';
   }
   if($under_val < 0 || $under_val == NULL) 
    $under_val = 0;
    
   if($over_val < 0 || $over_val == NULL)
    $over_val = 0;

   #queryOne is a handy shortcut to return a single value from the DB
   print "Ran <pre class='query'>$query5 </pre> and retrieved <b> $num_dept</b> for num_dept.<br>";
      InsertRow($array['fname'],
      $array['lname'],
      $ssn,
      $array['dname'],
      $sup_name,
      $array['salary'],
      $count_dep,
      $array['d_proj_num'],
      $array['d_proj_hrs'],
    $array['d_proj_cost'],
    $array['nd_proj_num'],
    $array['nd_proj_hrs'],
    $array['nd_proj_cost'],
    $under_val,
    $over_val,
    $oth_dept);

   $insert_number++;
}

   # important to free memory used by $result
$result->free();
DisplayResults();
   $con->disconnect();

}
?>
<?
function TopMatter(){
   return <<<TOP
   <html>
   <head>
   <style type="text/css">
   H1,H2,H3,H4 {background: #bbdddd;}
   BODY {margin-left:5%; margin-right:5%;}
   PRE.query {font-size: 120%;
            font-style: italic;
            font-weight: 600;
            background: #ddbbdd;
   }
   .problem {background: #ddddbb;}
   .indent {margin-left: 5%;}

   </style>

   <title>PHP Example: #4</title>
   </head>
   <body>
TOP;
}
function LoginForm(){
  return <<<_HTML_
  <h2>Supply information to login to your Oracle Account</h2><br/>
    <form method="post" action="$_SERVER[PHP_SELF]">
    Enter your oracle account id: <input type="text" name="user_name" id="user_name">
    <br/>
    Enter your oracle account password: <input type="password" name="password" id="password">
    <br/>
    Enter your oracle account SID: <input type="text" name="sid" id="sid">
    <br/>
    <input type='submit' value='SUBMIT INFO'>
    </form>
_HTML_;
}
function OverallExplanation(){
   return <<<EXPLAIN
   <div class='problem'>
   <h2>Sample Problem Statement</h2>
   <pre>
   This is an example problem to show what is required in the PHP problem.

   The problem is to produce a report on each project location, that is,
   any location where any department has a project.  There is to be only
   one report for each location, even if there are several projects there.

   We want to know for each location:

   lname: The name of that location;
   num_proj: The number of projects in that location;
   num_emp: The number of employees with addresses in that location;
   num_dept: The number of departments with offices in that location;
   num_work: The number of different employees who work on projects in that location;
   tot_hours: The total hours worked by employees on projects in that location;
   tot_cost: The total cost of those hours;

   It is essential that the way your program figures out the values
   that are required be clearly explained on the web page.  This means that you may
   find that a complex query cannot be used because it is too difficult to explain.

   It is also essential that the result of each query be shown on the web page.  From
   here on down is an example of what your application should look like.

   NOTE: Your project output does not need a beginning section like this one.  The
   example should be considered to start from the next section.
   </pre></div>
      <table border="1">
      <tr><td colspan="2">This page is the solely the work of</td></tr>
      <tr><td>pratik naik</td><td>pnaik</td></tr>
      <tr><td>scott fox</td><td>sfox</td></tr>
      <tr><td colspan="2">We have not recieved aid from anyone<br>
      else in this assignment.  We have not given <br>
         anyone else aid in the 
      assignment</td></tr>
      </table>

EXPLAIN;
}
function VerifyUID($uid){
   $legal_names=array(
       'RVAJRAPU', 'VKOLANU', 'CS450', 'CS450A', 'CS450B', 'CS450C', 'CS450D');

   if ( ! in_array($uid, $legal_names)){
     print <<<HTML
       <h1>ACCESS DENIED</h1>
HTML;
     if (preg_match('/cs450\b/',__FILE__)){
     print <<<HTML
       <b>Copy the source code to your own public_html directory<br>
          by clicking on the "To see the code" link<br>
          and add your UID to the \$legal_names array in function VerifyUID</b>
HTML;
     }
     print <<<HTML
       </body>
       </html>
HTML;
     exit;
   }
}
function error_check($e2check,$e_in_msg){
   global $con;
   if(PEAR::isError($e2check)) {
      echo("<br>Error in $e_in_msg : ");
      echo( $e2check->getMessage() );
      echo( ' - ');
      echo( $e2check->getUserinfo());
      if ($con->disconnect){
      $con->disconnect();
      }
      print "</body></html>";
      exit;
   }else {
      echo("no error in $e_in_msg<br>");
   }
}
function MakeConnection($uid){
   // $_POST is automatically global
   $sid = strtoupper($_POST['sid']);
   // Sometimes you have to uncomment the next line
#  $sid .= '.cs.odu.edu'; # sometimes needed
   $dsn= array(
         'phptype'  => 'oci8',
         'dbsyntax' => 'oci8',
         'username' => $uid,
         'password' => $_POST['password'],
         'hostspec' => "oracle.cs.odu.edu",
         'service'  => $sid,
         );
   $con =& MDB2::factory($dsn, array('emulate_prepared' => false));
   return $con;
}
function Approach(){
return <<<HTML
<h3>Overview</h3>
<div class='problem'>The approach taken here is to calculate the columns for 
most of the answer in separate SQL queries that are to be collected together in 
a WITH clause at the beginning of one select statement.  The queries are all 
joined together on lname to produce the final result.  One difficult part is 
collected on a per-row basis. This is to show that you are not required to use 
the WITH approach.
</div>
HTML;
}
function CleanTable(){
   # builds the procedure call to clean the table, executes the query,
   # checks the result and explains what is going on.
   global $uid,$con;
   print "<h3>First clean proj_loc_summary table</h3>";
   // $query & $result are automatically local to CleanTable because not global
   $query = "
   BEGIN 
      cs450.clean_emp_summary('$uid'); 
   END;
   ";
   $query=preg_replace('/\r/','',$query);
   print("cleaning with <pre class='query'>$query</pre>");
   $result =& $con->query($query);
   error_check($result,'cleaning');
   $result->free();
}
function Query1(){
   return <<<QUERY
   select e1.ssn, e1.fname, e1.lname, e1.dno, e1.salary,dname, 
     e2.fname || ' ' || e2.minit || ' ' || e2.lname as sup_name 
    from employee e1 left join employee e2
    on e1.superssn = e2.ssn
    join department
    on dnumber=e1.dno
    order by ssn
QUERY;
}
function ExplainQuery1($query1){
   return <<<HTML
   <h3>Columns: lname and num_emp--query1</h3>
   <pre class="query">$query1</pre>
   <div class="indent"><b>Explanation</b>:
   <ul><li><u>select distinct plocation</u>: ensures that each location is only used once.
   Otherwise the same employee would be counted for each different plocation</li>
   <li><u>left join:</u> ensures that each plocation appears in the result even if no
   employee lives there</li>
   <li><u>count(fname):</u> count does not count nulls so plocations with no employees will
            show up with 0s</li>
   </ul></div>
HTML;
}
function Query2(){
   return<<<QUERY
  select employee.ssn,nvl(d_proj_num,0) as d_proj_num, nvl(d_proj_hrs,0) as d_proj_hrs, nvl(d_proj_cost,0) as d_proj_cost from employee left join (select ssn,nvl(count(ssn),0) as d_proj_num, nvl(sum(hours),0) as d_proj_hrs, sum(hours)*salary/2000 as d_proj_cost
  from works_on,project,employee
where pno=pnumber and dno=dnum and essn=ssn
group by ssn, salary) a
on employee.ssn = a.ssn
QUERY;
}
function ExplainQuery2($query2){
   return <<<HTML
   <h3>Columns: lname and num_proj--query2</h3>
   <pre class="query">$query2</pre>
   <div class="indent"><b>Explanation</b>:
   <p>Simple count of tuples per project location</p></div>
HTML;
}
function Query3(){
   return <<<QUERY
   select employee.ssn,nvl(nd_proj_num,0) as nd_proj_num , nvl(nd_proj_hrs,0) as nd_proj_hrs, nvl(nd_proj_cost,0) as nd_proj_cost from employee left join (select ssn,nvl(count(ssn),0) as nd_proj_num, nvl(sum(hours),0) as nd_proj_hrs, sum(hours)*salary/2000 as nd_proj_cost
  from works_on,project,employee,department
where pno=pnumber and dnumber=dnum and essn=ssn and dno<>dnumber
group by ssn, salary) a
on employee.ssn = a.ssn
QUERY;
}
function ExplainQuery3($query3){
   return <<<HTML
   <h3>Columns: lname and num_work--query3</h3>
   <pre class="query">$query3</pre>
   <div class="indent"><b>Explanation</b>:
   <ul><li><u>right join:</u> ensures each project appears, even if no one works on it</li>
   <li><u>count(distinct ssn):</u> does two things-- 
          counting ssn means nulls will not be counted
          and projects with no workers will have a count of 0; 
          <u>distinct</u> means workers will only be counted once.</li>
   </ul></div>
HTML;
}
function Query4(){
   return <<<QUERY
  select ssn, LISTAGG(dname, ', ')
         WITHIN GROUP (ORDER BY ssn, dname) as agg_dname
from (select ssn, dname
from employee
join works_on
on ssn = essn
join department
on dno<>dnumber
join project
on dnum=dnumber and pnumber=pno
where ssn in (select ssn from employee)
group by ssn, dname) a
group by ssn
QUERY;
}
function ExplainQuery4($query4){
   return <<<HTML
   <h3>Columns: lname, tot_hours, and tot_cost-- query4</h3>
   <pre class="query">$query4</pre>
   <div class="indent"><b>Explanation</b>:
   <ul><li><u>left join:</u>ensures each project appears, even if no one works on it</li>
   <li><u>sum(hours*salary/2000)</u> calculates this value for each tuple in the join
   on the from line so it is correct for each employee.</li>
   </ul></div>
HTML;
}

function BigQuery($query1,$query2,$query3,$query4){
   return <<<QUERY
   with 
      query1 as 
   ($query1),
      query2 as 
   ($query2),
      query3 as
   ($query3),
      query4 as 
   ($query4)
  select query1.ssn, fname, lname,dname, sup_name, salary,d_proj_num,d_proj_hrs,d_proj_cost, nd_proj_num, nd_proj_hrs, nd_proj_cost, agg_dname
    from query1 left join query2 on query1.ssn=query2.ssn
                       left join query3 on query1.ssn=query3.ssn
                       left join query4 on query1.ssn=query4.ssn     

QUERY;
}
function ExplainBigQuery($bigquery){
   return <<<HTML
   <h3>Final Query--bigquery</h3>
   <pre class="query">$bigquery</pre>
   <div class="indent">This just unites all four queries using the <u>with</u> construct</div>
HTML;
}
function ExplainExtraQuery(){
   return <<<QUERY
   <p>This gets all the information we need except <b>num_dept</b> which we will
   calculate for each row using the following query:</p>
   <pre class="query">
   select count(distinct dnumber) num_dept
   from dept_locations
   where dlocation = 'XXXX'
   </pre>

   <p>with the current plocation substituted for XXXX.</p>
QUERY;
}
function Query5($ssn){
   return <<<QUERY
      select count(*) as total_depend
      from dependent
      where essn = $ssn
QUERY;
}
function Query6($ssn){
   return <<<QUERY
          select 40-sum(hours) as result
          from employee left join works_on
          on ssn=essn
          where ssn = $ssn
QUERY;
}
function Query7($ssn){
   return <<<QUERY
    select sum(hours)-40 as result
    from employee left join works_on
    on ssn=essn
          where ssn = $ssn
QUERY;
}

function InsertRow($fname,$lname,$ssn,$dname,$sup_name,$salary,$count_dep,$d_proj_num,$d_proj_hrs,$d_proj_cost,$nd_proj_num,$nd_proj_hrs,$nd_proj_cost,$under_val,$over_val,$agg_dname){
   global $uid,$con,$insert_number;
   $query=<<<QUERY
   BEGIN
      cs450.ins_emp_summary(
            '$fname',  -- proj location
            '$lname',
            $ssn, -- number of projects
            '$dname',  -- number of employees living here
            '$sup_name',
            $salary, -- number of depts with offices here
            $count_dep, -- number of emps working on projects here
            $d_proj_num, -- their total hours
            $d_proj_hrs,  -- their total cost
            $d_proj_cost, -- number of depts with offices here
            $nd_proj_num, -- number of emps working on projects here
            $nd_proj_hrs, -- their total hours
            $nd_proj_cost,  -- their total cost
            $under_val, -- number of emps working on projects here
            $over_val, -- their total hours
            '$agg_dname',  -- their total cost
            '$uid',     -- me
            $insert_number -- row number
            );
   END;
QUERY;
   # if you write your code on windows rather than UNIX you will need to add this next line
   # to avoid an error.  
   $query=preg_replace('/\r/','',$query);
   # The error occurs because Windows ends lines with two characters
   # ascii 13 and 10 but unix only uses 10.  The PL/SQL process gets upset when it finds
   # the carriage returns (ascii 13) in the code for the procedure calls (but in the
   # SQL there is no problem).

   print("Inserting with <pre class='query'>$query</pre>");
   $result =& $con->query($query);
   error_check($result,'procedure call');
   $result->free();
   # important to free memory used by $result
}
function DisplayResults(){
   global $con, $uid;
   $query="select * from TABLE(cs450.ins_emp_summary('$uid'))";
   print <<<_HTML_
      <h4>Checking results of Database Procedure Inserts</h4>
      using query <pre class='query'>$query</pre>
_HTML_;
   $result =& $con->query($query);
   error_check($result,'querying ins_emp_summary');
   ShowTable($result, 1); # 1 means free $result
}
function ShowTable($result,$free = 0){
  #changed from last version.  do not always want to free $result
  #$free is assumed to be ==0 unless stated otherwise 
   echo "<br><table border='1'>";
   $header=0;
   while ($array = $result->fetchRow(MDB2_FETCHMODE_ASSOC)) {
      if (!$header){
         $header=1;
         echo "<TR>";
            foreach($array as $key => $field){
               echo("<th>$key</th>");
            }
         echo "</TR>";
      }
      echo "<tr>";
         foreach ($array as  $field){
            echo("<td>$field</td>");
         }
      echo "</tr>";
   }
   # important to free memory used by $result
   if ($free) { $result->free();}
   # this version does automatically not free because of reuse of $result

   echo "</table>";
}
?>

</body>
</html>