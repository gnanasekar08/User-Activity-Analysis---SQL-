--- SQL Case study based on User Activity Analysis

select * from users
select * from logins 

--1. Which users did not log in during the past 5 months?

select distinct USER_id from logins where USER_id not in 
( select USER_ID
from logins
where login_timestamp > DATEADD(MONTH, -5, GETDATE())
)

--2. For the business units quarterly analysis, calculate how many users and how many sessions were at each quarter
-- order by quarter from newest to oldest?
-- Return first day of the quarter, user_count, session_count 

select Datetrunc(quarter, min(login_timestamp) ) as first_quarter_date, count(*) as session_count,
count(distinct user_id) as user_count
from logins
group by Datepart(quarter, login_timestamp)


--3. Which users logged in during January 2024 but did not log in during November 2023? Return only user_id

select distinct user_id from logins
where login_timestamp between '2024-01-01' and '2024-01-31'
and user_id not in (
select user_id from logins 
where login_timestamp between '2023-11-01' and '2023-11-30'
)

-- 4. What is the percentage change in sessions from the last quarter?
-- Add to the query from 2 the percentage change in sessions from last quarter
-- Return first day of the quarter, session_count, session_count_previous, session_percentage_change

With cte as (
select Datetrunc(quarter, min(login_timestamp) ) as first_quarter_date, count(*) as session_count
, count(distinct user_id) as user_count
from logins
group by Datepart(quarter, login_timestamp)
)
select *
, Coalesce (lag(session_count,1) over(order by first_quarter_date), 0) as previous_session_count
, Coalesce ((session_count - (lag(session_count,1) over(order by first_quarter_date))) *100.0 /(lag(session_count,1) over(order by first_quarter_date)), 0) as session_percentage_change
from cte;


-- 5. Which user had the highest session score each day?
-- Display the user that had the highest score (max) for each day? 
-- Return , date, username, score

with CTE as (
select user_id, cast(login_timestamp as date) as login_date
, SUM(session_score) as score
from logins
group by user_id, cast(login_timestamp as date)
)
select * from (
select *, ROW_NUMBER() over ( partition by login_date order by score desc) as rn
from cte) a
where rn = 1;


-- 6. Which users have had a session every single day since their first login?

select user_id,min(cast(login_timestamp as date)) as first_login
,DATEDIFF(day, Min(cast(login_timestamp as date)), GETDATE())+1 as no_of_login_days_required
, COUNT(distinct cast(login_timestamp as date)) as no_of_login_days
from logins 
group by user_id
having  DATEDIFF(day, Min(cast(login_timestamp as date)), GETDATE())+1 = COUNT(distinct cast(login_timestamp as date))
order by user_id


-- 7. On what dates were there no logins at all?
-- Min date = 2023-07-15 

with cte as(
select cast(min(login_timestamp) as date) as first_date, cast(getdate() as date) as last_date
from logins
union all
select DATEADD(day, 1, first_date) as first_date, last_date from CTE
where first_date < last_date
)
select first_date from CTE
where first_date not in 
(select distinct cast(login_timestamp as date ) from logins)

option(maxrecursion 500)


