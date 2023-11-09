// Data Task for Chicago Stigler Center
// Oct. 29, 2023
global path "C:\Users\huhu\Desktop\Code Task\***_task"
global D    "$path\data"      //data file
global Out  "$path\out"       //result: graph and table
cd "$D"                       //set current working directory
set scheme cleanplots, perm


/*
First I will import the html and csv file, check the data, then I use the dataset
provided to calculate the statistics for contribution amount. Once I've done that, I plot the tables and graphs we need.
*/


//----------------------Exercise 1-----------------------------------------

// Divide Arkansas into AR_00_01 and AR_02_16 as the first_term_method changes 
// at 2002, North Carolina also changes at 04 and 20, but we dont have 2020 
// data for NC
import delimited "law_firms_donations.csv",clear
keep if state_name=="ARKANSAS"
sort election_year
duplicates drop election_year,force
// Check the years of AR in our data:00-16
tab election_year


// Load the dataset
import delimited "state_chars_text.csv",clear
save state_chars_text.dta, replace

// Duplicates ARKANSAS
keep if state_name == "Arkansas"
replace slug="AR_02_16"
tempfile duplicate
save `duplicate'
use `duplicate', clear
append using state_chars_text.dta
replace slug="AR_00_01" if slug=="AR"
save state_chars_text_dupAR.dta,replace

use state_chars_text_dupAR.dta, clear
// Create binding_commission variable
gen binding_commission = 0 
replace binding_commission = 1 if regexm(interim_appointment_method, "binding slate")
// Revise the non-binding slate coding error
replace binding_commission = 0 if regexm(interim_appointment_method, "non-binding slate")


// Create partisan_election variable 
gen partisan_election = 1 
replace partisan_election = 0 if regexm(first_term_method, "non-partisan") 
// Edit for states that changes first_term_method
replace partisan_election = 1 if slug == "AR_00_01" | slug == "NC_96_03" | slug == "WV_96_14"
// Tennessee Judges are initially appointed by the governor, with Tennessee house of representatives and senate confirmation, from a binding slate of candidates, we classifiy Tennessee into non-partisan here
replace partisan_election = 0 if slug == "TN"

// Create retention variable 
gen retention = 0
replace retention = 1 if regexm(additional_term_method, "retention election")

// Save the dataset with new variables 
save "state_chars_text_3dummy.dta", replace

// Descriptive Statistics
estpost tabstat binding_commission partisan_election retention, statistics(N mean sd min max median) columns(statistics)
esttab using "descriptive_stats.rtf", cells("count mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2)) median(fmt(2))") nonumber noobs nomtitles replace




// -------------------------Exercise 2----------------------------------------
use state_chars_text_3dummy.dta, clear
keep if term_length==6
// The States that have term-lengths of 6 years are AL, GA, ID, MN, NV, OH, OR,
// PA, TX and WA
keep state_name
save temp_states, replace

// Load the donations dataset for non-lawyer individuals
import delimited nonlaw_indivs_donations.csv, case(preserve) clear
// rename to keep up with law_individual_donation file
rename (contributorid electionyear officesoughtid candidateid amount	contributioncount contributor originalname zipcode parentorgemployerid parentorgemployer employerid employer specificbusinessid specificbusiness	generalindustry	generalindustryid broadsector broadsectorid candidate	electionstatus candidatestatus electiontype generalparty officesought	incumbencystatus state_name) (contributor_id election_year office_sought_id candidate_id amount	contribution_count contributor original_name zip_code parent_org_employer_id	parent_org_employer employer_id employer specific_business_id	specific_business general_industry general_industry_id broad_sector	broad_sector_id candidate election_status candidate_status election_type	general_party office_sought	incumbency_status state_name)
save nonlawyers, replace

// Load the donations dataset for lawyer-individuals
import delimited "lawyers_donations.csv", clear
// replace state_name to first uppcase and other lowercase
replace state_name = proper(state_name)

// Append the two donations datasets
append using nonlawyers
gen individual=1

save individuals,replace

// Merge with the list of states with 6-year terms
merge m:1 state_name using temp_states
keep if _merge==3
drop _merge

// Compute statistics for all individuals
// there are negative donation amount may arising from over limit refund, 
// transfer to non-federal account, bank interest lost. I exclude them to
// calculate statistics
keep if amount>0

collapse (min) min_donation=amount (max) max_donation=amount ///
(median) median_donation=amount (mean) mean_donation=amount (iqr) iqr_donation=amount, by(state_name)
format min_donation max_donation median_donation mean_donation iqr_donation %9.2f
export excel using "donation_stats_by_state.xlsx", first(var) replace

