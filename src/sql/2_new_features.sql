-- Final Project - Production

## Source of dataest is from link https://racing.hkjc.com/racing/information/English/racing/LocalResults.aspx

## Note that, please  connect to DB pjhkjc.db frist

#### Create new features ####

# 1.0 Jockey Performance Statistics (Winning percent of each jockey)
CREATE table jockey_stat as
SELECT w_jockey, ROUND(CAST( w_cnt as REAL) * 100  / CAST(t_cnt as REAL) ,2) as w_pct
FROM 
(select r_jockey w_jockey, count(*) as w_cnt from results where r_finish_order=1 group by 1),
(select r_jockey t_jockey, count(*) as t_cnt from results  group by 1)
WHERE w_jockey = t_jockey
ORDER BY 2 DESC;

# 1.1 Add new column in fact table RESULTS for handle jockey performance
alter table results add r_jockey_pct REAL;

# 1.2 Update column r_jockey_pct
update results set r_jockey_pct = (Select w_pct from jockey_stat where r_jockey = w_jockey)
WHERE exists (select * from jockey_stat i where i.w_jockey= r_jockey);


# 2.0 Trainer Performance Statistics (Winning percent of each trainer)
CREATE table trainer_stat as
SELECT w_trainer, ROUND(CAST( w_cnt as REAL) * 100  / CAST(t_cnt as REAL) ,2) as w_pct
FROM 
(select r_trainer w_trainer, count(*) as w_cnt from results where r_finish_order=1 group by 1),
(select r_trainer t_trainer, count(*) as t_cnt from results group by 1)
WHERE w_trainer = t_trainer
ORDER BY 2 DESC

# 2.1 Add new column in fact table RESULTS for handle trainer performance
alter table results add r_trainer_pct REAL;

# 2.2 Update column r_trainer_pct
update results set r_trainer_pct = (Select w_pct from trainer_stat where r_trainer = w_trainer)
WHERE exists (select * from trainer_stat i where i.w_trainer= r_trainer)


#### Handle non-numerical values ####

# 1.0 Handle track
   alter table results add r_ct integer;

   update results set r_ct = 110 WHERE r_course='HV' AND r_tract='A' ;
	update results set r_ct = 120 WHERE r_course='HV' AND r_tract='B' ;
	update results set r_ct = 130 WHERE r_course='HV' AND r_tract='C' ;
	update results set r_ct = 133 WHERE r_course='HV' AND r_tract='C3';
	update results set r_ct = 210 WHERE r_course='ST' AND r_tract='A' ;
	update results set r_ct = 213 WHERE r_course='ST' AND r_tract='A3';
	update results set r_ct = 220 WHERE r_course='ST' AND r_tract='B' ;
	update results set r_ct = 222 WHERE r_course='ST' AND r_tract='B2';
	update results set r_ct = 230 WHERE r_course='ST' AND r_tract='C' ;
	update results set r_ct = 233 WHERE r_course='ST' AND r_tract='C3';
	update results set r_ct = 300 WHERE r_course='ST' AND r_tract='D' ;

# 2.0 Change course into numeric 
   alter table results add r_course_val integer;
   update results set r_course_val = 1 WHERE r_course='HV';
   update results set r_course_val = 2 WHERE r_course='ST' AND r_tract !='D';
   update results set r_course_val = 3 WHERE r_course='ST' AND r_tract='D' ;

# 3.0 Handle horse's r_brand_no (ie A013 will cover 1013)
   alter table results add r_lot     TEXT;
   alter table results add r_lot_num TEXT;
   alter table results add r_lot_seq TEXT;
   update results set r_lot=substr(r_brand_no,1,1 );

   update results set r_lot_num = 1 where r_lot ='A' ;
   update results set r_lot_num = 2 where r_lot ='B' ;
   update results set r_lot_num = 3 where r_lot ='C' ;
   update results set r_lot_num = 4 where r_lot ='D' ;
   update results set r_lot_num = 5 where r_lot ='E' ;
   update results set r_lot_num = 6 where r_lot ='F' ;
   update results set r_lot_num = 16 where r_lot ='P' ;
   update results set r_lot_num = 19 where r_lot ='S' ;
   update results set r_lot_num = 20 where r_lot ='T' ;
   update results set r_lot_num = 21 where r_lot ='V' ;
   update results set r_lot_seq=r_lot_num||substr(r_brand_no,2,3);


