#The average amount of duration (in minutes) per month on 2014 - 2017
SELECT
    FORMAT_DATETIME('%Y-%m (%B)', start_date) AS month,
    ROUND(AVG(duration_sec/60)) AS average_in_minutes
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
WHERE start_date BETWEEN '2014-01-01' AND '2018-01-01'
GROUP BY month
ORDER BY month;


#Total trips and total number of unique bikes grouped by region name on 2014 - 2017
SELECT
    r.name AS region_name,
    COUNT(t.trip_id) AS total_trips,
    COUNT(DISTINCT t.bike_number) AS total_bikes
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
JOIN (
    SELECT si.station_id, ri.name
    FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS si
    JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` AS ri
        ON si.region_id = ri.region_id
        ) AS r
    ON t.start_station_id = r.station_id
WHERE t.start_date BETWEEN '2014-01-01' AND '2018-01-01'
GROUP BY 1
ORDER BY 1;


#The youngest and oldest age of the members, for each gender from this year (2022)
WITH CTE AS
(
    SELECT 
        member_gender,
        MIN(member_birth_year) AS oldest,
        MAX(member_birth_year) AS youngest
    FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips`
    WHERE member_gender IN ('Female', 'Male')
    GROUP BY member_gender
)
SELECT
    member_gender,
    2022-oldest AS oldest_age,
    2022-youngest AS youngest_age
FROM CTE;


#The latest departure trip in each region on 2014 - 2017
WITH CTE AS
(
SELECT
    ri.name AS region_name,
    t.trip_id,
    t.duration_sec,
    t.start_date,
    t.start_station_name,
    t.member_gender,
    ROW_NUMBER() OVER (PARTITION BY ri.name ORDER BY t.start_date) AS row_numbers
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS si
    JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` AS ri
        ON si.region_id = ri.region_id
    JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
        ON t.start_station_id = si.station_id
WHERE 
    t.start_date BETWEEN '2014-01-01' AND '2018-01-01'
    AND t.member_gender IN ('Female', 'Male')
ORDER BY region_name, t.start_date
),
CTE2 AS
(
SELECT 
    region_name,
    MAX(row_numbers) as latest_trip
FROM CTE
GROUP BY 1
)
SELECT 
    a.trip_id,
    a.duration_sec,
    a.start_date,
    a.start_station_name,
    a.member_gender,
    a.region_name
FROM CTE AS a
JOIN CTE2 AS b
    ON a.region_name = b.region_name
    AND a.row_numbers = b.latest_trip
ORDER BY a.region_name;


#Total trips in each region, breakdown by date on November 2017 until December 2017
SELECT
    DATE(DATETIME_TRUNC(t.start_date, DAY)) AS start_dates,
    ri.name AS region_name,
    COUNT(t.trip_id) AS total_trips
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS si
    JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` AS ri
        ON si.region_id = ri.region_id
    JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
        ON t.start_station_id = si.station_id
WHERE 
    t.start_date BETWEEN '2017-11-01' AND '2018-01-01'
GROUP BY 1, 2
ORDER BY 1, 2;

#Monthly growth of trips in percentage from San Francisco region.
WITH CTE AS
(
SELECT 
    FORMAT_DATETIME('%Y-%m (%B)', t.start_date) as Month,
    ri.name AS Region,
    COUNT(t.trip_id) AS total_trips
FROM `bigquery-public-data.san_francisco_bikeshare.bikeshare_station_info` AS si
    JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_regions` AS ri
        ON si.region_id = ri.region_id
    JOIN `bigquery-public-data.san_francisco_bikeshare.bikeshare_trips` AS t
        ON t.start_station_id = si.station_id
WHERE 
    ri.name = 'San Francisco'
    AND t.start_date BETWEEN '2014-01-01' AND '2018-01-01'
GROUP BY Region, Month
ORDER BY Month
)
SELECT 
    Month,
    Region,
    total_trips,
    ROUND(((total_trips - LAG(total_trips, 1) OVER (ORDER BY Month)) / LAG(total_trips, 1) OVER (ORDER BY Month))*100,2) || '%' AS Growth
FROM CTE
ORDER BY Month DESC;