// Calculate only for lawyer-individuals
import delimited "lawyers_donations.csv", clear
replace state_name = proper(state_name)
merge m:1 state_name using temp_states
keep if _merge==3
drop _merge
keep if amount>0

collapse (min) min_donation=amount (max) max_donation=amount ///
(median) median_donation=amount (mean) mean_donation=amount (iqr) iqr_donation=amount, by(state_name)
format min_donation max_donation median_donation mean_donation iqr_donation %9.2f
export excel using "donation_stats_by_state_lawyer_individual.xlsx", first(var) replace



// --------------------------Exercise 3-------------------------------------
import delimited "law_firms_donations.csv", clear

// Replace the missing names by the non-missing ones within each group
gen non_missing_name=1 if !missing(contributor)

sort contributor_id non_missing_name
by contributor_id: replace contributor = contributor[1] if missing(contributor)

// Filter law firms in Ohio
keep if state_name=="OHIO"

// Aggregate donations
bysort contributor_id: egen total_donation = sum(amount)

// Sort by total donations and keep the top 10
gsort -total_donation
duplicates drop contributor_id, force
keep in 1/10
keep contributor total_donation
format total_donation %9.2f
// Export the table
export excel using "top10_law_firms_ohio.xlsx", firstrow(var) replace



// --------------------------Exercise 4-------------------------------------
// Get retention variable
use state_chars_text_3dummy.dta, clear
keep state_name retention
duplicates drop state_name, force
save temp_states, replace

use nonlawyers,clear
// Merge with the retention variable
merge m:1 state_name using temp_states
keep if _merge==3
drop _merge

// Keep only the observations from states with retention elections
keep if retention == 1

// Aggregate the donations
keep if amount>0
bysort contributor_id: egen total_donation = sum(amount)

* Sort by total donations in descending order and keep the top 10
gsort -total_donation
duplicates drop contributor_id, force
keep in 1/10
keep contributor state_name total_donation
format total_donation %9.2f
// Export the table
export excel using "top10_nonlawyer_donors.xlsx", firstrow(var) replace



// --------------------------Exercise 5-------------------------------------
import delimited "law_firms_donations.csv", clear
// replace state_name to first uppcase and other lowercase
replace state_name = proper(state_name)
save lawfirm,replace

import delimited "nonlaw_firms_donations.csv", clear
rename (contributorid electionyear officesoughtid candidateid amount	contributioncount contributor parentorgemployerid parentorgemployer employerid employer specificbusinessid specificbusiness	generalindustry	generalindustryid broadsector broadsectorid candidate electionstatus electiontype generalparty officesought	inumbencystatus statename) (contributor_id election_year office_sought_id candidate_id amount	contribution_count contributor parent_org_employer_id	parent_org_employer employer_id employer specific_business_id	specific_business general_industry general_industry_id broad_sector	broad_sector_id candidate election_status election_type	general_party office_sought	incumbency_status state_name)

append using lawfirm
gen firm = 1 
save firm,replace

// append all data
append using individuals
save all,replace

// merge state characterstic
use state_chars_text_3dummy.dta, clear
//gen mandatory retirement variable
gen mand_retirement=0
replace mand_retirement = 1 if state_name=="Minnesota" | state_name=="North Carolina" | state_name=="Oregon" | state_name=="Pennsylvania" | state_name=="Texas" | state_name=="Washington"
duplicates drop state_name,force
rename unnamed0 state_flag
save state_chars_text_4dummy.dta,replace

use all,clear
merge m:1 state_name using state_chars_text_4dummy
keep if _merge==3
drop _merge

keep if amount>0
//calculate total donations by state
bysort state_name: egen total_donation = sum(amount)
bysort state_name: egen individual_donation = sum(amount) if individual==1
bysort state_name: egen firm_donation = sum(amount) if firm ==1

//calculate total donations by year and state
bysort state_name election_year: egen panel_total_donation = sum(amount)
bysort state_name election_year: egen panel_individual_donation = sum(amount) if individual==1
bysort state_name election_year: egen panel_firm_donation = sum(amount) if firm ==1

save reg_data,replace


use reg_data,clear
// PANEL REG
duplicates drop state_flag election_year, force
xtset state_flag election_year

// all sample
xtreg panel_total_donation bench_size term_length binding_commission partisan_election retention mand_retirement
outreg2 using xxx.doc, replace bdec(3) tdec(2) ctitle(All Sample) ///
keep(bench_size term_length binding_commission partisan_election retention mand_retirement) addtext(State FE & Year FE, NO) label

