use dbms2_project;
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

select * from ipl_team_players
where player_id= 95;
select cast(substring('Pts-379.5 Mat-16 Wkt-17 Dot-137 4s-40 6s-23 Cat-1 Stmp-0',instr('Pts-379.5 Mat-16 Wkt-17 Dot-137 4s-40 6s-23 Cat-1 Stmp-0', 'wkt'),2) as unsigned int); 
