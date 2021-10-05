-- Extract statistical files

-- Jocky Stat --
-- Extract from table directly
SELECT * FROM JOCKEY_STAT;
-- Or
-- Extract by SQL
SELECT w_jockey, ROUND(CAST( w_cnt as REAL) * 100  / CAST(t_cnt as REAL) ,2) as w_pct
FROM (select r_jockey w_jockey, count(*) as w_cnt from results where r_finish_order=1 group by 1),
     (select r_jockey t_jockey, count(*) as t_cnt from results  group by 1)
WHERE w_jockey = t_jockey
ORDER BY 2 DESC;


-- Trainer Stat  --
-- Extract from table directly
SELECT * FROM TRAINER_STAT;
-- Or
-- Extract by SQL
SELECT w_trainer, ROUND(CAST( w_cnt as REAL) * 100  / CAST(t_cnt as REAL) ,2) as w_pct
FROM (select r_trainer w_trainer, count(*) as w_cnt from results where r_finish_order=1 group by 1),
     (select r_trainer t_trainer, count(*) as t_cnt from results group by 1)
WHERE w_trainer = t_trainer
ORDER BY 2 DESC;

-- Draw Stat --
SELECT * FROM DRAW_STAT;

