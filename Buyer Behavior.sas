%let file_root = /home/u64199816/sasuser.v94/;

libname buyers "&file_root/Consumer Buying Behavior";

/*     Module 1: Data Preparation and Cleaning    */

/*import CSV*/

/*PROC IMPORT OUT=buyers.shopbehave
    DATAFILE="/home/u64199816/sasuser.v94/Consumer Buying Behavior/shopping_behavior_updated.csv"
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
    GUESSINGROWS = 2000; 
RUN;*/

/* Remove Spaces from Variable Names, Clean Location Variable */

data buyers.shopbehave;
	set buyers.shopbehave;
	rename
	'Customer ID'n = Customer_ID
	'Item Purchased'n = Item_Purchased
	'Purchase Amount (USD)'n = Purchase_Amt
	'Review Rating'n = Review_Rating
	'Subscription Status'n = Subscript_Status
	'Shipping Type'n = Ship_type
	'Discount Applied'n = Discount
	'Promo Code Used'n = Promo_Code
	'Previous Purchases'n = Previous_Purchases
	'Payment Method'n = Pay_Method
	'Frequency of Purchases'n = Purchase_Freq
	;
run;


/* Check Missingness of Numeric Variables*/

Proc Means Data = buyers.shopbehave NMISS;
run;

/* Check Missingness and Valid Values of Character Variables*/
proc freq data=buyers.shopbehave;
   tables _character_ / missing;
run;

/* Check for duplicates by Customer_ID */

proc sql;
    create table dup_counts as
    select Customer_ID, count(*) as count
    from buyers.shopbehave
    group by Customer_ID
    having count(*) > 1;
quit;

/* Import Data on Median Household Income by State */

/*PROC IMPORT OUT=buyers.income
    DATAFILE="/home/u64199816/sasuser.v94/Consumer Buying Behavior/HDPulse_data_export.csv"
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
/*RUN;

/* Join Data sets to add state's Median Household Income */

data buyers.income;
    set buyers.income;
    temp = compress(translate('Value (Dollars)'n,"",","));
    State_Income_Rank = input('Rank Within US (of 52 states)'n, best12.);
    State_Median_Income = input(temp, best12.);
    drop temp
run;

proc sql;
	create table buyers.shopincome as
	select x.*, y.*
	 from buyers.shopbehave as x left join buyers.income(drop = FIPS) as y
	on x.Location = y.State;
quit;


/* Check to make sure the join worked for all states */

proc freq data = buyers.shopincome;
	tables Location*State;
run;

/*        Module 2: Customer Segmentation     */

/* Segment by Age */

data buyers.segment;
	set buyers.shopincome;
	select;
		when (Age < 18) AGE_SEG = "Under 18";
        when (Age >= 18 AND Age <= 25) AGE_SEG = "18-25";
        when (Age >= 26 AND Age <= 35) AGE_SEG = "26-35";
        when (Age >= 36 AND Age <= 45) AGE_SEG = "36-45";
        when (Age >= 46 AND Age <= 55) AGE_SEG = "46-55";
        when (Age >= 56 AND Age <= 65) AGE_SEG = "56-65";
        when (Age > 65) AGE_SEG = "Over 65";
        otherwise;
    end;
run;

/* Segment by State Median Income Ranking(Quartiles) */
data buyers.segment;
	set buyers.segment;
	select;
		when (State_Income_Rank <= 52 AND State_Income_Rank >= 40) STATE_INCOME_QRTL = "4";
		when (State_Income_Rank <= 39 AND State_Income_Rank >= 27) STATE_INCOME_QRTL = "3";
		when (State_Income_Rank <= 26 AND State_Income_Rank >= 14) STATE_INCOME_QRTL = "2";
		when (State_Income_Rank <= 13 AND State_Income_Rank >= 1) STATE_INCOME_QRTL = "1";
		otherwise STATE_INCOME_QRTL = "0";
	end;
run; 

/*  Customer Segment Tables */

ods excel file = "&file_root/Consumer Buying Behavior/Customer_Segment_Tables.xlsx" ;

ods excel options(sheet_name = "Table1");
title 'Gender and Age Segments';
proc freq data = buyers.segment;
	tables Gender*AGE_SEG;
run;

ods excel options(sheet_name = "Table2");
title 'State Income and Age Segments';
proc freq data = buyers.segment;
	tables STATE_INCOME_QRTL*AGE_SEG;
run;

ods excel options(sheet_name = "Table3");
title 'State Income and Gender';
proc freq data = buyers.segment;
	tables STATE_INCOME_QRTL*Gender ;
run;


ods excel close; 
title; 

/* Confirm Categorical Results Represent Underlying Distributions */

proc sgplot data=buyers.segment;
    histogram State_Median_Income / group=Gender transparency=0.5;
    density State_Median_Income / group=Gender type=normal;
run;

proc sgplot data=buyers.segment;
    histogram Age / group=Gender transparency=0.5;
    density Age / group=Gender type=normal;
run;

/* Results show that Male customer segment is larger, but is evenly distributed across age and high and low income states. 
Let's look at the buying behavior differences between male and female customers. */


ods excel file = "&file_root/Consumer Buying Behavior/Male and Female Purchase Patterns.xlsx" ;


ods excel options(sheet_name = "Table1");
title 'Items Purchased Across Gender Segments';
proc tabulate data=buyers.segment;
	class Item_Purchased Gender;
	table Item_Purchased, Gender * (N ROWPCTN);
run;

ods excel options(sheet_name = "Table2");
title 'Purchase Category Across Gender Segments';
proc tabulate data=buyers.segment;
	class Category Gender;
	table Category, Gender * (N ROWPCTN);
run;

ods excel options(sheet_name = "Table3");
title 'Amount Purchased by Gender';
proc tabulate data=buyers.segment;
	class Gender;
	var Purchase_Amt;
	table Purchase_Amt*Gender*(MEAN STD);
run;

ods excel options(sheet_name = "Table4");
title 'Frequency of Purchases by Gender';
proc tabulate data=buyers.segment;
	class Purchase_Freq Gender;
	table Purchase_Freq, Gender * (N ROWPCTN);
run;

ods excel options(sheet_name = "Table5");
title 'Number of Previous Purchases by Gender';
proc tabulate data=buyers.segment;
	class Gender;
	var Previous_Purchases;
	table Previous_Purchases*Gender*(MEAN STD);
run;

ods excel close; 
title; 

/* Because the variation in the metrics of consumer behavior do not differ
 disproportionately from the underlying population distribution, there does
 not appear to be significant differences in buying behavior across Genders */

/* Check for Seasonality in the Data */

proc sgplot data=buyers.segment;
    vbar Season;
run;

proc sgplot data=buyers.segment;
    vbar Category / group = Season;
run;

proc sgplot data=buyers.segment;
    vbar Item_Purchased / group = Season;
run;

/* There does not appear to be significant Seasonal Trends for Purchase Items or Category across Seasons */

