use ipl;
select * from ipl_bidder_details;
select * from ipl_bidder_points;
select * from ipl_bidding_details;
select * from ipl_match;
select * from ipl_match_schedule;
select * from ipl_player;
select * from ipl_stadium;
select * from ipl_team;
select * from ipl_team_players;
select * from ipl_team_standings;
select * from ipl_tournament;
select * from ipl_user;

#1.	Show the percentage of wins of each bidder in the order of highest to lowest percentage.

with cte as
(select bidder_id , bid_status, count(*) as cnt,
sum(count(*))over(partition by bidder_id) as total_cnt
from ipl_bidding_details
group by bidder_id, bid_status)

select bidder_id, (cnt/total_cnt)*100 as 'win percentage'
from cte
where bid_status = 'won'
order by (cnt/total_cnt)*100 desc;

select bdr_dt.bidder_id 'Bidder ID', bdr_dt.bidder_name 'Bidder Name', 
(select count(*) from ipl_bidding_details bid_dt 
where bid_dt.bid_status = 'won' and bid_dt.bidder_id = bdr_dt.bidder_id) / 
(select no_of_bids from ipl_bidder_points bdr_pt 
where bdr_pt.bidder_id = bdr_dt.bidder_id)*100 as 'Percentage of Wins (%)'
from ipl_bidder_details bdr_dt order by 3 desc;

#2.	Display the number of matches conducted at each stadium with the stadium name and city.

select STADIUM_NAME, CITY, count(*) as match_cnt
from IPL_MATCH_SCHEDULE as i_m_s
join IPL_STADIUM as i_s
on i_m_s.STADIUM_ID = i_s.STADIUM_ID
group by i_m_s.STADIUM_ID;

#3.	In a given stadium, what is the percentage of wins by a team that has won the toss?

with cte as
(select *
from (select 'Wins by a team that has won the toss' as 'Category', count(*) as 'Count'
from IPL_MATCH
where TOSS_WINNER = MATCH_WINNER) as t1
,(select 'Total match count' as 'Total Category', count(*) as 'Total Count'
from IPL_MATCH) as t2)

select category,concat(round((count/`Total Count`)*100, 2), '%') as "Percentage(%)"
from cte; -- doubt

select stadium_id 'Stadium ID', stadium_name 'Stadium Name',
(select count(*) from ipl_match m join ipl_match_schedule ms on m.match_id = ms.match_id
where ms.stadium_id = s.stadium_id and (toss_winner = match_winner)) /
(select count(*) from ipl_match_schedule ms where ms.stadium_id = s.stadium_id) * 100 
as 'Percentage of Wins by teams who won the toss (%)'
from ipl_stadium s;

#4.	Show the total bids along with the bid team and team name.

select t1.BIDDER_ID, BID_TEAM, BIDDER_NAME, total_bid_count
from IPL_BIDDER_DETAILS as t1
inner join (SELECT *,
count(*)over(partition by bid_team) as total_bid_count
FROM ipl.IPL_BIDDING_DETAILS) as t2
on t1.BIDDER_ID = t2.BIDDER_ID;

#5.	Show the team ID who won the match as per the win details.
select match_id, TEAM_ID, TEAM_NAME, WIN_DETAILS
from (SELECT match_id, WIN_DETAILS,
trim(substring(WIN_DETAILS,6,3)) as team_abv
FROM IPL_MATCH) as t1
join IPL_TEAM as t2
on team_abv = t2.remarks;

#6.	Display the total matches played, total matches won and total matches lost by the team along with its team name.
select TEAM_NAME, winner_count, looser_count
from(
select winner as team_id,
winner_count, looser_count
from
(
select winner, count(*) as winner_count
from (select *,
if(MATCH_WINNER = 1,TEAM_ID1,"") as 'Winner',
if(MATCH_WINNER = 2,TEAM_ID2,"") as 'Looser'
from IPL_MATCH) as temp1
where winner>0
group by winner
order by winner
) as tab1
inner join
(
select looser, count(*) as looser_count
from (select *,
if(MATCH_WINNER = 1,TEAM_ID1,"") as 'Winner',
if(MATCH_WINNER = 2,TEAM_ID2,"") as 'Looser'
from IPL_MATCH) as temp1
where looser>0
group by looser
order by looser
) as tab2
on tab1.winner = tab2.looser)
as temp1 
inner join IPL_TEAM as temp2
on temp1.team_id = temp2.team_id;

#7.	Display the bowlers for the Mumbai Indians team.
select player_id, player_name
from IPL_PLAYER
where player_id in (SELECT player_id FROM ipl.IPL_TEAM_PLAYERS
where player_role = 'bowler'
and remarks like '%MI%');

