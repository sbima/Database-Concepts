prompt Authors: Shivani Bimavarapu and Bhavani Manthena
with t2 as (
select attempt.cname,attempt.ename,competitor.igan,Concat(Concat(competitor.bfirst,' '),competitor.blast) as competitor,
competitor.agegroup,greatest((attempt.j1a1+attempt.j2a1)/2.0,(attempt.j1a2+attempt.j2a2)/2.0) as score,competitor.tname 
from attempt,competitor
where attempt.igan=competitor.igan),
t3 as (select t2.cname,t2.agegroup,t2.igan,sum(t2.score) 
as sum_of_scores from t2 group by t2.cname,t2.agegroup,t2.igan),
t4 as (select t3.cname,t3.agegroup,max(t3.sum_of_scores) max_allaround 
from t3 group by t3.cname,t3.agegroup),
t5 as (select t3.cname,t3.agegroup,t3.igan,t3.sum_of_scores 
from t3,t4 where t3.cname=t4.cname and t3.agegroup=t4.agegroup 
and t3.sum_of_scores=t4.max_allaround)
select cname as Meet , agegroup as AGEGROUP, temp.tname as TEAM, 
team_score_comp as SCORE, CFirst || ' ' ||Clast as COACH from (
  select sum(team_score_event) as team_score_comp,cname,tname, 
  agegroup, row_number() over(partition by cname, agegroup 
  order by sum(team_score_event) desc) as comp_row_num  from (
    select sum(score) as team_score_event, cname, ename, tname, agegroup from (
      select score, cname, ename, igan, tname, agegroup, ROW_NUMBER()
        OVER(PARTITION BY cname,ename,tname, agegroup ORDER BY score DESC) as row_number from (  
          select 
              case 
               when j1a1 + j2a1 > j1a2 + j2a2 then (j1a1+j2a1)/2
               else (j1a2 + j2a2)/2
             end as score, cname, ename, agegroup, attempt.igan, tname
             from attempt
             join competitor on competitor.igan = attempt.igan    
             where competitor.tname is not null and competitor.igan 
             not in 
             (select t5.igan from t5,competitor where t5.igan=competitor.igan)
       )     
    ) where row_number <= 4 group by cname, ename, tname, agegroup
  ) group by cname, tname, agegroup
)temp join coach on coach.tname = temp.tname 
where comp_row_num = 1 and coach.status='head' order by meet, agegroup;
PROMPT USED SQL ONLY