#### Another new feature ####
# 1.0 Horse performance at same course and same distance
#     Count of finish order at 1st, 2nd, 3rd, 4th and after 4th 
create table fea_same_cd as
SELECT a.r_lot_seq tg_lot_seq, a.r_date tg_date, 
       SUM(CASE WHEN CAST(b.r_finish_order as integer) =1 THEN 1 ELSE 0 END) tg_same_cd_1,
       SUM(CASE WHEN CAST(b.r_finish_order as integer) =2 THEN 1 ELSE 0 END) tg_same_cd_2,
       SUM(CASE WHEN CAST(b.r_finish_order as integer) =3 THEN 1 ELSE 0 END) tg_same_cd_3,
       SUM(CASE WHEN CAST(b.r_finish_order as integer) =4 THEN 1 ELSE 0 END) tg_same_cd_4,
       SUM(CASE WHEN CAST(b.r_finish_order as integer) >4 THEN 1 ELSE 0 END) tg_same_cd_x
FROM results a , results b
where a.r_lot_seq    = b.r_lot_seq
AND   a.r_course_val = b.r_course_val
AND   a.r_distance   = b.r_distance
and   a.r_date > b.r_date
--AND   b.r_finish_order IN(1,2,3,4)
group by a.r_lot_seq, 2 
order by 2,1; 
# 1.1 Add new columns in table RESULTS
alter table results add r_same_cd_1 integer;
alter table results add r_same_cd_2 integer;
alter table results add r_same_cd_3 integer;
alter table results add r_same_cd_4 integer;
alter table results add r_same_cd_x integer;

# 1.2 Update column r_same_cd_1, r_same_cd_2, r_same_cd_3, r_same_cd_4, r_same_cd_x
update  results set (r_same_cd_1, r_same_cd_2, r_same_cd_3, r_same_cd_4, r_same_cd_x) =
       (SELECT tg_same_cd_1, tg_same_cd_2, tg_same_cd_3, tg_same_cd_4, tg_same_cd_x 
        FROM   fea_same_cd WHERE tg_lot_seq = r_lot_seq and tg_date= r_date)
WHERE   exists ( SELECT * FROM fea_same_cd i where i.tg_lot_seq = r_lot_seq and i.tg_date= r_date );

# 1.3 set to value 0, if there is no historical record found
UPDATE  results set (r_same_cd_1, r_same_cd_2, r_same_cd_3, r_same_cd_4, r_same_cd_x) =
(0,0,0,0,0) WHERE r_same_cd_x is null;

# Handle category to numeric
alter table results add r_sea_race_ind integer;

update  results set r_sea_race_ind = r_season||r_index;

# winning performance based on draw
alter table results add r_draw_val integer;

update results set r_draw_val = 
              (SELECT ds_D01_pct FROM DRAW_STAT WHERE ds_course = r_course 
                                  AND ds_tract =r_tract AND ds_distance = r_distance)
WHERE exists (SELECT * FROM DRAW_STAT i  WHERE i.ds_course = r_course 
                                    AND i.ds_tract =r_tract AND i.ds_distance = r_distance)
AND r_draw=1; 


update results set r_draw_val = 
              (SELECT ds_D02_pct FROM DRAW_STAT WHERE ds_course = r_course 
                                  AND ds_tract =r_tract AND ds_distance = r_distance)
WHERE exists (SELECT * FROM DRAW_STAT i  WHERE i.ds_course = r_course 
                                    AND i.ds_tract =r_tract AND i.ds_distance = r_distance)
AND r_draw=2;

update results set r_draw_val = 
              (SELECT ds_D03_pct FROM DRAW_STAT WHERE ds_course = r_course 
                                  AND ds_tract =r_tract AND ds_distance = r_distance)
WHERE exists (SELECT * FROM DRAW_STAT i  WHERE i.ds_course = r_course 
                                    AND i.ds_tract =r_tract AND i.ds_distance = r_distance)
AND r_draw=3;


update results set r_draw_val = 
              (SELECT ds_D04_pct FROM DRAW_STAT WHERE ds_course = r_course 
                                  AND ds_tract =r_tract AND ds_distance = r_distance)
WHERE exists (SELECT * FROM DRAW_STAT i  WHERE i.ds_course = r_course 
                                    AND i.ds_tract =r_tract AND i.ds_distance = r_distance)
AND r_draw=4;

update results set r_draw_val = 
              (SELECT ds_D05_pct FROM DRAW_STAT WHERE ds_course = r_course 
                                  AND ds_tract =r_tract AND ds_distance = r_distance)
WHERE exists (SELECT * FROM DRAW_STAT i  WHERE i.ds_course = r_course 
                                    AND i.ds_tract =r_tract AND i.ds_distance = r_distance)
AND r_draw=5;

update results set r_draw_val = 
              (SELECT ds_D06_pct FROM DRAW_STAT WHERE ds_course = r_course 
                                  AND ds_tract =r_tract AND ds_distance = r_distance)
WHERE exists (SELECT * FROM DRAW_STAT i  WHERE i.ds_course = r_course 
                                    AND i.ds_tract =r_tract AND i.ds_distance = r_distance)
