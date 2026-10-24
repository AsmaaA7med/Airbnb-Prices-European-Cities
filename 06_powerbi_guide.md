# Power BI Dashboard Guide

## 1. Connect
Get Data > SQL Server > server `localhost`, database `AirbnbDW` > Import mode.
Load: Dim_City, Dim_DayType, Dim_RoomType, Dim_Host, Fact_Listing_Price, Fact_Scraped_Listing.

## 2. Model view (relationships, all one-to-many, single direction from Dim to Fact)
- Dim_City[city_key] -> Fact_Listing_Price[city_key]
- Dim_City[city_key] -> Fact_Scraped_Listing[city_key]
- Dim_DayType[daytype_key] -> Fact_Listing_Price[daytype_key]
- Dim_RoomType[room_key] -> Fact_Listing_Price[room_key]
- Dim_RoomType[room_key] -> Fact_Scraped_Listing[room_key]
- Dim_Host[host_key] -> Fact_Listing_Price[host_key]

Do NOT relate the two fact tables to each other. They meet only through Dim_City.

## 3. DAX measures
```
Avg Price = AVERAGE(Fact_Listing_Price[price])
Total Listings = COUNTROWS(Fact_Listing_Price)
Avg Satisfaction = AVERAGE(Fact_Listing_Price[guest_satisfaction])
Avg Cleanliness = AVERAGE(Fact_Listing_Price[cleanliness_rating])
Avg Distance to Center = AVERAGE(Fact_Listing_Price[dist_center])
Price per Bedroom = DIVIDE(SUM(Fact_Listing_Price[price]), SUM(Fact_Listing_Price[bedrooms]))
Price per Guest = DIVIDE(SUM(Fact_Listing_Price[price]), SUM(Fact_Listing_Price[person_capacity]))
Weekend Premium % =
VAR wk = CALCULATE([Avg Price], Dim_DayType[day_type] = "Weekday")
VAR we = CALCULATE([Avg Price], Dim_DayType[day_type] = "Weekend")
RETURN DIVIDE(we - wk, wk)
Superhost Share = DIVIDE(CALCULATE(COUNTROWS(Fact_Listing_Price), Dim_Host[is_superhost] = TRUE()), [Total Listings])

Scraped Avg Price = AVERAGE(Fact_Scraped_Listing[price])
Scraped Avg Rating = AVERAGE(Fact_Scraped_Listing[rating])
Scraped Listings = COUNTROWS(Fact_Scraped_Listing)
Guest Favorite % = DIVIDE(CALCULATE(COUNTROWS(Fact_Scraped_Listing), Fact_Scraped_Listing[is_guest_favorite] = TRUE()), [Scraped Listings])
Scraped Superhost % = DIVIDE(CALCULATE(COUNTROWS(Fact_Scraped_Listing), Fact_Scraped_Listing[is_superhost] = TRUE()), [Scraped Listings])
Avg Price 2BR Original = CALCULATE([Avg Price], Fact_Listing_Price[bedrooms] = 2, Dim_RoomType[room_type] = "Entire home/apt")
```

## 4. Pages
Page 1 - Overview: KPI cards (Total Listings, Avg Price, Avg Satisfaction, Weekend Premium %), bar chart of Avg Price by city, map using lat/lng sized by price, slicers for City, Day Type, Room Type.

Page 2 - Price drivers: scatter Price vs dist_center, scatter Price vs guest_satisfaction, column chart Avg Price by person_capacity, matrix City x Day Type with Avg Price.

Page 3 - Hosts: Superhost vs non-Superhost average price and satisfaction, Multi/Biz hosts share by city.

Page 4 - Scraped Airbnb features: Scraped Avg Price, Scraped Avg Rating, Guest Favorite %, Superhost % by city; clustered bar comparing Avg Price 2BR Original vs Scraped Avg Price per city (this is the only valid comparison between the two facts, at city level).

Page 5 - Data journey: a text/shape page summarizing CSV merge -> Selenium scraping -> cleaning -> SQL star schema -> Power BI, with a picture of the model view.