xtreg panel_total_donation bench_size term_length binding_commission partisan_election retention mand_retirement i.state_flag i.election_year
outreg2 using xxx.doc, append bdec(3) tdec(2) ctitle(All Sample) ///
keep(bench_size term_length binding_commission partisan_election retention mand_retirement) addtext(State FE & Year FE, YES) label
// Individual sample
xtreg panel_individual_donation bench_size term_length binding_commission partisan_election retention mand_retirement
outreg2 using xxx.doc, append bdec(3) tdec(2) ctitle(Individual) ///
keep(bench_size term_length binding_commission partisan_election retention mand_retirement) addtext(State FE & Year FE, NO) label

xtreg panel_individual_donation bench_size term_length binding_commission partisan_election retention mand_retirement i.state_flag i.election_year
outreg2 using xxx.doc, append bdec(3) tdec(2) ctitle(Individuals) ///
keep(bench_size term_length binding_commission partisan_election retention mand_retirement) addtext(State FE & Year FE, YES) label
// Firms sample
xtreg panel_firm_donation bench_size term_length binding_commission partisan_election retention mand_retirement
outreg2 using xxx.doc, append bdec(3) tdec(2) ctitle(Firms) ///
keep(bench_size term_length binding_commission partisan_election retention mand_retirement) addtext(State FE & Year FE, NO) label

xtreg panel_firm_donation bench_size term_length binding_commission partisan_election retention mand_retirement i.state_flag i.election_year
outreg2 using xxx.doc, append bdec(3) tdec(2) ctitle(Firms) ///
keep(bench_size term_length binding_commission partisan_election retention mand_retirement) addtext(State FE & Year FE, YES) label


// donation and election status
use reg_data,clear
bysort candidate_id election_year: egen candidate_total_donation = sum(amount)
bysort candidate_id election_year: egen candidate_individual_donation = sum(amount) if individual==1
bysort candidate_id election_year: egen candidate_firm_donation = sum(amount) if firm ==1

replace candidate_total_donation=candidate_total_donation/1000000
replace candidate_individual_donation=candidate_individual_donation/1000000
replace candidate_firm_donation=candidate_firm_donation/1000000


// gen win/lost variable
gen win = . 
replace win = 1 if regexm(election_status, "Win") | regexm(election_status, "Won")
replace win = 0 if regexm(election_status, "Lost")

// gen incumbency_status variable
gen incumb_status=0
replace incumb_status=1 if incumbency_status=="Challenger"
replace incumb_status=2 if incumbency_status=="Open"

// REG
duplicates drop candidate_id election_year, force
xtset candidate_id election_year

// all sample
probit win candidate_total_donation
estimates store donation_all_w/o_control
outreg2 using xxx.doc, replace bdec(3) tdec(2) ctitle(All Sample) ///
keep(candidate_total_donation) addtext(Control Variables, NO) label

probit win candidate_total_donation bench_size term_length binding_commission partisan_election retention mand_retirement
estimates store donation_all 
outreg2 using xxx.doc, append bdec(3) tdec(2) ctitle(All Sample) ///
keep(candidate_total_donation bench_size term_length binding_commission partisan_election retention mand_retirement) addtext(Control Variables, YES) label

// candidate_individual_donation_donation
probit win candidate_individual_donation
estimates store donation_individual_w/o_control
outreg2 using xxx.doc, append bdec(3) tdec(2) ctitle(individual) ///
keep(candidate_individual_donation) addtext(Control Variables, NO) label

probit win candidate_individual_donation bench_size term_length binding_commission partisan_election retention mand_retirement
estimates store donation_individual
outreg2 using xxx.doc, append bdec(3) tdec(2) ctitle(individual) ///
keep(candidate_individual_donation bench_size term_length binding_commission partisan_election retention mand_retirement) addtext(Control Variables, YES) label

// firm
probit win candidate_firm_donation
estimates store donation_firm_w/o_control
outreg2 using xxx.doc, append bdec(3) tdec(2) ctitle(Firms) ///
keep(candidate_firm_donation) addtext(Control Variables, NO) label

probit win candidate_firm_donation bench_size term_length binding_commission partisan_election retention mand_retirement
estimates store donation_firm
outreg2 using xxx.doc, append bdec(3) tdec(2) ctitle(Firms) ///
keep(candidate_firm_donation bench_size term_length binding_commission partisan_election retention mand_retirement) addtext(Control Variables, YES) label


//coefplot
coefplot donation_all_w/o_control donation_all donation_individual_w/o_control donation_individual donation_firm_w/o_control donation_firm, drop(_cons bench_size term_length binding_commission partisan_election retention mand_retirement) xline(0) ci
