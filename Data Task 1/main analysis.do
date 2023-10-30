// Data Task for Chicago Booth
// Oct. 19, 2023
global path "C:\Users\haoliang hu\Desktop\Code Task\Noel-Zwick Data task"
global D    "$path\data"      //data file
global Out  "$path\out"       //result: graph and table
cd "$D"                       //set current working directory
set scheme cleanplots, perm

/*
First I will import the csv file, check the data, then I use the dataset
provided to calculate the weighted median wealth and detect the trends of wealth for different races. Once I've done that, I plot the graphs we need and calculate the change of housing_wealth and nom_housing_wealth by the years.
*/

* Q1
* Load the dataset
import delimited "RA_21_22.csv",clear

* Calculate wealth as assets minus debt
gen wealth = asset_total - debt_total

* Calculate weighted median wealth by year, race, and education
gen weighted_median_wealth=.

levelsof year, local(time)
levelsof race, local(color)
levelsof education, local(school)
// use aweight to calculate weighted median wealth
quietly foreach i of local time{
	quietly foreach j of local color{
		quietly foreach k of local school{
			summarize wealth [aweight=weight] if year ==`i' & race == "`j'" & education == "`k'", de
			replace weighted_median_wealth = r(p50) if year ==`i' & race == "`j'" & education == "`k'"
		}
	}
}


* Plot combined median wealth trends for all groups
twoway (line weighted_median_wealth year if race == "white" & education == "college degree", lwidth(0.5) lpattern(solid) ) ///
      (line weighted_median_wealth year if race == "black" & education == "college degree", lwidth(0.5) lpattern(dash) ) ///
      (line weighted_median_wealth year if race == "Hispanic" & education == "college degree", lwidth(0.5) lpattern(shortdash) ) ///
      (line weighted_median_wealth year if race == "other" & education == "college degree", lwidth(0.5) lpattern(dash_dot)), ///
	  legend(order(1 "White - College Degree" 2 "Black - College Degree" 3 "Hispanic - College Degree" 4 "Other - College Degree") size(small)) ///
      ytitle("Median Wealth ($)") xtitle("Year") ///
      xlabel(1989(3)2016) ylabel(, format(%10.0fc) angle(horizontal)) ///
      xscale(range(1989 2016)) ///
      xline(2007, lcolor(black) lpattern(solid) lwidth(0.3)) ///
      graphregion(color(white)) bgcolor(white) ///
	  text(0 2007 "2007 Financial Crisis", place(e) size(vsmall))
graph save "$Out\trend_college.gph", replace

twoway (line weighted_median_wealth year if race == "white" & education == "some college", lwidth(0.5) lpattern(solid) ) ///
      (line weighted_median_wealth year if race == "black" & education == "some college", lwidth(0.5) lpattern(dash) ) ///
      (line weighted_median_wealth year if race == "Hispanic" & education == "some college", lwidth(0.5) lpattern(shortdash) ) ///
      (line weighted_median_wealth year if race == "other" & education == "some college", lwidth(0.5) lpattern(dash_dot) ), ///
	  legend(order(1 "White - Some College" 2 "Black - Some College" 3 "Hispanic - Some College" 4 "Other - Some College") size(small)) ///
      ytitle("Median Wealth ($)") xtitle("Year") ///
      xlabel(1989(3)2016) ylabel(, format(%10.0fc) angle(horizontal)) ///
      xscale(range(1989 2016)) ///
      xline(2007, lcolor(black) lpattern(solid) lwidth(0.3)) ///
      graphregion(color(white)) bgcolor(white) ///
	  text(0 2007 "2007 Financial Crisis", place(e) size(vsmall))
graph save "$Out\trend_some_college.gph", replace
	  
