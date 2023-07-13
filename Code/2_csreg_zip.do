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
	* Zip level analysis

Input:
	* preprocessed.dta

Output:
	(a): Tables
		* Table II (Panel A, B): Intra-city Rent and Price Changes
		* Table A.III: Explaining the Cross-ZIP Variation in Price Changes
	
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

*==============================================================================*

* loading data price/rent + variables data
use "${int}/preprocessed.dta", clear

* long
reshape long ZHVI_ ZHVI_B1_ ZHVI_B2_ ZORI_ ZHVI_condo_ ZHVI_sfr_ , i(zip) j(month) string
destring zip, replace

* formatting month
gen miy = substr(month,1,2)
gen year = substr(month,3,4)
destring miy year, replace
drop month
gen month = ym(year, miy)
format month %tm
drop miy year
order n cbsa zip distance month

* log distance log of prices and rents
gen distance_log = log(1+distance)
* total unavailable zip
replace totalunavailable_zip = totalunavailable_zip/100
* household income in thousands
replace cns_median_hh_inc = cns_median_hh_inc/1000

local ylist "ZHVI_ ZORI_ ZHVI_B1_ ZHVI_B2_ ZHVI_condo_ ZHVI_sfr_ " //condo, sfr to come
foreach y of local ylist {
	gen `y'log = log(`y')
}

sort n distance month

gen log_estab = log(establishments)

merge m:1 n using "${int}/norm_pc1.dta"
drop if _merge ==2
drop _merge

* indicators
** (a) zips with rent and price data
gen zori_av = 0
replace zori_av = 1 if ZORI_!=.&ZHVI_!=.
//replace zori_av = 1 if ch_ZORI_log!=.&ch_ZHVI_log!=.

** (b) zips with population >=5,000
gen zip_pop = 0
replace zip_pop = 1 if cns_pop>=5000
unique zip if zip_pop==0&n<=30 //1,591 zips

* rent growth, price growth -- 12 month changes for benchmark sample
local loglist "ZORI_log ZHVI_log ZHVI_B1_log ZHVI_B2_log ZHVI_condo_log ZHVI_sfr_log"
foreach log of local loglist {
	bysort n zip (month): gen l_`log'= `log'[_n-12] if zori_av==1&zori_av[_n-12]==1
	gen ch_`log' = `log' - l_`log' if zori_av==1&zori_av[_n-12]==1
}
drop l_ZORI_log l_ZHVI_*

unique zip if ch_ZORI_log!=.&ch_ZHVI_log!=.&n<=30 //1,722
unique zip if ch_ZORI_log!=.&ch_ZHVI_log!=.&n<=30&month==731 //1,697

* price growth -- 12 month changes for robustness checks
local loglist "ZHVI_log"
foreach log of local loglist {
	bysort n zip (month): gen l_a_`log'= `log'[_n-12]
	gen ch_a_`log' = `log' - l_a_`log'
}
drop l_a_*

sort n zip month


* label variables
label var distance_log "Log(Distance)"
label var teleworkable "Work from Home"
label var log_estab "Log(Restaurants \& Bars)"
label var ch_ZHVI_log " "
label var ch_ZORI_log " "
label var ch_a_ZHVI_log " "
label var ch_ZHVI_B1_log " "
label var ch_ZHVI_B2_log " "
label var ch_ZHVI_condo_log " "
label var ch_ZHVI_sfr_log " "
label var norm_pc1 "Supply Inelasticity Index"
label var totalunavailable_zip "Percent Land Unavailable"
label var cns_median_hh_inc "Median Household Income ('000)"
label var cns_median_age "Median Age"
label var cns_black_ratio "Percent of Black Households"
label var cns_rich_ratio "Share of High Income Households"

estimates clear

* zip level regressions

	* #1: prices for baseline sample, i.e, zhvi with zori_av==1
