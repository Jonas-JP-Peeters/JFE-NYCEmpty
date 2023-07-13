/*==============================================================================
Date: Sep 21, 2021
Author of Script: Vrinda Mittal

Project:
	* Paper: Flattening the Curve: Pandemic Induced Revaluation of Urban Real Estate
	* NBER working paper #w28675, link: https://www.nber.org/papers/w28675
	* DOI 10.3386/w28675
	* SSRN working paper: https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3780012
	* Authors: Arpit Gupta, Vrinda Mittal, Jonas Peeters, Stijn Van Nieuwerburgh

Objective:
	* Comparing CPI Rent and ZORI MSA level data

Input:
	* CPI MSA level series
		- cpi_ny_1.csv
		- cpi_la_2.csv
		- cpi_chicago_3.csv
		- cpi_dallas_4.csv
		- cpi_houston_5.csv
		- cpi_miami_7.csv
		- cpi_philadelphia_8.csv
		- cpi_atlanta_9.csv
		- cpi_phoenix_10.csv
		- cpi_boston_11.csv
		- cpi_sf_12.csv
		- cpi_detroit_14.csv
		- cpi_seattle_15.csv
		- cpi_minneapolis_16.csv
		- cpi_sd_17.csv
		- cpi_tampa_18.csv
		- cpi_denver_19.csv
		- cpi_stlouis_20.csv
		- cpi_pittsburgh_27.csv
		- cpi_cincinnati_30.csv
	* ZORI MSA level
		- Metro_ZORI_AllHomesPlusMultifamily_SSA.dta

Output:
	(a): Figures
		* Fig A15: Correlation Between CPI Rent of Primary Residence and ZORI
				   at MSA level

==============================================================================*/

clear
set varabbrev off

//setting path
if "`c(username)'"=="vm2517" {
	cd "/Users/vm2517/Dropbox/PhD/Research/NYCempty_all/NYCempty/JFEfinal"
}
else {
	cd "" //Jonas -- you can fill in path here
}


*defining global variables
global src "Data/Source"
global int "Data/Intermediate"
global figures "Figures"
global tables "Tables"

*================================================================================================* 
* 1: ny //m
import delimited "${src}/cpi_ny_1.csv", clear
rename cuura101seha n_1
tempfile n1
save `n1'

* 2: la //semiannually
import delimited "${src}/cpi_la_2.csv", clear
rename value n_2
gen miy = 06
replace miy = 12 if period == "S02"
gen month = ym(year, miy)
format month %tm
drop seriesid label period year miy
tempfile n2
save `n2'

* 3: chicago //m
import delimited "${src}/cpi_chicago_3.csv", clear
rename cuura207seha n_3
tempfile n3
save `n3'

* 4: dallas //m
import delimited "${src}/cpi_dallas_4.csv", clear
rename cuura316seha n_4
tempfile n4
save `n4'

* 5: houston //m
import delimited "${src}/cpi_houston_5.csv", clear
rename cuura318seha n_5
tempfile n5
save `n5'

* 6: N/A

* 7: miami //m
import delimited "${src}/cpi_miami_7.csv", clear
rename cuura320seha n_7
tempfile n7
save `n7'

* 8: philadelphia //m
import delimited "${src}/cpi_philadelphia_8.csv", clear
rename cuura102seha n_8
tempfile n8
save `n8'

* 9: atlanta //m
import delimited "${src}/cpi_atlanta_9.csv", clear
rename cuura319seha n_9
tempfile n9
save `n9'

* 10: Phoenix //annual
import delimited "${src}/cpi_phoenix_10.csv", clear
rename cuusa429seha n_10
gen year = substr(date, 1, 4)
gen miy = 12
destring year, replace
gen month = ym(year, miy)
format month %tm
drop date year miy
tempfile n10
save `n10'

* 11: boston //m
import delimited "${src}/cpi_boston_11.csv", clear
rename cuura103seha n_11
tempfile n11
save `n11'

* 12: sf //m
import delimited "${src}/cpi_sf_12.csv", clear
rename cuura422seha n_12
tempfile n12
save `n12'

* 13: N/A

* 14: detroit //m
import delimited "${src}/cpi_detroit_14.csv", clear
rename cuura208seha n_14
tempfile n14
save `n14'

* 15: seattle //m
import delimited "${src}/cpi_seattle_15.csv", clear
rename cuura423seha n_15
tempfile n15
save `n15'

* 16: minneapolis //annual
import delimited "${src}/cpi_minneapolis_16.csv", clear
rename cuusa211seha n_16
gen year = substr(date, 1, 4)
gen miy = 12
destring year, replace
gen month = ym(year, miy)
format month %tm
drop date year miy
tempfile n16
save `n16'

* 17: san diego //annual
import delimited "${src}/cpi_sd_17.csv", clear
rename cuusa424seha n_17
gen year = substr(date, 1, 4)
gen miy = 12
destring year, replace
gen month = ym(year, miy)
format month %tm
drop date year miy
tempfile n17
save `n17'

* 18: tampa //annual
import delimited "${src}/cpi_tampa_18.csv", clear
rename cuusa321seha n_18
gen year = substr(date, 1, 4)
gen miy = 12
destring year, replace
gen month = ym(year, miy)
format month %tm
drop date year miy
tempfile n18
save `n18'

* 19: denver //annual
import delimited "${src}/cpi_denver_19.csv", clear
rename cuusa433seha n_19
gen year = substr(date, 1, 4)
gen miy = 12
destring year, replace
gen month = ym(year, miy)
format month %tm
drop date year miy
tempfile n19
save `n19'

* 20: St Louis //seminnually
import delimited "${src}/cpi_stlouis_20.csv", clear
rename cuusa209seha n_20
gen year = substr(date,1,4)
gen miy = substr(date,6,2)
destring year miy, replace
replace miy = 6 if miy == 1
replace miy = 12 if miy == 7
gen month = ym(year, miy)
format month %tm
drop date year miy
tempfile n20
save `n20'