AND r_draw=6;

update results set r_draw_val = 
              (SELECT ds_D07_pct FROM DRAW_STAT WHERE ds_course = r_course 
                                  AND ds_tract =r_tract AND ds_distance = r_distance)
WHERE exists (SELECT * FROM DRAW_STAT i  WHERE i.ds_course = r_course 
                                    AND i.ds_tract =r_tract AND i.ds_distance = r_distance)
AND r_draw=7;

update results set r_draw_val = 
              (SELECT ds_D08_pct FROM DRAW_STAT WHERE ds_course = r_course 
                                  AND ds_tract =r_tract AND ds_distance = r_distance)
WHERE exists (SELECT * FROM DRAW_STAT i  WHERE i.ds_course = r_course 
                                    AND i.ds_tract =r_tract AND i.ds_distance = r_distance)
AND r_draw=8;

update results set r_draw_val = 
              (SELECT ds_D09_pct FROM DRAW_STAT WHERE ds_course = r_course 
                                  AND ds_tract =r_tract AND ds_distance = r_distance)
WHERE exists (SELECT * FROM DRAW_STAT i  WHERE i.ds_course = r_course 
                                    AND i.ds_tract =r_tract AND i.ds_distance = r_distance)
AND r_draw=9;

update results set r_draw_val = 
              (SELECT ds_D10_pct FROM DRAW_STAT WHERE ds_course = r_course 
                                  AND ds_tract =r_tract AND ds_distance = r_distance)
WHERE exists (SELECT * FROM DRAW_STAT i  WHERE i.ds_course = r_course 
                                    AND i.ds_tract =r_tract AND i.ds_distance = r_distance)
AND r_draw=10;


update results set r_draw_val = 
              (SELECT ds_D11_pct FROM DRAW_STAT WHERE ds_course = r_course 
                                  AND ds_tract =r_tract AND ds_distance = r_distance)
WHERE exists (SELECT * FROM DRAW_STAT i  WHERE i.ds_course = r_course 
                                    AND i.ds_tract =r_tract AND i.ds_distance = r_distance)
AND r_draw=11;


update results set r_draw_val = 
              (SELECT ds_D12_pct FROM DRAW_STAT WHERE ds_course = r_course 
                                  AND ds_tract =r_tract AND ds_distance = r_distance)
WHERE exists (SELECT * FROM DRAW_STAT i  WHERE i.ds_course = r_course 
                                    AND i.ds_tract =r_tract AND i.ds_distance = r_distance)
AND r_draw=12;


update results set r_draw_val = 
              (SELECT ds_D13_pct FROM DRAW_STAT WHERE ds_course = r_course 
                                  AND ds_tract =r_tract AND ds_distance = r_distance)
WHERE exists (SELECT * FROM DRAW_STAT i  WHERE i.ds_course = r_course 
                                    AND i.ds_tract =r_tract AND i.ds_distance = r_distance)
AND r_draw=13;



update results set r_draw_val = 
              (SELECT ds_D14_pct FROM DRAW_STAT WHERE ds_course = r_course 
                                  AND ds_tract =r_tract AND ds_distance = r_distance)
WHERE exists (SELECT * FROM DRAW_STAT i  WHERE i.ds_course = r_course 
                                    AND i.ds_tract =r_tract AND i.ds_distance = r_distance)
AND r_draw=14;


# Change label (r_label) value to same at finish order instead of 0 (zero)
update results set r_label =2 where CAST(r_finish_order as integer) =2;
update results set r_label =3 where CAST(r_finish_order as integer) =3;
update results set r_label =4 where CAST(r_finish_order as integer) =4;
-- update results set r_label =5 where CAST(r_finish_order as integer) >=4;
update results set r_label =5 where CAST(r_finish_order as integer)  =5;
update results set r_label =6 where CAST(r_finish_order as integer)  =6;
update results set r_label =7 where CAST(r_finish_order as integer)  =7;
update results set r_label =8 where CAST(r_finish_order as integer)  =8;
update results set r_label =9 where CAST(r_finish_order as integer)  =9;
update results set r_label =10 where CAST(r_finish_order as integer) =10;
update results set r_label =11 where CAST(r_finish_order as integer) >=10;
update results set r_label =11 where CAST(r_finish_order as integer) =0;


#### Another two new features ####
# 1.0 Jockey and Horse performance 
create table fea_same_jh as
SELECT a.r_lot_seq tg_lot_seq, a.r_date tg_date, 
       SUM(CASE WHEN CAST(b.r_finish_order as integer) = 1 THEN 1 ELSE 0 END) tg_same_jh_1,
       SUM(CASE WHEN CAST(b.r_finish_order as integer) =2 THEN 1 ELSE 0 END) tg_same_jh_2,
       SUM(CASE WHEN CAST(b.r_finish_order as integer) =3 THEN 1 ELSE 0 END) tg_same_jh_3,
       SUM(CASE WHEN CAST(b.r_finish_order as integer) =4 THEN 1 ELSE 0 END) tg_same_jh_4,
       SUM(CASE WHEN CAST(b.r_finish_order as integer) >4 THEN 1 ELSE 0 END) tg_same_jh_x