local ylist "ZHVI ZORI ZHVI_B1 ZHVI_B2 ZHVI_condo ZHVI_sfr"
foreach y of local ylist {
	
	** reg1 
reghdfe ch_`y'_log ///
	distance_log ///
	if zori_av==1&(n<=30)&(month==731), absorb(n, savefe) vce(cluster n)
	estadd local nFE "$\checkmark$"
	estimates store `y'_vsh_dist
	
	** reg2
reghdfe ch_`y'_log ///
	teleworkable ///
	if zori_av==1&(n<=30)&(month==731), absorb(n, savefe) vce(cluster n)
	estadd local nFE "$\checkmark$"
	estimates store `y'_vsh_wfh

	** reg3
reg ch_`y'_log ///
	distance_log teleworkable ///
	if zori_av==1&(n<=30)&(month==731), vce(cluster n)
	estimates store `y'_sh_noFE
	
	** reg4
reghdfe ch_`y'_log ///
	distance_log teleworkable ///
	if zori_av==1&(n<=30)&(month==731), absorb(n, savefe) vce(cluster n)
	estadd local nFE "$\checkmark$"
	estimates store `y'_sh_FE
	
	** reg5
reg ch_`y'_log ///
	distance_log teleworkable ///
	cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio log_estab ///
	if zori_av==1&(n<=30)&(month==731), vce(cluster n)
	estimates store `y'_noFE
	
	** reg6
reghdfe ch_`y'_log ///
	distance_log teleworkable ///
	cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio log_estab ///
	if zori_av==1&(n<=30)&(month==731), absorb(n, savefe) vce(cluster n)
	estadd local nFE "$\checkmark$"	
	estimates store `y'_FE
}

* Table II, Panel A: ZORI
	esttab ZORI* ///
	using "${tables}/ZORI_zip.tex", ///
	stats(nFE N r2 , fmt(0 %12.0f %12.3f) labels( "\\ MSA fixed effects" "\addlinespace Observations" "R squared")) ///
	star(* 0.10 ** 0.05 *** 0.01) nonotes label compress collabels(none) ///
	replace booktabs

* Table II, Panel B: ZHVI
	esttab ZHVI_vsh_dist ZHVI_vsh_wfh ZHVI_sh_noFE ZHVI_sh_FE ZHVI_noFE ZHVI_FE ///
	using "${tables}/ZHVI_zip.tex", ///
	stats(nFE N r2 , fmt(0 %12.0f %12.3f) labels( "\\ MSA fixed effects" "\addlinespace Observations" "R squared")) ///
	star(* 0.10 ** 0.05 *** 0.01) nonotes label compress collabels(none) ///
	replace booktabs

	* #2: prices for robustness
local ylist "a_ZHVI" //
foreach y of local ylist {

** reg6 from above
reghdfe ch_`y'_log ///
	distance_log teleworkable ///
	cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio log_estab ///
	if (n<=30)&(month==731), absorb(n, savefe) vce(cluster n)
	estadd local nFE "$\checkmark$"	
	estimates store `y'_rob

* zips with pop >= 5000
reghdfe ch_`y'_log ///
	distance_log teleworkable ///
	cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio log_estab ///
	if (n<=30)&(month==731)&zip_pop==1, absorb(n, savefe) vce(cluster n)
	estadd local nFE "$\checkmark$"	
	estimates store `y'_zp_rob

* zips pop pweighted
reghdfe ch_`y'_log ///
	distance_log teleworkable ///
	cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio log_estab ///
	if (n<=30)&(month==731) [aw=cns_pop], absorb(n, savefe) vce(cluster n)
	estadd local nFE "$\checkmark$"	
	estimates store `y'_pw_rob

}

	* Table A.III: zip level robustness
	esttab ZHVI_FE a_ZHVI_rob a_ZHVI_zp_rob a_ZHVI_pw_rob ZHVI_B1_FE ZHVI_B2_FE ZHVI_condo_FE ZHVI_sfr_FE ///
	using "${tables}/rob_zip.tex", ///
	stats(nFE N r2 r2_a , fmt(0 %12.0f %12.3f %12.3f) labels( "\\ MSA fixed effects" "\addlinespace Observations" "R squared" "Adj. R squared")) ///
	star(* 0.10 ** 0.05 *** 0.01) label compress collabels(none) ///
	mtitle("Benchmark" "All ZIPs" "Pop$>$5000" "Pop Weight" "Bed1" "Bed2" "Condo" "SFR") ///
	replace booktabs	
	
estimates clear

*================================ end of code =================================*

	
	


	
	
	