twoway (line weighted_median_wealth year if race == "white" & education == "no college", lwidth(0.5) lpattern(solid) ) ///
      (line weighted_median_wealth year if race == "black" & education == "no college",  lwidth(0.5) lpattern(dash) ) ///
      (line weighted_median_wealth year if race == "Hispanic" & education == "no college", lwidth(0.5) lpattern(shortdash) ) ///
      (line weighted_median_wealth year if race == "other" & education == "no college", lwidth(0.5) lpattern(dash_dot) ), ///
	  legend(order(1 "White - No College" 2 "Black - No College" 3 "Hispanic - No College" 4 "Other - No College") size(small)) ///
      ytitle("Median Wealth ($)") xtitle("Year") ///
      xlabel(1989(3)2016) ylabel(, format(%10.0fc) angle(horizontal)) ///
      xscale(range(1989 2016)) ///
      xline(2007, lcolor(black) lpattern(solid) lwidth(0.3)) ///
      graphregion(color(white)) bgcolor(white) ///
	  text(0 2007 "2007 Financial Crisis", place(e) size(vsmall))
graph save "$Out\trend_no_college.gph", replace

graph combine "$Out\trend_college.gph" "$Out\trend_some_college.gph" "$Out\trend_no_college.gph", col(1) ysize(14) xsize(12) ///
title("Median Wealth Over the Years by Race and Education") subtitle("Analysis from the Survey of Consumer Finances") note("Data rescaled into 2016 $. Source: Survey of Consumer Finances.")

graph export "$Out\trend_all.png", replace



* Q2
* Calculate housing wealth
gen housing_wealth = asset_housing - debt_housing

* Drop the man who does not owes housing wealth
gen homeowner = (asset_housing > 0)
keep if (race == "black" | race == "white") & homeowner == 1

* Calculate weighted median housing wealth by year, race
gen weighted_median_housing_wealth=.

levelsof year, local(time)
levelsof race, local(color)

quietly foreach i of local time{
	quietly foreach j of local color{
		summarize housing_wealth [aweight=weight] if year ==`i' & race == "`j'", de
		replace weighted_median_housing_wealth = r(p50) if year ==`i' & race == "`j'"
	}
}

* Plot median housing wealth trends
twoway (line weighted_median_housing_wealth year if race == "white", lwidth(0.5) lpattern(solid) ) ///
      (line weighted_median_housing_wealth year if race == "black", lwidth(0.5) lpattern(solid) ), ///
      title("Median Housing Wealth Over the Years for Black and White Households") ///
      subtitle("Analysis from the Survey of Consumer Finances") ///
      note("Data rescaled into 2016 $. Source: Survey of Consumer Finances.") /// 
	  legend(order(1 "White" 2 "Black")) ///
      ytitle("Median Housing Wealth ($)") xtitle("Year") ///
      xlabel(1989(3)2016) ylabel(, format(%10.0fc) angle(horizontal)) ///
      xscale(range(1989 2016)) ///
      xline(2007, lcolor(black) lpattern(solid) lwidth(0.3)) ///
      graphregion(color(white)) bgcolor(white) ///
	  text(40000 2007 "2007 Financial Crisis", place(e) size(small))
graph save "$Out\trend_housing_wealth.png", replace
	  

//Q3
* Filter dataset for age 25 or older and for black and white households
keep if age >= 25 & (race == "black" | race == "white") & homeowner == 1
gen non_housing_wealth = wealth - housing_wealth

* Calculate weighted median housing wealth by year, race
drop weighted_median_housing_wealth
gen weighted_median_housing_wealth=.

levelsof year, local(time)
levelsof race, local(color)
quietly foreach i of local time{
	quietly foreach j of local color{
		summarize housing_wealth [aweight=weight] if year ==`i' & race == "`j'", de
		replace weighted_median_housing_wealth = r(p50) if year ==`i' & race == "`j'"
	}
}

* Calculate weighted median non-housing wealth by year, race
gen wtmedian_non_housing_wealth=.

levelsof year, local(time)
levelsof race, local(color)

quietly foreach i of local time{
	quietly foreach j of local color{
		summarize non_housing_wealth [aweight=weight] if year ==`i' & race == "`j'", de
		replace wtmedian_non_housing_wealth = r(p50) if year ==`i' & race == "`j'"
	}
}

save household_wealth,replace


* Determine the number of observations
count
local num_obs = r(N)

