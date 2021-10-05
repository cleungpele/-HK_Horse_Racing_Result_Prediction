-- Final Project - Production

# results.csv contains three past three seasons (2018-2019, 2019-2020 and 2020-2021) (for training and validation)
# and current season result (season 2021-2022 for month in Sep and Oct 2021) (for testing)
# Noter that, data in season 2021-2022 will be ignored during create statistical files 
# and current season data as of Oct 2, 2021 horse racing results.
# Source of data is from link https://racing.hkjc.com/racing/information/English/racing/LocalResults.aspx

import results.csv and named as table RESULTS into DB. 

-- command at below: 

sqlite3
.open pjhkjc.db
.mode csv
.import /...../results.csv results

