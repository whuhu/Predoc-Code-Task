// Data Task for HKS
// Nov. 17, 2023
clear all
set more off 
cap log close 
set maxvar 20000
set scheme cleanplots, perm

global path "C:\Users\huhu\Desktop\Code Task\HIL_DataTask_2024"
global D    "$path\data"      //data file
global Out  "$path\out"       //result: graph and table
cd "$D"                       //set current working directory

log using "$Out\task 1.smcl", replace

//---------------------Data Preparation--------------------------------
use "GSS7218_R1.dta", clear

// Make all variables lowercase
rename *,lower

//keep vote* if* sex relig age educ

gen vote_pres=.

// Loop through each election year
foreach y in 72 76 80 84 88 92 96 {
    local z = `y' +1902
    replace vote_pres = 1 if (vote`y' == 1) & year >= `z'
    replace vote_pres = 0 if (vote`y' == 2) & year >= `z'
}

label define vote_pres_lbl 0 "Did Not Vote" 1 "Voted"
label values vote_pres vote_pres_lbl

keep if vote_pres!=.

// gen repub_v_dem
gen repub_v_dem=.
replace repub_v_dem=1 if (pres72==2)|(pres76==2)|(pres80==2)|(pres84==2)|(pres88==2)|(pres92==2)|(pres96==2)
replace repub_v_dem=0 if (pres72==1)|(pres76==1)|(pres80==1)|(pres84==1)|(pres88==1)|(pres92==1)|(pres96==1)

label define repub_v_dem_lbl 0 "Voted Democrat" 1 "Voted Republican"
label values repub_v_dem repub_v_dem_lbl

// gen male
gen male=0
replace male = 1 if sex== 1

label define male_lbl 0 "Female" 1 "Male"
label values male male_lbl

// Recode the relig
recode relig (1 = 1) (2 = 2) (4 = 3), generate(religion)
replace religion=4 if (relig~=1 & relig~=2& relig~=3) & !missing(relig)
drop if missing(religion)

label define religion_lbl 1 "Protestant" 2 "Catholic" 3 "No Religion" 4 "Other"
label values religion religion_lbl


// gen age_cat
gen age_cat =.

replace age_cat = 1 if age >= 18 & age <= 29  // 18 to 29
replace age_cat = 2 if age >= 30 & age <= 49  // 30 to 49
replace age_cat = 3 if age >= 50 & age <= 64  // 50 to 64
replace age_cat = 4 if age >= 65 & age!=.n & age!=.d // 65+

label define age_cat_lbl 1 "18 to 29" 2 "30 to 49" 3 "50 to 64" 4 "65+"
label values age_cat age_cat_lbl

// gen less_highschool
gen less_highschool = .

replace less_highschool = 1 if educ < 12
replace less_highschool = 0 if educ >= 12 & educ != .a

save final.dta, replace

//---------------------------Data analysis-----------------------------
// summary statistics
estpost tabstat vote_pres repub_v_dem male religion age_cat less_highschool, statistics(N mean sd min max median) columns(statistics)
esttab using "descriptive_stats.rtf", cells("count mean(fmt(2)) sd(fmt(2)) min(fmt(2)) max(fmt(2)) median(fmt(2))") nonumber noobs nomtitles replace


// Regression whether someone voted on the following controls adding in the 
// order specified one at a time until all controls are included: religion, age, male, less than high school, and year voted
regress vote_pres i.religion [aw=wtssall]
outreg2 using regression_output.rtf, replace ctitle("Control Religion") bdec(3) tdec(2) label

* Add age to the model
regress vote_pres i.religion i.age_cat [aw=wtssall]
outreg2 using regression_output.rtf, append ctitle("Control Religion and Age") bdec(3) tdec(2) label

* Add gender (male) to the model
regress vote_pres i.religion i.age_cat male [aw=wtssall]
outreg2 using regression_output.rtf, append ctitle("Control Religion, Age, and Male") bdec(3) tdec(2) label

* Add education (less than high school) to the model
regress vote_pres i.religion i.age_cat male i.less_highschool [aw=wtssall]
outreg2 using regression_output.rtf, append ctitle("Control Religion, Age, Male, and Education") bdec(3) tdec(2) label

* Final model with year voted
regress vote_pres i.religion i.age_cat male i.less_highschool year [aw=wtssall]
outreg2 using regression_output.rtf, append ctitle("Full Model") bdec(3) tdec(2) label



//Repeat step 2 immediately above for the outcome of voted Republican vs. 
//Democrat.
regress repub_v_dem i.religion [aw=wtssall]
outreg2 using regression_output.rtf, replace ctitle("Control Religion") bdec(3) tdec(2) label

* Add age to the model
regress repub_v_dem i.religion i.age_cat [aw=wtssall]
outreg2 using regression_output.rtf, append ctitle("Control Religion and Age") bdec(3) tdec(2) label

* Add gender (male) to the model
regress repub_v_dem i.religion i.age_cat male [aw=wtssall]
outreg2 using regression_output.rtf, append ctitle("Control Religion, Age, and Male") bdec(3) tdec(2) label

* Add education (less than high school) to the model
regress repub_v_dem i.religion i.age_cat male i.less_highschool [aw=wtssall]
outreg2 using regression_output.rtf, append ctitle("Control Religion, Age, Male, and Education") bdec(3) tdec(2) label

* Final model with year voted
regress repub_v_dem i.religion i.age_cat male i.less_highschool year [aw=wtssall]
outreg2 using regression_output.rtf, append ctitle("Full Model") bdec(3) tdec(2) label



// DID
gen post1979 = year > 1979
gen less_than_highschool = educ < 12

regress repub_v_dem post1979 less_than_highschool post1979#less_than_highschool i.religion i.age male i.year [aw=wtssall]

coefplot, keep(post1979 less_than_highschool post1979#less_than_highschool) ciopts(recast(rcap))


// Event Study
foreach year in 72 74 76 80 82 84 88 92 96 {
    gen interaction`year' = (year == `year') * less_than_highschool
}

regress repub_v_dem interaction* i.religion i.age male i.less_highschool [aw=wtssall] if year != 1976

coefplot interaction* if year != 1976, drop(interaction76) ciopts(recast(rcap))


log  close