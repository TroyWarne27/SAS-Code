%let file_root = /home/u64199816/sasuser.v94/BRFSS Data;

libname intrmd "&file_root/Intermediate Datasets";
libname output "&file_root/Output";
libname tbles	"&file_root/Output/Tables";
libname inputd	"&file_root/Input Data";

/* import CSV files */

/*%macro import_loop(start=2, end=5);

    %do i = &start %to &end;

        proc import datafile="/home/u64199816/sasuser.v94/BRFSS Data/Input Data/201&i..csv"
            out=inputd.year201&i
            dbms=csv
            replace;
            getnames=yes;
            GUESSINGROWS = 1000; 
        run;

    %end;

%mend;

%import_loop(start=2, end=5);

/* Loop to stack, not enough memory in current SAS enviroment */

/*%macro stack_loop;

		data inputd.BRFSSstack;
			set 
			%do i= 2 %to 5;
	        	inputd.year201&i (keep =_state IMonth IYear dispcode)
	    	%end;
	    	;
   		run;
	
%mend;

%stack_loop; */

/* Will only use 2015 data due to memory limitations */

proc contents data = inputd.year2015;

data inputd.BRFSS2015;
set inputd.year2015;
keep _state IMonth IYear Dispcode GenHlth HlthPln1 PersDoc2 MedCost MENTHLTH PHYSHLTH
ADDEPEV2 SEX MARITAL EDUCA EMPLOY1 CHILDREN INCOME2 QLACTLM2 SMOKE100 STOPSMK2 
ALCDAY5 EXERANY2 QLSTRES2 QLHLTH2 SCNTMEL1 SCNTMNY1 SCNTWRK1 SXORIENT EMTSUPRT _BMI5CAT
 _EDUCAG _PACAT1 _AGE80;
run;

/* Check Missingness of Numeric Variables*/

Proc Means Data = inputd.BRFSS2015 NMISS;
run;

/* Check Missingness and Valid Values of Character Variables*/
proc freq data=inputd.BRFSS2015 ;
   tables _character_ / missing;
run;

/* Drop Variables with high missingness */
data inputd.BRFSS2015;
set inputd.year2015;
drop SCNTMEL1 SCNTMNY1 SCNTWRK1 STOPSMK2;
run;

/* Clean Month and Year Variable */
data inputd.BRFSS2015;
	set inputd.brfss2015; 
	Year = substr(IYEAR,3,4);
	Month = substr(IMONTH,3,2);
	drop IYEAR IMONTH;
run;

proc freq data=inputd.BRFSS2015 ;
   tables Month*Year;
run;

/* Observe Distribution of Key Variables */

/* Candidate for Dependent Variable: Now thinking about your mental health, which includes stress, depression, and problems with emotions, for how many
days during the past 30 days was your mental health not good? */

/* observe distribution of values for population that responded 1 or greater days*/

proc sgplot data = inputd.BRFSS2015;
	where MENTHLTH not in (0, 88, 77, 99);
	histogram MENTHLTH / transparency= .5;
run;
	
/* Candidate for Dependent Variable: Now thinking about your physical health, which includes physical illness and injury, for how many days during the past
30 days was your physical health not good? */

/* observe distribution of values for population that responded 1 or greater days*/

proc sgplot data = inputd.BRFSS2015;
	where PHYSHLTH not in (0, 88, 77, 99);
	histogram PHYSHLTH / transparency= .5;
run;

/* Create Categorical Variables for Mental Health, Physical Health Days, and clean history of depression variable */

proc sql; 
	create table intrmd.BRFSS2015_clean as
	select *,
		case 
			when MENTHLTH between 21 and 30 then 1
			when MENTHLTH between 11 and 20 then 2
			when MENTHLTH between 1 and 10 then 3
			when MENTHLTH = 88 then 4
			else . 
		end as MentalHLTH,
	
		case 
			when PHYSHLTH between 21 and 30 then 1
			when PHYSHLTH between 11 and 20 then 2
			when PHYSHLTH between 1 and 10 then 3
			when PHYSHLTH = 88 then 4
			else . 
		end as PhysicalHLTH,
		
		case 
			when ADDEPEV2 in(7,9) then .
			else ADDEPEV2
		end as DepressHIST
		
			
	from inputd.BRFSS2015;
	
quit; 

proc freq data=intrmd.BRFSS2015_clean ;
   tables PhysicalHLTH*MentalHLTH;
run;

proc corr data=intrmd.BRFSS2015_clean spearman;
  var MentalHLTH PhysicalHLTH;
run;

proc freq data=intrmd.BRFSS2015_clean ;
   tables DepressHIST*MentalHLTH;
run;

proc corr data=intrmd.BRFSS2015_clean spearman;
  var MentalHLTH DepressHIST;
run;

/* Test Demographic and Context Variables for Correlation */

proc sql;
	create table intrmd.BRFSS2015_clean as
	select *,
		case when EMPLOY1 in(8,3,4,7) then 1
		case when EMPLOY1 in (5,6) then 2
		case when EMPLOY1 in (1,2) then 3
		else .
	end as EMPLOYSTATUS

from intrmd.BRFSS2015_clean;

quit; 
