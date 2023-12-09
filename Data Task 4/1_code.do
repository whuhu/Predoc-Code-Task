// Nov. 26, 2023
********************************************************************

* The code file has 2 parts:
* - Part 1 Data Cleaning
* - Part 2 Data Analysis

************************Part 1 Data Cleaning***********************

clear all
set more off 
cap log close 
set maxvar 20000
set scheme cleanplots, perm

// If the reader wants to replicate the results, he/she just needs to change this global path and put the data in raw_data file. 
global path "XXX"
global D    "$path\data"      //data file
global Out  "$path\out"       //result: graph and table
cd "$D"                       //set current working directory

log using "$Out\task 1.smcl", replace

local year `""2009" "2010" "2011" "2012""'
foreach y in `year' {
	import delimited "red_sox_`y'.csv", clear
	gen year = `y'
	save `y'.dta, replace
}

// combine dataset
use 2009.dta, clear
append using 2010
append using 2011
append using 2012
save red_sox.dta, replace

// encode string variables
encode sectiontype, gen(sectiontype_encoded)
encode gamemonth, gen(gamemonth_encoded)
encode team, gen(team_encoded)

************************Part 2 Data Analysis***********************
// pooled trend
tw (scatter logprice days_from_transaction_until_game) ///
	(lfit logprice days_from_transaction_until_game), title("Trend of Log Price over Days") xtitle("Days from Transaction Until Game") ytitle("Log Price") xscale(reverse) 
graph export "$Out\trend_all.png", replace


sort days_from_transaction_until_game
by days_from_transaction_until_game: egen sd_logprice = sd(logprice)
sc sd_logprice days_from_transaction_until_game, title("Volatility of Log Price over Days") xtitle("Days from Transaction Until Game") ytitle("Volatility of Log Price") graphregion(color(white)) xscale(reverse)
graph export "$Out\sd_all.png", replace


scatter logprice days_from_transaction_until_game, by(year) xscale(reverse)

tw (lpoly logprice days_from_transaction_until_game if year==2009, n(1000)) ///
	(lpoly logprice days_from_transaction_until_game if year==2010, n(1000)) ///
	(lpoly logprice days_from_transaction_until_game if year==2011, n(1000)) ///
	(lpoly logprice days_from_transaction_until_game if year==2012, n(1000))


// regression
regress logprice days_from_transaction_until_game, r
outreg2 using regression_output.tex, replace ctitle("Baseline") bdec(3) tdec(2) label addtext(Year FE, NO)

// Add year to the model
regress logprice days_from_transaction_until_game i.year, r
outreg2 using regression_output.tex, append ctitle("With Year FE") bdec(3) tdec(2) label addtext(Year FE, YES)

// Add other controls to the model
regress logprice days_from_transaction_until_game i.year i.sectiontype_encoded number_of_tickets i.gamemonth_encoded i.team_encoded day_game weekend_game, r
outreg2 using regression_output.tex, append ctitle("Full Control") bdec(3) tdec(2) label keep(days_from_transaction_until_game i.year number_of_tickets day_game weekend_game) addtext(Year FE, YES)


//coefplot
coefplot,keep(*.year *.gamemonth_encoded) title("Coefficient of Years and Months") xline(0) baselevels ci
graph export "$Out\coef_time.png", replace

coefplot,keep(*.team_encoded) title("Coefficient of Opponent Teams") xline(0) baselevels ci
graph export "$Out\coef_opponent.png", replace


// regress by group
// divide by group
gen group_days = ceil(days_from_transaction_until_game / 5)

forvalues i = 1/51 { 
    local lower = 5 * (`i' - 1) + 1
    local upper = 5 * `i'
    label define daygroup `i' "`lower'-`upper' days", add
}

label values group_days daygroup

// dynamic effects graph
regress logprice i.group_days i.year i.sectiontype_encoded number_of_tickets i.gamemonth_encoded i.team_encoded day_game weekend_game, r

coefplot,keep(*.group_days) title("Coefficient of Opponent Teams") baselevels ci vertical label xlabel(, angle(45) labsize(vsmall))

// ticket price trend by opponents
tw (sc logprice days_from_transaction_until_game if team=="NYY") ///
	(sc logprice days_from_transaction_until_game if team=="SEA") ///
	(lpoly logprice days_from_transaction_until_game if team=="NYY", n(1000)) ///
	(lpoly logprice days_from_transaction_until_game if team=="SEA", n(1000)) ///
	,title("Trend of Log Price(NYY & SEA)") legend(label(1 "NYY") label(2 "SEA") label(3 "NYY Trend Line") label(4 "SEA Trend Line") position(4) ring(0))
graph export "$Out\trend_opponent.png", replace


// Time trend patterns by year
// regression
gen year2009 = (year==2009)
gen year2010 = (year==2010)
gen year2011 = (year==2011)
gen year2012 = (year==2012)

gen interact2010 = days_from_transaction_until_game*year2010
gen interact2011 = days_from_transaction_until_game*year2011
gen interact2012 = days_from_transaction_until_game*year2012

regress logprice interact2010 interact2011 interact2012 days_from_transaction_until_game year2010 year2011 year2012, r
outreg2 using regression_output.tex, replace ctitle("Baseline") bdec(3) tdec(2) label

// Add year to the model
regress logprice interact2010 interact2011 interact2012 days_from_transaction_until_game year2010 year2011 year2012 i.sectiontype_encoded number_of_tickets i.gamemonth_encoded i.team_encoded day_game weekend_game, r
outreg2 using regression_output.tex, append ctitle("Full Control") bdec(3) tdec(2) label keep(interact2010 interact2011 interact2012 days_from_transaction_until_game year2010 year2011 year2012 number_of_tickets day_game weekend_game)


log  close
