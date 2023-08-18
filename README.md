# Analysis on Searches & Bookings for Airbnb
This data is search and bookings data for Airbnb in Dublin

## Purpose
I found sample data on Airbnb’s searches and bookings data for Dublin, so I wanted to analyze it and answer questions on various topics. This type of analysis could help a company like Airbnb 1) understand what their customers are searching for and 2) what gives the highest percentage likelihood of converting initial requests into bookings. 

## Data Tools Used

I used MySQL to clean, transform, and analyze the data on MySQL Workbench. I then exported csv files from MySQL Workbench into Tableau, where I visualized the data. Here is the link to the [SQL file](https://github.com/rossurbina/Airbnb_SQL/blob/main/Airbnb_Data_Analysis.sql) and the [Tableau Dashboard](https://public.tableau.com/app/profile/ross.urbina/viz/AirbnbSearchesandBookings-SampleData/AirbnbSearchesBookingsData)

# Insights & Observations

## Customer Search Data

• **Host capacity:** The most amount of searches received by host capacity was 1 person with 44% of searches, and the second highest was 2 people with 33%. Only 7% of searches are for more than 4 people. This leads me to believe that most people use Airbnb for family or small group bookings, as opposed to large gatherings. 

•	**Day of week:** Not surprising, the two most popular days for guests to search are Friday and Saturday with 46% of the total searches, excluding 6,014 searches that had no dates (assume these searches were more casual searchers since they didn’t put in dates).

**•	Price:** 51% of searches did not have any max price filter. This could mean that people with those searches aren’t money conscious, but I think it’s more likely that most of them are either casually searching or sorted through pricing later. Out of the other 49% of searches, the top two categories were €1 - €100 with 38% and €101 - €200 with 28%. The third most popular search category is €500+ with 15%. This shows that the vast majority of searchers look for the cheapest or cheap options, but there is a sizable group searching for the most expensive properties. 

•	**Property type filters (entire home, private room, or shared):** 52% of searches have no filter on the type of property. Out of the other 48% of searches, entire homes were the most desirable with 49%, private rooms were the next most desirable with 24%, and entire homes or private rooms were third with 21%. All other searches were a combo with shared rooms

## Bookings Data (Customer & Host Communication)

Based on all message chains between a customer and a host, 93% of hosts responded to the first message, 47% of hosts accepted the request, and 28% of guests booked the place. There was not too much variance in the percentage of bookings based on the # of guests, # of nights, or day of week that the guest reached out about. However, we can draw small conclusions from the data: 

•	**# of Guests:** 1, 2, and 5 guests had the highest conversions with 29-30%. However, 1 and 2 by far had the most initial messages with 71% of the total. 

•	**# of Nights:** 1, 2, 3, and 5 nights all had the highest percentage of booking conversion ranging between 30-32%. After 10 nights, the percentage acceptance rate dramatically dropped to 13% or below for categories after 10 nights. Note that 9 nights had a 44% conversion rate, but I didn’t consider it in conclusion since it only had 0.4% of the results and therefore wasn’t a good sample size.

•	**Day of week:** Friday had the highest convention with 32% and Saturday had the lowest with 23%

## Cleaning & Transforming the Data with SQL

•	Created tables and loaded data into the tables

•	Added in columns for day of week

•	Updated '0000-00-00 00:00:00' values to null

•	The initial searches table contained values for the user and host, so I created a new guest_searches for only the guest searches to focus the analysis more

•	The filters for host type and neighborhoods were written text in one column, so I created new column categories for better analysis / visualization 

•	Ran various statements to select the data I wanted for analysis

•	Made groupings for number of messages and number of nights

## Data Visualization (Tableau)

•	Used Tableau to generate various charts for both the searches and bookings data. Here is the [Tableau Dashboard]([url](https://public.tableau.com/app/profile/ross.urbina/viz/AirbnbSearchesandBookings-SampleData/AirbnbSearchesBookingsData)https://public.tableau.com/app/profile/ross.urbina/viz/AirbnbSearchesandBookings-SampleData/AirbnbSearchesBookingsData). 