* 21-26: N/A

* 27: Pittsburgh //seminnually
import delimited "${src}/cpi_pittsburgh_27.csv", clear
rename cuusa104seha n_27
gen year = substr(date,1,4)
gen miy = substr(date,6,2)
destring year miy, replace
replace miy = 6 if miy == 1
replace miy = 12 if miy == 7
gen month = ym(year, miy)
format month %tm
drop date year miy
tempfile n27
save `n27'

* 28-29: N/A

* 30: cincinnati //annual
import delimited "${src}/cpi_cincinnati_30.csv", clear
rename cuusa213seha n_30
gen year = substr(date, 1, 4)
gen miy = 12
destring year, replace
gen month = ym(year, miy)
format month %tm
drop date year miy
tempfile n30
save `n30'

* merging monthly
use `n1'
merge 1:1 date using `n3'
drop _merge
merge 1:1 date using `n4'
drop _merge
merge 1:1 date using `n5'
drop _merge
merge 1:1 date using `n7'
drop _merge
merge 1:1 date using `n8'
drop _merge
merge 1:1 date using `n9'
drop _merge
merge 1:1 date using `n11'
drop _merge
merge 1:1 date using `n12'
drop _merge
merge 1:1 date using `n14'
drop _merge
merge 1:1 date using `n15'
drop _merge

gen year = substr(date, 1, 4)
gen miy = substr(date, 6, 2)
destring year miy, replace
gen month = ym(year, miy)
format month %tm

order date year miy month

* semiannual
merge 1:1 month using `n2'
drop _merge
merge 1:1 month using `n20'
drop _merge
merge 1:1 month using `n27'
drop _merge


* annual
merge 1:1 month using `n10'
drop _merge
merge 1:1 month using `n16'
drop _merge
merge 1:1 month using `n17'
drop _merge
merge 1:1 month using `n18'
drop _merge
merge 1:1 month using `n19'
drop _merge
merge 1:1 month using `n30'
drop _merge

drop date

gen id = _n

* wide to long
reshape long n_, i(id) j(n)
sort n month
drop id
rename n_ cpi_rent
tempfile cpi_rent
save `cpi_rent'

* merge zori
use "${int}/Metro_ZORI_AllHomesPlusMultifamily_SSA.dta", clear

ds _*
foreach var of varlist `r(varlist)' {
	local varname = "`var'"
    rename `var' ZORI`varname'
}

drop if SizeRank ==0
drop index
gen n = .
order SizeRank n


* houston
replace n=1 if RegionName == "New York, NY"
replace n=2 if RegionName == "Los Angeles-Long Beach-Anaheim, CA"
replace n=3 if RegionName == "Chicago, IL"
replace n=4 if RegionName == "Dallas-Fort Worth, TX"
replace n=5 if RegionName == "Houston, TX"
replace n=7 if RegionName == "Miami-Fort Lauderdale, FL"
replace n=8 if RegionName == "Philadelphia, PA"
replace n=9 if RegionName == "Atlanta, GA"
replace n=10 if RegionName == "Phoenix, AZ"
replace n=11 if RegionName == "Boston, MA"
replace n=12 if RegionName == "San Francisco, CA"
replace n=14 if RegionName == "Detroit, MI"
replace n=15 if RegionName == "Seattle, WA"
replace n=16 if RegionName == "Minneapolis-St Paul, MN"
replace n=17 if RegionName == "San Diego, CA"
replace n=18 if RegionName == "Tampa, FL"
replace n=19 if RegionName == "Denver, CO"
replace n=20 if RegionName == "St. Louis, MO"
replace n=27 if RegionName == "Pittsburgh, PA"
replace n=30 if RegionName == "Cincinnati, OH"

keep if n!=.
drop SizeRank RegionID RegionName

* long
gen id = _n
reshape long ZORI_, i(id) j(month) string
drop id

* formatting month
gen miy = substr(month,6,2)
gen year = substr(month,1,4)
destring miy year, replace
drop month
gen month = ym(year, miy)
format month %tm
drop miy year
order n month
sort n month ZORI_

merge 1:1 n month using `cpi_rent'
//_merge==0 is none, makes sense zori starts from 2014
drop _merge


* Fig A15 of the paper: percentage changes between dec 2014 and dec 2020
sort n month
local rlist "ZORI_ cpi_rent"
foreach r of local rlist {
	gen l_`r' = log(`r')
}

local rlist "ZORI_ cpi_rent"
foreach r of local rlist {
	gen `r'_14 = `r' if month==659
	bysort n (`r'_14): replace `r'_14 = `r'_14[1] if `r'_14==.
} 
sort n month

gen l_ZORI__14 = log(ZORI__14)
gen l_cpi_rent_14 = log(cpi_rent_14)

gen cpi_r_ld_6yr = l_cpi_rent - l_cpi_rent_14
gen zori_ld_6yr = l_ZORI_ - l_ZORI__14

	twoway (scatter zori_ld_6yr cpi_r_ld_6yr if (month==731), mcolor(red%50)) (lfit zori_ld_6yr cpi_r_ld_6yr if (month==731), lcolor(black) lwidth(thick)), graphregion(color(white)) xtitle("Difference in Log(CPI Rent) Dec2014-Dec2020") ytitle("Difference in Log(ZORI) Dec2014-Dec2020") ///
	legend(order(1 "CBSAs" 3 "OLS fit")) ///
	ylabel(,angle(360) format(%9.3fc))
	
	graph export "${figures}/cpi_zori_1420.pdf", replace

*================================ end of code =================================*