FROM results a , results b
where a.r_lot_seq    = b.r_lot_seq
AND   a.r_jockey     = b.r_jockey
AND   a.r_brand_no   = b.r_brand_no
and   a.r_date > b.r_date
group by a.r_lot_seq, 2 
order by 2,1;

# 1.1 Add new columns in table RESULTS
alter table results add r_same_jh_1 integer;
alter table results add r_same_jh_2 integer;
alter table results add r_same_jh_3 integer;
alter table results add r_same_jh_4 integer;
alter table results add r_same_jh_x integer;

# 1.2 Update column r_same_jh_1, r_same_jh_2, r_same_jh_3, r_same_jh_4, r_same_jh_x
update  results set (r_same_jh_1, r_same_jh_2, r_same_jh_3, r_same_jh_4, r_same_jh_x) =
       (SELECT tg_same_jh_1, tg_same_jh_2, tg_same_jh_3, tg_same_jh_4, tg_same_jh_x 
        FROM   fea_same_jh WHERE tg_lot_seq = r_lot_seq and tg_date= r_date)
WHERE   exists ( SELECT * FROM fea_same_jh i where i.tg_lot_seq = r_lot_seq and i.tg_date= r_date );

# 1.3 set to value 0, if there is no historical record found
UPDATE  results set (r_same_jh_1, r_same_jh_2, r_same_jh_3, r_same_jh_4, r_same_jh_x) =
(0,0,0,0,0) WHERE r_same_jh_x is null;

# 2.0 Jockey and Horse performance 
create table fea_same_tj as
SELECT tg_trainer,  tg_jockey, tg_same_tj_1, tg_same_tj_2,tg_same_tj_3, 
       tg_same_tj_4, tg_same_tj_x, tg_same_tj_all, 
       ROUND(CAST(tg_same_tj_1 as real) * 100 / cast(tg_same_tj_all as REAL),2)  as tg_same_tj_1_pct,
       ROUND(CAST(tg_same_tj_2 as real) * 100 / cast(tg_same_tj_all as REAL),2)  as tg_same_tj_2_pct,
       ROUND(CAST(tg_same_tj_3 as real) * 100 / cast(tg_same_tj_all as REAL),2)  as tg_same_tj_3_pct,
       ROUND(CAST(tg_same_tj_4 as real) * 100 / cast(tg_same_tj_all as REAL),2)  as tg_same_tj_4_pct,
       ROUND(CAST(tg_same_tj_x as real) * 100 / cast(tg_same_tj_all as REAL),2)  as tg_same_tj_x_pct
FROM (
select a.r_trainer as tg_trainer, a.r_jockey as tg_jockey,
       SUM(CASE WHEN CAST(a.r_finish_order as integer)=1 THEN 1 ELSE 0 END) tg_same_tj_1,
       SUM(CASE WHEN CAST(a.r_finish_order as integer)=2 THEN 1 ELSE 0 END) tg_same_tj_2,
       SUM(CASE WHEN CAST(a.r_finish_order as integer)=3 THEN 1 ELSE 0 END) tg_same_tj_3,
       SUM(CASE WHEN CAST(a.r_finish_order as integer)=4 THEN 1 ELSE 0 END) tg_same_tj_4,
       SUM(CASE WHEN CAST(a.r_finish_order as integer) >4 THEN 1 ELSE 0 END) tg_same_tj_x,
       COUNT(*)   as tg_same_tj_all
FROM results a 
WHERE CAST(a.r_finish_order as integer) between 1 and 14
group by 1,2
order by 1,2);

# 2.1 Add new columns in table RESULTS
alter table results add r_same_tj_1 real;
alter table results add r_same_tj_2 real;
alter table results add r_same_tj_3 real;
alter table results add r_same_tj_4 real;
alter table results add r_same_tj_x real;

# 1.2 Update columns
update  results set (r_same_tj_1, r_same_tj_2, r_same_tj_3, r_same_tj_4, r_same_tj_x) =
       (SELECT tg_same_tj_1_pct, tg_same_tj_2_pct, tg_same_tj_3_pct, tg_same_tj_4_pct, tg_same_tj_x_pct 
        FROM   fea_same_tj WHERE tg_trainer = r_trainer and tg_jockey= r_jockey)
WHERE   exists ( SELECT * FROM fea_same_tj i where i.tg_trainer = r_trainer and i.tg_jockey= r_jockey );


