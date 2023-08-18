use test;

CREATE TABLE contacts(
id_guest varchar(255),
id_host varchar(255),
id_listing varchar(255),
ts_contact_at TIMESTAMP,
ts_reply_at TIMESTAMP,
ts_accepted_at TIMESTAMP,
ts_booking_at TIMESTAMP,
ds_checkin DATETIME,
ds_checkout DATETIME,
n_guests INT,
n_messages INT
);

CREATE TABLE searches (
ds DATE,
id_user	VARCHAR(255),
ds_checkin DATETIME,
ds_checkout DATETIME,
n_searches INT,
n_nights INT,
n_guests_min INT,
n_guests_max INT,
origin_country CHAR(2),
filter_price_min INT,
filter_price_max INT,
filter_room_types VARCHAR(255),
filter_neighborhoods VARCHAR(255)
);

SET GLOBAL local_infile=1;

load data local infile '/Users/rossurbina/Box Sync/Data Analytics Learning/Interview Test Prep Projects/Airbnb_sample_project/contacts.tsv'
into table contacts
ignore 1 rows;

load data local infile '/Users/rossurbina/Box Sync/Data Analytics Learning/Interview Test Prep Projects/Airbnb_sample_project/searches.tsv'
into table searches
ignore 1 rows;

SET SQL_SAFE_UPDATES = 0;

# TRANSFORM DATA - find the day of the week for checkin and checkout
ALTER TABLE searches
ADD dow_in VARCHAR(20);
ALTER TABLE searches
ADD dow_out VARCHAR(20);

UPDATE searches
SET dow_in = 
    CASE DAYOFWEEK(ds_checkin)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END;

UPDATE searches
SET dow_out = 
    CASE DAYOFWEEK(ds_checkout)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END;

# Make all 0000-00-00 values null
UPDATE searches SET ds_checkin = NULL WHERE CAST(ds_checkin AS CHAR(20)) = '0000-00-00 00:00:00';
UPDATE searches SET ds_checkout = NULL WHERE CAST(ds_checkout AS CHAR(20)) = '0000-00-00 00:00:00';

# NOTE: the searches table contains values for the user and host, so I'm creating a new table for only the user values
CREATE TABLE guest_searches AS (
WITH guest AS (
	SELECT id_guest
	FROM contacts
)
Select *
FROM searches
LEFT JOIN guest
ON searches.id_user = guest.id_guest
WHERE guest.id_guest IS NOT NULL);

# be able to group by on strings
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

# DATA ANALYSIS

# DAY OF THE WEEK - what are the most popular days of the week to book? 
SELECT dow_in,
	COUNT(*) AS count
FROM guest_searches
GROUP BY 1
ORDER BY 2 DESC;
        
# NIGHTS - what number of nights do guests search the most for?
SELECT n_nights,
count(*)
FROM guest_searches
WHERE n_nights > 0
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;

# NUMBER OF GUESTS (min and max) - how many guests do users search for? 
WITH max AS (
	SELECT n_guests_max AS n_guests,
	count(*) AS count_max
	FROM guest_searches
	GROUP BY 1
	ORDER BY 1
),
min AS (
	SELECT n_guests_min AS n_guests,
	count(*) AS count_min
	FROM guest_searches
	GROUP BY 1
	ORDER BY 1
)
SELECT max.n_guests,
	count_min,
    count_max
FROM max
LEFT JOIN min
ON min.n_guests = max.n_guests;

# PRICE - segment people into various groups for pricing based on the max price they set. Assume all currency is in EUR, since we're looking at Dublin
WITH price_group AS (
	SELECT id_user,
		CASE
			WHEN filter_price_max = 0 THEN 'no_max_filter'
			WHEN filter_price_max BETWEEN 1 AND 100 THEN '1-100'
			WHEN filter_price_max BETWEEN 101 AND 200 THEN '101-200'
			WHEN filter_price_max BETWEEN 201 AND 300 THEN '201-300'
			WHEN filter_price_max BETWEEN 301 AND 400 THEN '301-400'
			WHEN filter_price_max BETWEEN 401 AND 500 THEN '401-500'
			WHEN filter_price_max > 500 THEN '500+'
		END AS price_group
	FROM guest_searches
)
SELECT price_group,
count(*)
FROM price_group
GROUP BY 1
ORDER BY 2 DESC;

