prompt Authors: Shivani Bimavarapu and Bhavani Manthena
select temp.tname as TNAME, points as PTS, rank as RANK, cfirst|| ' '||clast as COACH from(
select sum(rank) as points, tname, row_number() over(order by sum(rank) desc) as rank from ( 
select 
      case 
        when comp_row_num = 1 then 4
        when comp_row_num = 2 then 2
        else 1
      end as rank, cname, tname, team_score_comp as score, agegroup, comp_row_num from (
	select sum(team_score_event) as team_score_comp,cname,tname, agegroup, row_number() over(partition by cname, agegroup 
		order by sum(team_score_event) desc) as comp_row_num  from (
		select sum(score) as team_score_event, cname, ename, tname, agegroup from (		
			select score, cname, ename, igan, tname, agegroup, ROW_NUMBER()
		    OVER(PARTITION BY cname,ename,tname, agegroup ORDER BY score DESC) as row_number from (	   
		    select 
			        case 
			         when j1a1 + j2a1 > j1a2 + j2a2 then j1a1+j2a1
			         else j1a2 + j2a2
			       end as score, cname, ename, agegroup, attempt.igan, tname
			       from attempt
			       join competitor on competitor.igan = attempt.igan    
			       where competitor.tname is not null
		   )  
		) where row_number <= 4 group by cname, ename, tname, agegroup
	) group by cname, tname, agegroup
) where comp_row_num <= 3) group by tname )temp j
oin coach on coach.tname = temp.tname where coach.status='head' order by pts desc ;
PROMPT USED SQL ONLY