* Save a copy of the current dataset
tempfile tempdata
save `tempdata'

* Generate a variable for wealth type
gen wealth_type = "Housing Wealth"

* Append the dataset to itself
append using `tempdata'

* Update the wealth type for the appended data
local new_obs = `num_obs' + 1
replace wealth_type = "Non-Housing Wealth" in `new_obs'/l

* use the extended dataset to draw the combined graph
twoway (line weighted_median_housing_wealth year if race == "white" & wealth_type=="Housing Wealth", lwidth(0.5) lpattern(solid)) ///
      (line weighted_median_housing_wealth year if race == "black"& wealth_type=="Housing Wealth", lwidth(0.5) lpattern(solid)) ///
	  (line wtmedian_non_housing_wealth year if race == "white" & wealth_type == "Non-Housing Wealth", lwidth(0.5) lpattern(dash)) ///
	  (line wtmedian_non_housing_wealth year if race == "black" & wealth_type == "Non-Housing Wealth", lwidth(0.5) lpattern(dash)), ///
      by(wealth_type, title("Trend in Median Housing and Non-Housing Wealth Over the Years for White and Black Households", size(medsmall))) ///
      ytitle("Median Housing Wealth ($)") xtitle("Year") ///
      xlabel(1989(3)2016) ylabel(, format(%10.0fc) angle(horizontal)) ///
      xscale(range(1989 2016)) legend(order(1 "Housing Wealth - White" 2 "Housing Wealth - Black" 3 "Non-Housing Wealth - White" 4 "Non-Housing Wealth - Black") cols(2)) ///
      xline(2007, lcolor(black) lpattern(solid) lwidth(0.3)) ///
      graphregion(color(white)) bgcolor(white) ///
	  text(0 2007 "2007 Financial Crisis", place(e) size(small))
graph save "$Out\combined_trend_housing_wealth.png", replace

* Q3
use household_wealth, clear

br weighted_median_housing_wealth if year==2007 & race=="white"
br weighted_median_housing_wealth if year==2007 & race=="black"

* Calculate housing wealth difference in dollar terms(2017 as base)
gen diff_housing_wealth_black = weighted_median_housing_wealth - 69480.9
gen diff_housing_wealth_white = weighted_median_housing_wealth - 132013.7

gen diff_=diff_housing_wealth_black
replace diff_=diff_housing_wealth_white if race=="white"

* Calculate housing wealth difference in proportional terms(2017 as base)
gen prop_change_black = diff_housing_wealth_black / 69480.9
gen prop_change_white = diff_housing_wealth_white / 132013.7

gen prop_=prop_change_black
replace prop_=prop_change_white if  race=="white"

* drop duplicate observations
duplicates drop year race, force
keep year race diff_ prop_
reshape wide diff_ prop_, i(year) j(race) string

* bar graph for Differential Housing Wealth by Race
graph bar diff_white diff_black, over(year) bargap(0) ///
bar(1, lwidth(medium)) /// 
bar(2, lwidth(medium)) ///
ylabel(, angle(0) grid gmin gmax) ///
legend(size(small) order(1 "White" 2 "Black") ring(0) pos(5)) ///
title("Differential Housing Wealth by Race(Base Year=2007)", size(medium))
graph save "$Out\diff_wealth.gph", replace

* bar graph for Proportional Changes in Housing Wealth by Race
graph bar prop_white prop_black, over(year) bargap(0) ///
bar(1, lwidth(medium)) /// 
bar(2, lwidth(medium)) ///
ylabel(, angle(0) grid gmin gmax format(%9.0g)) ///
legend(size(small) order(1 "White" 2 "Black") ring(0) pos(5)) ///
title("Proportional Changes in Housing Wealth by Race(Base Year=2007)", size(medium)) ///
note("Source: Survey of Consumer Finances.", size(vsmall) pos(5))
graph save "$Out\prop_changes.gph", replace

graph combine "$Out\diff_wealth.gph" "$Out\prop_changes.gph", col(2) xsize(10)
graph save "$Out\combined_2017.png", replace

