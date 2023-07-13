/* =============================================================================

Author: Jonas Peeters
Date: 06/16/2021
Summary: Run specification to check if covariates predict ZORI being missing 
while controlling for distance.

============================================================================= */

// Setup the environment
clear all
global path ""

cd "${path}"

// Load data
use "Data/Intermediate/grad.dta", clear
keep n cbsa pop_2019
duplicates drop
tempfile tmp
save `tmp', replace

use "Data/Intermediate/coef.dta", clear
 
gen cbsa = ""
replace cbsa = "New York-Newark-Jersey City, NY-NJ-PA" if n == 1
replace cbsa = "Los Angeles-Long Beach-Anaheim, CA" if n == 2
replace cbsa = "Chicago-Naperville-Elgin, IL-IN-WI" if n == 3
replace cbsa = "Dallas-Fort Worth-Arlington, TX" if n == 4
replace cbsa = "Houston-The Woodlands-Sugar Land, TX" if n == 5
replace cbsa = "Washington-Arlington-Alexandria, DC-VA-MD-WV" if n == 6
replace cbsa = "Miami-Fort Lauderdale-Pompano Beach, FL" if n == 7
replace cbsa = "Philadelphia-Camden-Wilmington, PA-NJ-DE-MD" if n == 8
replace cbsa = "Atlanta-Sandy Springs-Alpharetta, GA" if n == 9
replace cbsa = "Phoenix-Mesa-Chandler, AZ" if n == 10
replace cbsa = "Boston-Cambridge-Newton, MA-NH" if n == 11
replace cbsa = "San Francisco-Oakland-Berkeley, CA" if n == 12
replace cbsa = "Riverside-San Bernardino-Ontario, CA" if n == 13
replace cbsa = "Detroit-Warren-Dearborn, MI" if n == 14
replace cbsa = "Seattle-Tacoma-Bellevue, WA" if n == 15
replace cbsa = "Minneapolis-St Paul-Bloomington, MN-WI" if n == 16
replace cbsa = "San Diego-Chula Vista-Carlsbad, CA" if n == 17
replace cbsa = "Tampa-St Petersburg-Clearwater, FL" if n == 18
replace cbsa = "Denver-Aurora-Lakewood, CO" if n == 19
replace cbsa = "St Louis, MO-IL" if n == 20
replace cbsa = "Baltimore-Columbia-Towson, MD" if n == 21
replace cbsa = "Charlotte-Concord-Gastonia, NC-SC" if n == 22
replace cbsa = "Orlando-Kissimmee-Sanford, FL" if n == 23
replace cbsa = "San Antonio-New Braunfels, TX" if n == 24
replace cbsa = "Portland-Vancouver-Hillsboro, OR-WA" if n == 25
replace cbsa = "Sacramento-Roseville-Folsom, CA" if n == 26
replace cbsa = "Pittsburgh, PA" if n == 27
replace cbsa = "Las Vegas-Henderson-Paradise, NV" if n == 28
replace cbsa = "Austin-Round Rock-Georgetown, TX" if n == 29
replace cbsa = "Cincinnati, OH-KY-IN" if n == 30

merge n:1 n using `tmp', nogenerate keepusing(pop_2019)

keep n cbsa pop_2019 yvar month coef_dist_log

gen pre = (month == tm(2019m12)) if !mi(month)
gen post = (month == tm(2020m12)) if !mi(month)

keep if pre | post

drop month post
keep if inlist(yvar, "zhvi", "zhvi_zoriav", "zori_zoriav")
reshape wide coef_dist_log, i(n cbsa yvar pop_2019) j(pre)

gen delta_grad_ = coef_dist_log0 - coef_dist_log1
rename coef_dist_log1 pre_grad_

keep n cbsa pop_2019 yvar *grad*
reshape wide *grad*, i(n cbsa pop_2019) j(yvar) string

order n cbsa pop_2019 pre_grad_zori_zoriav delta_grad_zori_zoriav pre_grad_zhvi_zoriav delta_grad_zhvi_zoriav pre_grad_zhvi delta_grad_zhvi 

replace pop_2019 = pop_2019/1000000
format pop_2019 %9.2f
format *grad* %9.3f

cd "Tables"
listtex * using MSAs_v2.tex, ///
	replace rstyle(tabular) ///
	head("\begin{tabular}{cl|ccccccc} \hline\# & MSA & \begin{tabular}{c}Population\\(Millions)\end{tabular} & \begin{tabular}{c}Pre-pandemic\\Rent Gradient\end{tabular} & \begin{tabular}{c}Change in\\ Rent Gradient\end{tabular} & \begin{tabular}{c}Pre-pandemic\\Price Gradient\end{tabular} & \begin{tabular}{c}Change in\\ Price Gradient\end{tabular} & \begin{tabular}{c}Pre-pandemic\\Price Gradient*\end{tabular} & \begin{tabular}{c}Change in\\ Price Gradient*\end{tabular}\\\hline") ///
	foot("\hline\end{tabular}")

// yvar == "zhvi_zoriav" -- for ZHVI restricted,
// yvar == "zori_zoriav" -- for ZORI restricted,
// yvar == "zhvi" -- for ZHVI all zips