#8.	How many all-rounders are there in each team, Display the teams with more than 4 
#all-rounders in descending order.
select TEAM_NAME, cnt
from (SELECT substr(remarks,(instr(remarks, '-')+2)) as Team, count(*) as Cnt
FROM ipl.IPL_TEAM_PLAYERS
where player_role = 'All-Rounder'
group by remarks
having count(*) > 4) as t1
join IPL_TEAM as t2
where team=remarks
order by cnt desc;

#9.	 Write a query to get the total bidders' points for each bidding status of those bidders who bid on CSK when they won 
#the match in M. Chinnaswamy Stadium bidding year-wise.
#Note the total bidders’ points in descending order and the year is the bidding year.
#Display columns: bidding status, bid date as year, total bidder’s points
select BID_STATUS, year(BID_DATE) as BID_DATE, TOTAL_POINTS
from IPL_BIDDER_POINTS as t1
join (
select * from IPL_BIDDING_DETAILS
where schedule_id in (
select schedule_id
from (select *
from IPL_MATCH) as tab1
join (select *
from IPL_MATCH_SCHEDULE
where STADIUM_ID = (select stadium_id
from IPL_STADIUM
where STADIUM_NAME = 'M. Chinnaswamy Stadium')) as tab2
on tab1.MATCH_ID = tab2.MATCH_ID
where WIN_DETAILS like '%CSK won%')) as t2
on t1.bidder_id = t2.bidder_id;

#10.	Extract the Bowlers and All-Rounders that are in the 5 highest number of wickets.
#Note 
#1. Use the performance_dtls column from ipl_player to get the total number of wickets
#2. Do not use the limit method because it might not give appropriate results when players have the same number of wickets
#3.	Do not use joins in any cases.
#4.	Display the following columns teamn_name, player_name, and player_role.
select 
(select TEAM_NAME 
from IPL_TEAM 
where TEAM_ID in (select TEAM_ID from IPL_TEAM_PLAYERS where PLAYER_ID = t1.PLAYER_ID)) as TEAM_NAME,
PLAYER_NAME,
(select PLAYER_ROLE from IPL_TEAM_PLAYERS where PLAYER_ID = t1.PLAYER_ID) as PLAYER_ROLE,
No_of_wicket
from (select PLAYER_ID, PLAYER_NAME,
convert(substring(PERFORMANCE_DTLS,(instr(PERFORMANCE_DTLS, 'wkt')+4),2), unsigned Integer) as 'No_of_wicket',
row_number()over(order by convert(substring(PERFORMANCE_DTLS,(instr(PERFORMANCE_DTLS, 'wkt')+4),2), unsigned Integer) desc) as rw_num
from IPL_PLAYER
where PLAYER_ID in (select PLAYER_ID
from IPL_TEAM_PLAYERS
where PLAYER_ROLE in ('All-Rounder', 'Bowler'))) as t1
where rw_num <= 5;

#11.	show the percentage of toss wins of each bidder and display the results in descending order based on the percentage
with cte as
(select *,
count(*) over(partition by bidder_id, w_l)/bid_count_by_bidder*100 as 'Percentage(%)'
from (select BIDDER_ID, i_b_d.SCHEDULE_ID, BID_TEAM, i_m.MATCH_ID,
if(toss_winner = team_id1, team_id1, team_id2) as toss_winner_id,
if(BID_TEAM = (if(toss_winner = team_id1, team_id1, team_id2)), 'Win', 'Loss') as W_L,
count(*) over(partition by bidder_id) as 'bid_count_by_bidder'
from IPL_BIDDING_DETAILS as i_b_d
inner join IPL_MATCH_SCHEDULE as i_m_s
on i_b_d.SCHEDULE_ID = i_m_s.SCHEDULE_ID
inner join IPL_MATCH as i_m
on i_m_s.MATCH_ID = i_m.MATCH_ID) as t1)

select distinct bidder_id, `Percentage(%)` as `Toss win Percentage(%)`
from cte
where w_l = 'Win'
order by `Percentage(%)` desc;

#12.	find the IPL season which has a duration and max duration.
#Output columns should be like the below:
#Tournment_ID, Tourment_name, Duration column, Duration
select TOURNMT_ID, TOURNMT_NAME, datediff(TO_DATE,FROM_DATE) as `Duration(in days)`
from IPL_TOURNAMENT;

#13.	Write a query to display to calculate the total points month-wise for the 2017 bid year. sort the results based on total points in descending order and month-wise in ascending order.
#Note: Display the following columns:
#1.	Bidder ID, 2. Bidder Name, 3. Bid date as Year, 4. Bid date as Month, 5. Total points
#Only use joins for the above query queries.
select distinct t1.BIDDER_ID, BIDDER_NAME, year(BID_DATE) as `Bid date as Year`, month(BID_DATE) as `Bid date as Month`, TOTAL_POINTS
from (SELECT * FROM IPL_BIDDING_DETAILS
where year(bid_date)=2017) as t1
join IPL_BIDDER_POINTS as t2
on t1.BIDDER_ID = t2.BIDDER_ID
join IPL_BIDDER_DETAILS as t3
on t2.BIDDER_ID=t3.BIDDER_ID
order by TOTAL_POINTS desc, month(BID_DATE) asc;