# MINIMUM PRICE - no analysis to be done here since the amount of people who put a minimum amount is insignificant
SELECT filter_price_min,
count(*)
FROM guest_searches
GROUP BY 1
ORDER BY 2 DESC;

# FILTERS - discover which filters are most searched for
WITH written_filter AS (
	WITH home_filters AS ( 
		SELECT id_user, # these case arguments are meant to create 3 new columns from the filter_room_types column to say yes / no to if it has it
			CASE WHEN filter_room_types LIKE '%Entire home/apt%' THEN 1 ELSE 0 END AS entire_home_apt,
			CASE WHEN filter_room_types LIKE '%Private room%' THEN 1 ELSE 0 END AS private_room,
			CASE WHEN filter_room_types LIKE '%Shared room%' THEN 1 ELSE 0 END AS shared_room
		FROM guest_searches
	)
	SELECT *,
		CASE # there are cases where a row has multiple filters (like entire home and private room), so need to create categories for them
			WHEN entire_home_apt = 1 AND private_room = 1 AND shared_room = 1 THEN 'all_filters' # note that all filters must go first, then ones with 2 filters, then 1 filter
			WHEN entire_home_apt = 1 AND private_room = 1 THEN 'entire_home_or_private'
			WHEN private_room = 1 AND shared_room = 1 THEN 'private_or_shared'
			WHEN entire_home_apt = 1 AND shared_room = 1 THEN 'entire_or_shared'
			WHEN entire_home_apt = 1 THEN 'entire_home_apt'
			WHEN private_room = 1 THEN 'private_room'
			WHEN shared_room = 1 THEN 'shared_room'
		END AS filter_name
	FROM home_filters
)
SELECT filter_name, # after creating written_filter, group the total count by each filter
count(*) AS total_num
FROM written_filter
GROUP BY 1
ORDER BY 2 DESC;

# NEIGHBORHOODS - discover which neighborhoods are the most requested
SELECT
    filter AS searched_filter,
    COUNT(*) AS search_count
FROM (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(filter_neighborhoods, ',', numbers.n), ',', -1) AS filter
    FROM (
        SELECT 1 AS n UNION ALL
        SELECT 2 UNION ALL
        SELECT 3 UNION ALL
        SELECT 4 UNION ALL
        SELECT 5 UNION ALL
        SELECT 6
    ) AS numbers
    JOIN guest_searches
    ON CHAR_LENGTH(filter_neighborhoods)
       -CHAR_LENGTH(REPLACE(filter_neighborhoods, ',', '')) >= numbers.n - 1
) AS filter_values
GROUP BY searched_filter
ORDER BY search_count DESC
LIMIT 6;

# -------------------- CONTACTS DATASET ANALYSIS --------------------

# CLEAN DATA - turn all 0000-00-00 values into null values, indicating that this step wasn't completed
SET SQL_SAFE_UPDATES = 0;
UPDATE contacts SET ts_contact_at = NULL WHERE CAST(ts_contact_at AS CHAR(20)) = '0000-00-00 00:00:00';
UPDATE contacts SET ts_reply_at = NULL WHERE CAST(ts_reply_at AS CHAR(20)) = '0000-00-00 00:00:00';
UPDATE contacts SET ts_accepted_at = NULL WHERE CAST(ts_accepted_at AS CHAR(20)) = '0000-00-00 00:00:00';
UPDATE contacts SET ts_booking_at = NULL WHERE CAST(ts_booking_at AS CHAR(20)) = '0000-00-00 00:00:00';

# TRANSFORM DATA - find the number of nights by subtracting the checkout - checkin date
ALTER TABLE contacts
ADD COLUMN n_nights INT;

UPDATE contacts
SET n_nights = DATEDIFF(ds_checkout, ds_checkin);

# TRANSFORM DATA - find the day of the week for checkin and checkout
ALTER TABLE contacts
ADD dow_in VARCHAR(20);
ALTER TABLE contacts
ADD dow_out VARCHAR(20);

UPDATE contacts
SET dow_in = 
    CASE DAYOFWEEK(ds_checkin)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END;