#14.	Write a query for the above question using sub-queries by having the same constraints as the above question.
SELECT distinct BIDDER_ID,
(select BIDDER_NAME from IPL_BIDDER_DETAILS where BIDDER_ID = t1.BIDDER_ID) as 'BIDDER_NAME',
year(BID_DATE) as `Bid date as Year`, month(BID_DATE) as `Bid date as Month`,
(select TOTAL_POINTS from IPL_BIDDER_POINTS where BIDDER_ID = t1.BIDDER_ID) as TOTAL_POINTS
FROM IPL_BIDDING_DETAILS as t1
where year(bid_date)=2017
order by (select TOTAL_POINTS from IPL_BIDDER_POINTS where BIDDER_ID = t1.BIDDER_ID) desc, month(BID_DATE) asc;

#15.	Write a query to get the top 3 and bottom 3 bidders based on the total bidding points for the 2018 bidding year.
#Output columns should be:
#like
#Bidder Id, Ranks (optional), Total points, Highest_3_Bidders --> columns contains name of bidder, Lowest_3_Bidders  --> columns contains name of bidder;
with cte as
(SELECT distinct BIDDER_ID,
(select TOTAL_POINTS from IPL_BIDDER_POINTS where BIDDER_ID = t1.BIDDER_ID) as TOTAL_POINTS
FROM IPL_BIDDING_DETAILS as t1
where year(BID_DATE) = 2018)

select top3.BIDDER_ID, top3.TOTAL_POINTS, Highest_3_Bidders,
bot3.BIDDER_ID, bot3.TOTAL_POINTS, Lowest_3_Bidders
from (select row_number()over(order by TOTAL_POINTS desc) as rw_num,
tab_1.BIDDER_ID, TOTAL_POINTS, BIDDER_NAME as Highest_3_Bidders
from cte as tab_1
,(select * from IPL_BIDDER_DETAILS
where BIDDER_ID in (select BIDDER_ID from cte)) as tab_2
where tab_1.BIDDER_ID = tab_2.BIDDER_ID
order by TOTAL_POINTS desc limit 3) as top3
left JOIN
(select row_number()over(order by TOTAL_POINTS) as rw_num,
tab_1.BIDDER_ID, TOTAL_POINTS, BIDDER_NAME as Lowest_3_Bidders
from cte as tab_1
,(select * from IPL_BIDDER_DETAILS
where BIDDER_ID in (select BIDDER_ID from cte)) as tab_2
where tab_1.BIDDER_ID = tab_2.BIDDER_ID
order by TOTAL_POINTS limit 3) as bot3
on top3.rw_num = bot3.rw_num;

#16.	Create two tables called Student_details and Student_details_backup. (Additional Question - Self Study is required)

#Student id, Student name, mail id, mobile no.	Student id, student name, mail id, mobile no.

#Feel free to add more columns the above one is just an example schema.
#Assume you are working in an Ed-tech company namely Great Learning where you will be inserting and modifying the details of the students in the Student details table. Every time the students change their details like their mobile number, You need to update their details in the student details table.  Here is one thing you should ensure whenever the new students' details come, you should also store them in the Student backup table so that if you modify the details in the student details table, you will be having the old details safely.
#You need not insert the records separately into both tables rather Create a trigger in such a way that It should insert the details into the Student back table when you insert the student details into the student table automatically.
create table student_details
(
Student_id smallint,
Student_name varchar(30),
mail_id varchar(20),
mobile_no integer
);

create table student_details_backup
(
action VARCHAR(255),
action_time   TIMESTAMP,
Student_id smallint,
Student_name varchar(30),
mail_id varchar(20),
mobile_no integer
);

DELIMITER $$
CREATE TRIGGER stud_backup_insert AFTER INSERT ON student_details
FOR EACH ROW
BEGIN
  INSERT INTO student_details_backup (action, action_time, Student_id, Student_name, mail_id, mobile_no)
  VALUES('insert', NOW(), NEW.Student_id, NEW.Student_name, NEW.mail_id, NEW.mobile_no);
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER stud_backup_update AFTER UPDATE ON student_details
FOR EACH ROW
BEGIN
  INSERT INTO student_details_backup (action, action_time, Student_id, Student_name, mail_id, mobile_no)
  VALUES('update', NOW(), NEW.Student_id, NEW.Student_name, NEW.mail_id, NEW.mobile_no);
END$$
DELIMITER ;