UPDATE contacts
SET dow_out = 
    CASE DAYOFWEEK(ds_checkout)
        WHEN 1 THEN 'Sunday'
        WHEN 2 THEN 'Monday'
        WHEN 3 THEN 'Tuesday'
        WHEN 4 THEN 'Wednesday'
        WHEN 5 THEN 'Thursday'
        WHEN 6 THEN 'Friday'
        WHEN 7 THEN 'Saturday'
    END;

# TRANSFORM N_Messages to make it easier to group by. Note that we're keeping it to a string value since we're grouping them together
ALTER TABLE contacts
ADD COLUMN n_messages_group VARCHAR(10);

UPDATE contacts
SET n_messages_group = 
	CASE
		WHEN n_messages BETWEEN 11 AND 20 then '11-20'
        WHEN n_messages BETWEEN 21 AND 30 then '21-30'
        WHEN n_messages BETWEEN 31 AND 50 then '31-50'
        WHEN n_messages > 51 THEN '51+'
        ELSE n_messages
	END;

# TRANSFORM N_Nights to make it easier to group by. Note that we're keeping it to a string value since we're grouping them together
ALTER TABLE contacts
ADD COLUMN n_nights_group VARCHAR(10);

UPDATE contacts
SET n_nights_group = 
	CASE
		WHEN n_nights BETWEEN 11 AND 20 then '11-20'
        WHEN n_nights BETWEEN 21 AND 30 then '21-30'
        WHEN n_nights BETWEEN 31 AND 50 then '31-50'
        WHEN n_nights > 51 THEN '51+'
        ELSE n_nights
	END;

# TRANSFORM DATA - turn all dates into 1 when it's not null to make our analysis simpler. Note that the difference in response time could impact the success rate, which can be explored
CREATE TABLE simple_contacts AS (
SELECT id_guest, id_host, id_listing, n_guests, n_messages_group, n_nights_group, dow_in, dow_out,
	CASE WHEN ts_contact_at IS NOT NULL THEN 1 ELSE 0 END AS contacted,
    CASE WHEN ts_reply_at IS NOT NULL THEN 1 ELSE 0 END AS replied,
	CASE WHEN ts_accepted_at IS NOT NULL THEN 1 ELSE 0 END AS accepted,
	CASE WHEN ts_booking_at IS NOT NULL THEN 1 ELSE 0 END AS booked
FROM contacts);

# ANALYZE - for each applicable attribute (n_guests, n_messages, n_nights), what do hosts accept the most?

# GUESTS
SELECT n_guests,
	count(*),
	sum(replied) / sum(contacted) AS replied_conv,
	sum(accepted) / sum(contacted) AS accepted_conv, # accepted_conv is what we're looking for the host to say yes
    sum(booked) / sum(contacted) AS booked_conv
FROM simple_contacts
GROUP BY 1
ORDER BY 4 DESC;

# MESSAGES
SELECT n_messages_group,
	count(*),
	sum(replied) / sum(contacted) AS replied_conv,
	sum(accepted) / sum(contacted) AS accepted_conv, # accepted_conv is what we're looking for the host to say yes
    sum(booked) / sum(contacted) AS booked_conv
FROM simple_contacts
GROUP BY 1
ORDER BY 4 DESC;

# NIGHTS
SELECT n_nights_group,
	count(*),
	sum(replied) / sum(contacted) AS replied_conv,
	sum(accepted) / sum(contacted) AS accepted_conv, # accepted_conv is what we're looking for the host to say yes
    sum(booked) / sum(contacted) AS booked_conv
FROM simple_contacts
GROUP BY 1
ORDER BY 4 DESC;

# DAYS OF THE WEEK
SELECT dow_in,
	count(*),
	sum(replied) / sum(contacted) AS replied_conv,
	sum(accepted) / sum(contacted) AS accepted_conv, # accepted_conv is what we're looking for the host to say yes
    sum(booked) / sum(contacted) AS booked_conv
FROM simple_contacts
GROUP BY 1
ORDER BY 4 DESC;

# Find the number of hosts & total bookings per capacity (assuming that the max # of people booked at a host's location is the max capacity, which won't always hold true)
WITH host_capacity AS (
	SELECT id_host,
	max(n_guests) AS capacity,
	COUNT(*) AS num_booked
	FROM contacts
	GROUP BY id_host
)
SELECT capacity,
count(*) AS num_hosts,
sum(num_booked) as total_booked
FROM host_capacity
GROUP BY 1
ORDER BY 2 DESC;