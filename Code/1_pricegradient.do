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
	* This is the main analysis file of this paper
	* plotting prices from MSA core, calculating price gradients

Input:
	* preprocessed.dta

Output:
	(a): Figures
		* Fig 1 (Panel A, B): Rent and Price Gradients across top 30 MSAs
		* Fig 6 (Panel A-H): Robustness in Bid-Rent Curve Estimation Across
						     Price Series
		* Fig A12 (Panel A, B): Determinants of Rent and Price Gradient 
								Changes by MSA

	(b): Tables
		* Table I (Panel A, B): Determinants of Cross-MSA Variation in Rent
								and Price Gradient Changes
		* Table A.II: Explaining the Cross-MSA Variation in Price Gradient
					  Changes
	
	(c): Data
		* grad.dta, which is processed raw data -- used to make plots in python
		* coef.dta, which is input file for many plots
		* norm_pc1.dta, which is input file for 2_csreg_zip.do
	 

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

* loading data price/rent + variables data
use "${int}/preprocessed.dta", clear

* long
reshape long ZHVI_ ZHVI_B1_ ZHVI_B2_ ZHVI_condo_ ZHVI_sfr_ ZORI_ rltr_med_dom_ rltr_act_list_count_ rltr_mlp_ rltr_med_list_ppsqft_ , i(zip) j(month) string

* formatting month
gen miy = substr(month,1,2)
gen year = substr(month,3,4)
destring miy year, replace
drop month
gen month = ym(year, miy)
format month %tm
drop miy

sort cbsa distance month

* indicators
** (a) zips with rent and price data
gen zori_av = 0
replace zori_av = 1 if ZORI_!=.&ZHVI_!=.
unique zip if ZHVI_!=.&ZORI_!=.&n<=30 //1,722


** (b) zips with population >=5,000
gen zip_pop = 0
replace zip_pop = 1 if cns_pop>=5000
unique zip if zip_pop==0&n<=30 //dropping 1,591 zips


* checks and counts
unique zip if ZORI_!=.&n<=30&month>=696&month<=731 
//1727

** (c) zips checking availability of zhvi and zori
unique zip if ZHVI_!=.&ZORI_!=.&n<=30 //1722
unique zip if ZHVI_!=.&ZORI_==.&n<=30 //5579
unique zip if ZHVI_==.&ZORI_!=.&n<=30 //10


replace totalunavailable_zip = totalunavailable_zip/100
replace totalunavailable_cbsa = totalunavailable_cbsa/100

* cleaning ALC
replace rltr_act_list_count_ = . if rltr_act_list_count_ == 0 //getting rid of ACL==0
replace rltr_act_list_count_ = . if rltr_act_list_count_ < 20


* log of prices and quantities
local ylist "ZORI_ ZHVI_B2_ ZHVI_B1_ ZHVI_ ZHVI_condo_ ZHVI_sfr_ rltr_mlp_ rltr_med_list_ppsqft_ rltr_act_list_count_ rltr_med_dom_"
foreach y of local ylist {
	gen `y'log = log(`y')
}

gen distance_log = log(1+ distance)

* log changes in y variables
local ylist "ZHVI_log ZHVI_B1_log ZHVI_B2_log ZHVI_condo_log ZHVI_sfr_log ZORI_log rltr_mlp_log rltr_med_list_ppsqft_log rltr_act_list_count_log rltr_med_dom_log"
foreach y of local ylist {
	bysort cbsa zip (month): gen ll12_`y' = `y'[_n-12]
	gen ld_`y' = `y'-ll12_`y'
}

* % change in prices and quantities
local ylist "ZHVI_ ZHVI_B1_ ZHVI_B2_ ZHVI_condo_ ZHVI_sfr_ ZORI_ rltr_mlp_ rltr_med_list_ppsqft_ rltr_act_list_count_ rltr_med_dom_"
foreach y of local ylist {
	bysort cbsa zip (month): gen l12_`y'= `y'[_n-12]
}

local ylist "ZHVI_ ZHVI_B1_ ZHVI_B2_ ZHVI_condo_ ZHVI_sfr_ ZORI_ rltr_mlp_ rltr_med_list_ppsqft_ rltr_act_list_count_ rltr_med_dom_" 
foreach y of local ylist {
	bysort cbsa zip (month): gen pc_`y'=(`y' - `y'[_n-12])/`y'[_n-12]
}

* data cleaning
replace rltr_med_list_ppsqft_=. if pc_rltr_med_list_ppsqft_>10& pc_rltr_med_list_ppsqft_!=.
replace l12_rltr_med_list_ppsqft_=. if pc_rltr_med_list_ppsqft_>10& pc_rltr_med_list_ppsqft_!=.
replace pc_rltr_med_list_ppsqft_=. if pc_rltr_med_list_ppsqft_>10& pc_rltr_med_list_ppsqft_!=.


sort n distance month

save "${int}/grad.dta", replace


*======================================= Section 1: end ========================================*

*================= Section 2: Top 30 MSA gradient estimation with controls =====================*

use "${int}/grad.dta", clear


* #1: price gradient for baseline sample, i.e, zhvi with zori_av==1
egen tag_zip = tag(zip) if n<=30&ZHVI_log!=.&zori_av==1
gen sample = n<=30&ZHVI_log!=.&zori_av==1

* demean covariates for sample of estimation
local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reghdfe ZHVI_log ///
	i.month i.month#(c.distance_log) ///
	cns_median_hh_inc_dm cns_median_age_dm ///
	cns_black_ratio_dm cns_rich_ratio_dm ///
	if zori_av==1&(n<=30)&(month>=696&month<=731), absorb(n, savefe)

mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zhvi_zoriav_coefs_0
rename coefs2 zhvi_zoriav_se_0

drop *_dm tag_zip sample

local colnames: colnames e(b)
display "`colnames'"

gen name_zhvi_zoriav = ""
local i = 1
foreach var of local colnames {
	replace name_zhvi_zoriav = "`var'" in `i'
	local i = `i'+1
}

* #2: rent gradient for baseline sample, i.e, zori with zori_av==1
egen tag_zip = tag(zip) if n<=30&ZORI_log!=.&zori_av==1
gen sample = n<=30&ZORI_log!=.&zori_av==1

local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reghdfe ZORI_log ///
	i.month i.month#(c.distance_log) ///
	cns_median_hh_inc_dm cns_median_age_dm ///
	cns_black_ratio_dm cns_rich_ratio_dm ///
	if zori_av==1&(n<=30)&(month>=696&month<=731), absorb(n, savefe)
	//[aw = cns_pop]


mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zori_zoriav_coefs_0 //0 stands for all MSAs
rename coefs2 zori_zoriav_se_0

drop *_dm tag_zip sample

local colnames: colnames e(b)
display "`colnames'"

gen name_zori_zoriav = ""
local i = 1
foreach var of local colnames {
	replace name_zori_zoriav = "`var'" in `i'
	local i = `i'+1
}

* #3: zhvi all zips
egen tag_zip = tag(zip) if n<=30&ZHVI_log!=.
gen sample = n<=30&ZHVI_log!=.

* demean covariates for sample of estimation
local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reghdfe ZHVI_log ///
	i.month i.month#(c.distance_log) ///
	cns_median_hh_inc_dm cns_median_age_dm ///
	cns_black_ratio_dm cns_rich_ratio_dm ///
	if (n<=30)&(month>=696&month<=731), absorb(n, savefe)
	//[aw = cns_pop]

mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zhvi_coefs_0
rename coefs2 zhvi_se_0

drop tag_zip *_dm sample

local colnames: colnames e(b)
display "`colnames'"

gen name_zhvi = ""
local i = 1
foreach var of local colnames {
	replace name_zhvi = "`var'" in `i'
	local i = `i'+1
}


* #4: zhvi all zips, pop>=5000
egen tag_zip = tag(zip) if n<=30&ZHVI_log!=.&zip_pop==1
gen sample = n<=30&ZHVI_log!=.&zip_pop==1

* demean covariates for sample of estimation
local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reghdfe ZHVI_log ///
	i.month i.month#(c.distance_log) ///
	cns_median_hh_inc_dm cns_median_age_dm ///
	cns_black_ratio_dm cns_rich_ratio_dm ///
	if zip_pop==1&(n<=30)&(month>=696&month<=731), absorb(n, savefe)
	
	//[aw = cns_pop]

mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zhvi_pop_coefs_0
rename coefs2 zhvi_pop_se_0

drop *_dm tag_zip sample

local colnames: colnames e(b)
display "`colnames'"

gen name_zhvi_pop = ""
local i = 1
foreach var of local colnames {
	replace name_zhvi_pop = "`var'" in `i'
	local i = `i'+1
}

* #5: zhvi all zips, population weighted
egen tag_zip = tag(zip) if n<=30&ZHVI_log!=.
gen sample = n<=30&ZHVI_log!=.

* demean covariates for sample of estimation
local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reghdfe ZHVI_log ///
	i.month i.month#(c.distance_log) ///
	cns_median_hh_inc_dm cns_median_age_dm ///
	cns_black_ratio_dm cns_rich_ratio_dm ///
	if (n<=30)&(month>=696&month<=731) [aw = cns_pop], absorb(n, savefe)
	//

mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zhvi_pw_coefs_0
rename coefs2 zhvi_pw_se_0

drop tag_zip *_dm sample

local colnames: colnames e(b)
display "`colnames'"

gen name_zhvi_pw = ""
local i = 1
foreach var of local colnames {
	replace name_zhvi_pw = "`var'" in `i'
	local i = `i'+1
}


* #6: zhvi b1
egen tag_zip = tag(zip) if n<=30&ZHVI_B1_log!=.
gen sample = n<=30&ZHVI_B1_log!=.

local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reghdfe ZHVI_B1_log ///
	i.month i.month#(c.distance_log) ///
	cns_median_hh_inc_dm cns_median_age_dm ///
	cns_black_ratio_dm cns_rich_ratio_dm ///
	if zori_av==1&(n<=30)&(month>=696&month<=731), absorb(n, savefe)
	//[aw = cns_pop]
	
mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zhvib1_coefs_0
rename coefs2 zhvib1_se_0

drop *_dm tag_zip sample

local colnames: colnames e(b)
display "`colnames'"

gen name_zhvib1 = ""
local i = 1
foreach var of local colnames {
	replace name_zhvib1 = "`var'" in `i'
	local i = `i'+1
}


* #7: zhvi b2
egen tag_zip = tag(zip) if n<=30&ZHVI_B2_log!=.
gen sample = n<=30&ZHVI_B2_log!=.

local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reghdfe ZHVI_B2_log ///
	i.month i.month#(c.distance_log) ///
	cns_median_hh_inc_dm cns_median_age_dm ///
	cns_black_ratio_dm cns_rich_ratio_dm ///
	if zori_av==1&(n<=30)&(month>=696&month<=731) , absorb(n, savefe)
	//[aw = cns_pop]


mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zhvib2_coefs_0
rename coefs2 zhvib2_se_0

drop *_dm tag_zip sample

local colnames: colnames e(b)
display "`colnames'"

gen name_zhvib2 = ""
local i = 1
foreach var of local colnames {
	replace name_zhvib2 = "`var'" in `i'
	local i = `i'+1
}


* #8: zhvi condo
egen tag_zip = tag(zip) if n<=30&ZHVI_condo_log!=.
gen sample = n<=30&ZHVI_condo_log!=.

local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reghdfe ZHVI_condo_log ///
	i.month i.month#(c.distance_log) ///
	cns_median_hh_inc_dm cns_median_age_dm ///
	cns_black_ratio_dm cns_rich_ratio_dm ///
	if zori_av==1&(n<=30)&(month>=696&month<=731), absorb(n, savefe)
	//[aw = cns_pop]

mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zhvic_coefs_0
rename coefs2 zhvic_se_0

drop *_dm tag_zip sample

local colnames: colnames e(b)
display "`colnames'"

gen name_zhvic = ""
local i = 1
foreach var of local colnames {
	replace name_zhvic = "`var'" in `i'
	local i = `i'+1
}


* #9: zhvi sfr
egen tag_zip = tag(zip) if n<=30&ZHVI_sfr_log!=.
gen sample = n<=30&ZHVI_sfr_log!=.

local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reghdfe ZHVI_sfr_log ///
	i.month i.month#(c.distance_log) ///
	cns_median_hh_inc_dm cns_median_age_dm ///
	cns_black_ratio_dm cns_rich_ratio_dm ///
	if zori_av==1&(n<=30)&(month>=696&month<=731), absorb(n, savefe)
	//[aw = cns_pop]

mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zhvisfr_coefs_0
rename coefs2 zhvisfr_se_0

drop *_dm tag_zip sample

local colnames: colnames e(b)
display "`colnames'"

gen name_zhvisfr = ""
local i = 1
foreach var of local colnames {
	replace name_zhvisfr = "`var'" in `i'
	local i = `i'+1
}

* organizing data
keep *_coefs_* *_se_* name_*
keep if name_zhvi_zoriav!=""
gen name_end = substr(name_zhvi_zoriav,-3,.)
keep if name_end == "log"
gen month = substr(name_zhvi_zoriav,1,3)
destring month, replace
format month %tm
drop name_end name_*
order month 

* wide to long
reshape long zhvi_zoriav_coefs_ zhvi_zoriav_se_ zori_zoriav_coefs_ zori_zoriav_se_ zhvi_coefs_ zhvi_se_ zhvi_pop_coefs_ zhvi_pop_se_ zhvi_pw_coefs_ zhvi_pw_se_ zhvib1_coefs_ zhvib1_se_ zhvib2_coefs_ zhvib2_se_ zhvic_coefs_ zhvic_se_ zhvisfr_coefs_ zhvisfr_se_ , i(month) j(n)
sort n month

* zhvi
preserve
keep n month zhvi_zoriav_coefs_ zhvi_zoriav_se_
rename zhvi_zoriav_coefs_ coef_dist_log
rename zhvi_zoriav_se_ se
tempfile zhvi_zoriav
save `zhvi_zoriav', replace
restore

* zori
preserve
keep n month zori_zoriav_coefs_ zori_zoriav_se_
rename zori_zoriav_coefs_ coef_dist_log
rename zori_zoriav_se_ se
tempfile zori_zoriav
save `zori_zoriav', replace
restore

* zhvi
preserve
keep n month zhvi_coefs_ zhvi_se_
rename zhvi_coefs_ coef_dist_log
rename zhvi_se_ se
tempfile zhvi
save `zhvi', replace
restore

* zhvi pop>=5000
preserve
keep n month zhvi_pop_coefs_ zhvi_pop_se_
rename zhvi_pop_coefs_ coef_dist_log
rename zhvi_pop_se_ se
tempfile zhvi_pop
save `zhvi_pop', replace
restore

* zhvi pop weighted
preserve
keep n month zhvi_pw_coefs_ zhvi_pw_se_
rename zhvi_pw_coefs_ coef_dist_log
rename zhvi_pw_se_ se
tempfile zhvi_pw
save `zhvi_pw', replace
restore

* b1
preserve
keep n month zhvib1_coefs_ zhvib1_se_
rename zhvib1_coefs_ coef_dist_log
rename zhvib1_se_ se
tempfile zhvib1
save `zhvib1', replace
restore

* b2
preserve
keep n month zhvib2_coefs_ zhvib2_se_
rename zhvib2_coefs_ coef_dist_log
rename zhvib2_se_ se
tempfile zhvib2
save `zhvib2', replace
restore

* condo
preserve
keep n month zhvic_coefs_ zhvic_se_
rename zhvic_coefs_ coef_dist_log
rename zhvic_se_ se
tempfile zhvic
save `zhvic', replace
restore

* sfr
preserve
keep n month zhvisfr_coefs_ zhvisfr_se_
rename zhvisfr_coefs_ coef_dist_log
rename zhvisfr_se_ se
tempfile zhvisfr
save `zhvisfr', replace
restore

use `zhvi_zoriav', clear
gen yvar = "zhvi_zoriav"
append using `zori_zoriav'
replace yvar = "zori_zoriav" if yvar == ""
append using `zhvi'
replace yvar = "zhvi" if yvar == ""
append using `zhvi_pop'
replace yvar = "zhvi_pop" if yvar == ""
append using `zhvi_pw'
replace yvar = "zhvi_pw" if yvar == ""
append using `zhvib1'
replace yvar = "zhvi b1" if yvar == ""
append using `zhvib2'
replace yvar = "zhvi b2" if yvar == ""
append using `zhvic'
replace yvar = "zhvi condo" if yvar == ""
append using `zhvisfr'
replace yvar = "zhvi sfr" if yvar == ""

* standard errors
gen ub = coef_dist_log + 1.65*se
gen lb = coef_dist_log - 1.65*se

* creating series for short figure
gen coef_dist_log_sh = coef_dist_log
gen ub_sh = ub
gen lb_sh = lb
replace coef_dist_log_sh = . if month>720
replace ub_sh = . if month>720
replace lb_sh = . if month>720

* #1: zhvi zori av
	twoway (connected coef_dist_log month if (yvar=="zhvi_zoriav"), lwidth(thin) lpattern("-") lcolor(edkblue%50) msymbol(S) mcolor(edkblue) msize(small) yaxis(1)) (rcap ub lb month if (yvar=="zhvi_zoriav"), lwidth(vthin) lpattern("l") lcolor(red%50)  yaxis(1)), ///
	xline(720, lcolor(black)) xlabel(696 "2018m1" 702 "2018m7" 708 "2019m1" 714 "2019m7" 720 "2020m1" 726 "2020m7") ylabel(-0.13 (0.02) -0.07) graphregion(color(white)) xtitle("Month") ytitle("Gradient elasticity w.r.t. zhvi", axis(1)) ///
	text(-0.08 724 "{&Delta} {&delta} = 0.012") ///
	legend(order(1 "Estimates" 2 "Bounds")) ///
	ylabel(,angle(360) format(%9.3fc) axis(1))
	
	graph export "${figures}/zhvi_grad1_t30_rr.pdf", replace
	

* #2: zori zori av
	twoway (connected coef_dist_log month if (yvar=="zori_zoriav"), lwidth(thin) lpattern("-") lcolor(edkblue%50) msymbol(S) mcolor(edkblue) msize(small) yaxis(1)) (rcap ub lb month if (yvar=="zori_zoriav"), lwidth(vthin) lpattern("l") lcolor(red%50)  yaxis(1)), ///
	xline(720, lcolor(black)) xlabel(696 "2018m1" 702 "2018m7" 708 "2019m1" 714 "2019m7" 720 "2020m1" 726 "2020m7") ylabel(-0.05 (0.01) 0.01) graphregion(color(white)) xtitle("Month") ytitle("Gradient elasticity w.r.t. zori", axis(1)) ///
	text(0 724 "{&Delta} {&delta} = 0.032") ///
	legend(order(1 "Estimates" 2 "Bounds")) ///
	ylabel(,angle(360) format(%9.3fc) axis(1))
	
	graph export "${figures}/zori_grad1_t30_rr.pdf", replace
	
* #3: zhvi all zips
	twoway (connected coef_dist_log month if (yvar=="zhvi"), lwidth(thin) lpattern("-") lcolor(edkblue%50) msymbol(S) mcolor(edkblue) msize(small) yaxis(1)) (rcap ub lb month if (yvar=="zhvi"), lwidth(vthin) lpattern("l") lcolor(red%50)  yaxis(1)), ///
	xline(720, lcolor(black)) xlabel(696 "2018m1" 702 "2018m7" 708 "2019m1" 714 "2019m7" 720 "2020m1" 726 "2020m7") ylabel(-0.15 (0.02) -0.09) graphregion(color(white)) xtitle("Month") ytitle("Gradient elasticity w.r.t. zhvi", axis(1)) ///
	text(-0.10 724 "{&Delta} {&delta} = 0.001") ///
	legend(order(1 "Estimates" 2 "Bounds")) ///
	ylabel(,angle(360) format(%9.3fc) axis(1))
	
	graph export "${figures}/zhvi_grad1_t30.pdf", replace
	
* #4: zhvi pop >=5000
	twoway (connected coef_dist_log month if (yvar=="zhvi_pop"), lwidth(thin) lpattern("-") lcolor(edkblue%50) msymbol(S) mcolor(edkblue) msize(small) yaxis(1)) (rcap ub lb month if (yvar=="zhvi_pop"), lwidth(vthin) lpattern("l") lcolor(red%50)  yaxis(1)), ///
	xline(720, lcolor(black)) xlabel(696 "2018m1" 702 "2018m7" 708 "2019m1" 714 "2019m7" 720 "2020m1" 726 "2020m7") ylabel(-0.14 (0.02) -0.08) graphregion(color(white)) xtitle("Month") ytitle("Gradient elasticity w.r.t. zhvi", axis(1)) ///
	text(-0.09 724 "{&Delta} {&delta} = 0.003") ///
	legend(order(1 "Estimates" 2 "Bounds")) ///
	ylabel(,angle(360) format(%9.3fc) axis(1))
	
	graph export "${figures}/zhvi_grad1_t30_pop.pdf", replace

* #5: zhvi pop weighted
	twoway (connected coef_dist_log month if (yvar=="zhvi_pw"), lwidth(thin) lpattern("-") lcolor(edkblue%50) msymbol(S) mcolor(edkblue) msize(small) yaxis(1)) (rcap ub lb month if (yvar=="zhvi_pw"), lwidth(vthin) lpattern("l") lcolor(red%50)  yaxis(1)), ///
	xline(720, lcolor(black)) xlabel(696 "2018m1" 702 "2018m7" 708 "2019m1" 714 "2019m7" 720 "2020m1" 726 "2020m7") ylabel(-0.15 (0.02) -0.09) graphregion(color(white)) xtitle("Month") ytitle("Gradient elasticity w.r.t. zhvi", axis(1)) ///
	text(-0.10 724 "{&Delta} {&delta} = 0.005") ///
	legend(order(1 "Estimates" 2 "Bounds")) ///
	ylabel(,angle(360) format(%9.3fc) axis(1))
	
	graph export "${figures}/zhvi_grad1_t30_pw.pdf", replace

* #6: zhvi b1
	twoway (connected coef_dist_log month if (yvar=="zhvi b1"), lwidth(thin) lpattern("-") lcolor(edkblue%50) msymbol(S) mcolor(edkblue) msize(small) yaxis(1)) (rcap ub lb month if (yvar=="zhvi b1"), lwidth(vthin) lpattern("l") lcolor(red%50)  yaxis(1)), ///
	xline(720, lcolor(black)) xlabel(696 "2018m1" 702 "2018m7" 708 "2019m1" 714 "2019m7" 720 "2020m1" 726 "2020m7") ylabel(-0.14 (0.02) -0.08) graphregion(color(white)) xtitle("Month") ytitle("Gradient elasticity w.r.t. zhvi b1", axis(1)) ///
	text(-0.09 724 "{&Delta} {&delta} = 0.018") ///
	legend(order(1 "Estimates" 2 "Bounds")) ///
	ylabel(,angle(360) format(%9.3fc) axis(1))
	
	graph export "${figures}/zhvi b1_grad1_t30_rr.pdf", replace	
	
* #7: zhvi b2
	twoway (connected coef_dist_log month if (yvar=="zhvi b2"), lwidth(thin) lpattern("-") lcolor(edkblue%50) msymbol(S) mcolor(edkblue) msize(small) yaxis(1)) (rcap ub lb month if (yvar=="zhvi b2"), lwidth(vthin) lpattern("l") lcolor(red%50)  yaxis(1)), ///
	xline(720, lcolor(black)) xlabel(696 "2018m1" 702 "2018m7" 708 "2019m1" 714 "2019m7" 720 "2020m1" 726 "2020m7") ylabel(-0.2 (0.02) -0.14) graphregion(color(white)) xtitle("Month") ytitle("Gradient elasticity w.r.t. zhvi b2", axis(1)) ///
	text(-0.15 724 "{&Delta} {&delta} = 0.013") ///
	legend(order(1 "Estimates" 2 "Bounds")) ///
	ylabel(,angle(360) format(%9.3fc) axis(1))
	
	graph export "${figures}/zhvi b2_grad1_t30_rr.pdf", replace	

* #8: zhvi condo
	twoway (connected coef_dist_log month if (yvar=="zhvi condo"), lwidth(thin) lpattern("-") lcolor(edkblue%50) msymbol(S) mcolor(edkblue) msize(small) yaxis(1)) (rcap ub lb month if (yvar=="zhvi condo"), lwidth(vthin) lpattern("l") lcolor(red%50)  yaxis(1)), ///
	xline(720, lcolor(black)) xlabel(696 "2018m1" 702 "2018m7" 708 "2019m1" 714 "2019m7" 720 "2020m1" 726 "2020m7") ylabel(-0.13 (0.02) -0.07) graphregion(color(white)) xtitle("Month") ytitle("Gradient elasticity w.r.t. zhvi condo", axis(1)) ///
	text(-0.08 724 "{&Delta} {&delta} = 0.016") ///
	legend(order(1 "Estimates" 2 "Bounds")) ///
	ylabel(,angle(360) format(%9.3fc) axis(1))
	
	graph export "${figures}/zhvi condo_grad1_t30_rr.pdf", replace	

* #9: zhvi sfr
	twoway (connected coef_dist_log month if (yvar=="zhvi sfr"), lwidth(thin) lpattern("-") lcolor(edkblue%50) msymbol(S) mcolor(edkblue) msize(small) yaxis(1)) (rcap ub lb month if (yvar=="zhvi sfr"), lwidth(vthin) lpattern("l") lcolor(red%50)  yaxis(1)), ///
	xline(720, lcolor(black)) xlabel(696 "2018m1" 702 "2018m7" 708 "2019m1" 714 "2019m7" 720 "2020m1" 726 "2020m7") ylabel(-0.16 (0.02) -0.10) graphregion(color(white)) xtitle("Month") ytitle("Gradient elasticity w.r.t. zhvi sfr", axis(1)) ///
	text(-0.11 724 "{&Delta} {&delta} = 0.011") ///
	legend(order(1 "Estimates" 2 "Bounds")) ///
	ylabel(,angle(360) format(%9.3fc) axis(1))
	
	graph export "${figures}/zhvi sfr_grad1_t30_rr.pdf", replace	


*======================================= Section 2: end ========================================*

*=============== Section 3: Individual MSA gradient estimation with controls ===================*

use "${int}/grad.dta", clear

* #1: zhvi with zori_av==1
forvalues nmsa = 1(1)30 {

egen tag_zip = tag(zip) if n==`nmsa'&ZHVI_log!=.&zori_av==1
gen sample = n==`nmsa'&ZHVI_log!=.&zori_av==1

* demean covariates for sample of estimation
local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reg ZHVI_log i.month i.month#(c.distance_log) cns_median_hh_inc_dm cns_median_age_dm cns_black_ratio_dm cns_rich_ratio_dm if (n==`nmsa')&(month>=696&month<=731)&zori_av==1 
//[aw=cns_pop]

//ereturn list
mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zhvi_zoriav_coefs_`nmsa'
rename coefs2 zhvi_zoriav_se_`nmsa'

drop tag_zip *_dm sample

}

local colnames: colnames e(b)
display "`colnames'"

gen name = ""
local i = 1
foreach var of local colnames {
	replace name = "`var'" in `i'
	local i = `i'+1
}

* #2: zori with zori_av==1
forvalues nmsa = 1(1)30 {

egen tag_zip = tag(zip) if n==`nmsa'&ZORI_log!=.&zori_av==1
gen sample = n==`nmsa'&ZORI_log!=.&zori_av==1

* demean covariates for sample of estimation
local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reg ZORI_log i.month i.month#(c.distance_log) cns_median_hh_inc_dm cns_median_age_dm cns_black_ratio_dm cns_rich_ratio_dm if (n==`nmsa')&(month>=696&month<=731)&zori_av==1 
//[aw=cns_pop]

//ereturn list
mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zori_zoriav_coefs_`nmsa'
rename coefs2 zori_zoriav_se_`nmsa'

drop tag_zip *_dm sample

}

* #3: zhvi all zips
forvalues nmsa = 1(1)30 {

egen tag_zip = tag(zip) if n==`nmsa'&ZHVI_log!=.
gen sample = n==`nmsa'&ZHVI_log!=.

* demean covariates for sample of estimation
local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reg ZHVI_log i.month i.month#(c.distance_log) cns_median_hh_inc_dm cns_median_age_dm cns_black_ratio_dm cns_rich_ratio_dm if (n==`nmsa')&(month>=696&month<=731)
//[aw=cns_pop]

//ereturn list
mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zhvi_coefs_`nmsa'
rename coefs2 zhvi_se_`nmsa'

drop tag_zip *_dm sample

}

* #4: zhvi all zips, pop >=5000
forvalues nmsa = 1(1)30 {

egen tag_zip = tag(zip) if n==`nmsa'&ZHVI_log!=.&zip_pop==1
gen sample = n==`nmsa'&ZHVI_log!=.&zip_pop==1

* demean covariates for sample of estimation
local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reg ZHVI_log i.month i.month#(c.distance_log) cns_median_hh_inc_dm cns_median_age_dm cns_black_ratio_dm cns_rich_ratio_dm if (n==`nmsa')&(month>=696&month<=731)&zip_pop==1

//ereturn list
mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zhvi_pop_coefs_`nmsa'
rename coefs2 zhvi_pop_se_`nmsa'

drop tag_zip *_dm sample

}

* #5: zhvi all zips, pop weighted
forvalues nmsa = 1(1)30 {

egen tag_zip = tag(zip) if n==`nmsa'&ZHVI_log!=.
gen sample = n==`nmsa'&ZHVI_log!=.

* demean covariates for sample of estimation
local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reg ZHVI_log i.month i.month#(c.distance_log) cns_median_hh_inc_dm cns_median_age_dm cns_black_ratio_dm cns_rich_ratio_dm if (n==`nmsa')&(month>=696&month<=731) [aw=cns_pop]
//

//ereturn list
mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zhvi_pw_coefs_`nmsa'
rename coefs2 zhvi_pw_se_`nmsa'

drop tag_zip *_dm sample

}

* #6: zhvi b1
forvalues nmsa = 1(1)30 {

egen tag_zip = tag(zip) if n==`nmsa'&ZHVI_B1_log!=.
gen sample = n==`nmsa'&ZHVI_B1_log!=.

local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reg ZHVI_B1_log i.month i.month#(c.distance_log) cns_median_hh_inc_dm cns_median_age_dm cns_black_ratio_dm cns_rich_ratio_dm if (n==`nmsa')&(month>=696&month<=731)&zori_av==1 


mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zhvib1_coefs_`nmsa'
rename coefs2 zhvib1_se_`nmsa'

drop tag_zip *_dm sample
}

* #7: zhvi b2
forvalues nmsa = 1(1)30 {

egen tag_zip = tag(zip) if n==`nmsa'&ZHVI_B2_log!=.
gen sample = n==`nmsa'&ZHVI_B2_log!=.

local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reg ZHVI_B2_log i.month i.month#(c.distance_log) cns_median_hh_inc_dm cns_median_age_dm cns_black_ratio_dm cns_rich_ratio_dm if (n==`nmsa')&(month>=696&month<=731)&zori_av==1 
//[aw=cns_pop]

mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zhvib2_coefs_`nmsa'
rename coefs2 zhvib2_se_`nmsa'

drop tag_zip *_dm sample
}

* #8: zhvi condo
* note: skip msa 11, no nonmissing ZHVI condo
forvalues nmsa = 1(1)30 {
	if inlist(`nmsa',11) continue

egen tag_zip = tag(zip) if n==`nmsa'&ZHVI_condo_log!=.
gen sample = n==`nmsa'&ZHVI_condo_log!=.

local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reg ZHVI_condo_log i.month i.month#(c.distance_log) cns_median_hh_inc_dm cns_median_age_dm cns_black_ratio_dm cns_rich_ratio_dm if (n==`nmsa')&(month>=696&month<=731)&zori_av==1 

mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zhvic_coefs_`nmsa'
rename coefs2 zhvic_se_`nmsa'

drop tag_zip *_dm sample
}

* #9: zhvi sfr
* note: skip msa 11, no nonmissing ZHVI sfr
forvalues nmsa = 1(1)30 {
	if inlist(`nmsa',11) continue

egen tag_zip = tag(zip) if n==`nmsa'&ZHVI_sfr_log!=.
gen sample = n==`nmsa'&ZHVI_sfr_log!=.

local covlist "cns_median_hh_inc cns_median_age cns_black_ratio cns_rich_ratio"
foreach var of local covlist {
	sum `var' if sample&tag_zip==1
	gen `var'_dm = `var' - `r(mean)'
}

reg ZHVI_sfr_log i.month i.month#(c.distance_log) cns_median_hh_inc_dm cns_median_age_dm cns_black_ratio_dm cns_rich_ratio_dm if (n==`nmsa')&(month>=696&month<=731)&zori_av==1

mata: cov = st_matrix("e(V)")
mata: se = sqrt(diagonal(cov))
mata: b = st_matrix("e(b)")
mata: coef = b'
mata: mat_out = coef,se
mata: st_matrix("coefs",mat_out)

svmat coefs
rename coefs1 zhvisfr_coefs_`nmsa'
rename coefs2 zhvisfr_se_`nmsa'

drop tag_zip *_dm sample
}


* organizing data
keep *_coefs_* *_se_* name
gen name_end = substr(name,-3,.)
keep if name_end == "log"
gen month = substr(name,1,3)
drop if month=="695" //plotting from 2018 onwards
destring month, replace
format month %tm
drop name_end name
order month 

* wide to long
reshape long zhvi_zoriav_coefs_ zhvi_zoriav_se_ zori_zoriav_coefs_ zori_zoriav_se_ zhvi_coefs_ zhvi_se_ zhvi_pop_coefs_ zhvi_pop_se_ zhvi_pw_coefs_ zhvi_pw_se_ zhvib1_coefs_ zhvib1_se_ zhvib2_coefs_ zhvib2_se_ zhvic_coefs_ zhvic_se_ zhvisfr_coefs_ zhvisfr_se_, i(month) j(n)
sort n month


* #1: zhvi zori av
preserve
keep n month zhvi_zoriav_coefs_ zhvi_zoriav_se_
rename zhvi_zoriav_coefs_ coef_dist_log
rename zhvi_zoriav_se_ se
tempfile zhvi_zoriav_coefs
save `zhvi_zoriav_coefs', replace
restore

* #2: zori zori av
preserve
keep n month zori_zoriav_coefs_ zori_zoriav_se_
rename zori_zoriav_coefs_ coef_dist_log
rename zori_zoriav_se_ se
tempfile zori_zoriav_coefs
save `zori_zoriav_coefs', replace
restore

* #3: zhvi
preserve
keep n month zhvi_coefs_ zhvi_se_
rename zhvi_coefs_ coef_dist_log
rename zhvi_se_ se
tempfile zhvi_coefs
save `zhvi_coefs', replace
restore

* #4: zhvi pop
preserve
keep n month zhvi_pop_coefs_ zhvi_pop_se_
rename zhvi_pop_coefs_ coef_dist_log
rename zhvi_pop_se_ se
tempfile zhvi_pop_coefs
save `zhvi_pop_coefs', replace
restore

* #5: zhvi pw
preserve
keep n month zhvi_pw_coefs_ zhvi_pw_se_
rename zhvi_pw_coefs_ coef_dist_log
rename zhvi_pw_se_ se
tempfile zhvi_pw_coefs
save `zhvi_pw_coefs', replace
restore

* #6: zhvi b1
preserve
keep n month zhvib1_coefs_ zhvib1_se_
rename zhvib1_coefs_ coef_dist_log
rename zhvib1_se_ se
tempfile zhvib1_coefs
save `zhvib1_coefs', replace
restore

* #7: zhvi b2
preserve
keep n month zhvib2_coefs_ zhvib2_se_
rename zhvib2_coefs_ coef_dist_log
rename zhvib2_se_ se
tempfile zhvib2_coefs
save `zhvib2_coefs', replace
restore

* #8: zhvic
preserve
keep n month zhvic_coefs_ zhvic_se_
rename zhvic_coefs_ coef_dist_log
rename zhvic_se_ se
tempfile zhvic_coefs
save `zhvic_coefs', replace
restore

* #9: zhvi sfr
preserve
keep n month zhvisfr_coefs_ zhvisfr_se_
rename zhvisfr_coefs_ coef_dist_log
rename zhvisfr_se_ se
tempfile zhvisfr_coefs
save `zhvisfr_coefs', replace
restore

use `zhvi_zoriav_coefs', clear
gen yvar = "zhvi_zoriav"
append using `zori_zoriav_coefs'
replace yvar = "zori_zoriav" if yvar == ""
append using `zhvi_coefs'
replace yvar = "zhvi" if yvar == ""
append using `zhvi_pop_coefs'
replace yvar = "zhvi_pop" if yvar == ""
append using `zhvi_pw_coefs'
replace yvar = "zhvi_pw" if yvar == ""
append using `zhvib1_coefs'
replace yvar = "zhvib1" if yvar == ""
append using `zhvib2_coefs'
replace yvar = "zhvib2" if yvar == ""
append using `zhvic_coefs'
replace yvar = "zhvicondo" if yvar == ""
append using `zhvisfr_coefs'
replace yvar = "zhvisfr" if yvar == ""

* standard errors
gen ub = coef_dist_log + 1.65*se
gen lb = coef_dist_log - 1.65*se
gen yvarnum=1 if yvar=="zhvi_zoriav"
replace yvarnum=2 if yvar=="zori_zoriav"
replace yvarnum=3 if yvar=="zhvi"
replace yvarnum=4 if yvar=="zhvi_pop"
replace yvarnum=5 if yvar=="zhvi_pw"
replace yvarnum=6 if yvar == "zhvib1"
replace yvarnum=7 if yvar == "zhvib2"
replace yvarnum=8 if yvar == "zhvicondo"
replace yvarnum=9 if yvar == "zhvisfr"
sort n yvarnum month
save "${int}/coef.dta", replace

*======================================= Section 3: end ========================================*

*======================= Section 4: MSA cross-sectional regressions ============================*

* merging coef data with grad data
use "${int}/grad.dta", clear
unique n zip month //693,514 unique and total
sort n zip month
fcollapse (mean) stringencyindex teleworkable_cbsa WRLURI18_cbsa supplyelasticity totalunavailable_cbsa (mean) ZORI_ ZHVI_B2_ ZHVI_B1_ ZHVI_ ZHVI_condo_ ZHVI_sfr_ pc_* [aw=cns_pop], by(n month)
save "${int}/grad_c.dta", replace


use "${int}/coef.dta" , clear
unique n month
sort n yvarnum month
bysort n yvarnum (month): gen coef_dist_log_ch = coef_dist_log-coef_dist_log[_n-12]
sort n yvarnum month

merge m:1 n month using "${int}/grad_c.dta" //n==0 not matched
drop if _merge==1 // dropping n=0
drop _merge

sort n yvarnum month

* stringencyindex 
replace stringencyindex = stringencyindex/100

label var coef_dist_log_ch " "
label var WRLURI18_cbsa "Wharton Regulatory Index"
label var teleworkable_cbsa "Work from Home"
label var supplyelasticity "Saiz Supply Elasticity"
label var totalunavailable_cbsa "Land Unavailable Percent"
label var stringencyindex "Stringency Measure"

* PCA
pca totalunavailable_cbsa supplyelasticity WRLURI18_cbsa if yvar=="zhvi"&month==731&n>=1&n<=30
predict pc1 pc2, score

label var pc1 "Supply Inelasticity Index"
* normalizing supply inelasticity index
egen max_pc1 = max(pc1)
egen min_pc1 = min(pc1)
gen norm_pc1 = (pc1-min_pc1)/(max_pc1-min_pc1)
label var norm_pc1 "Supply Inelasticity Index"

* exporting norm_pc1 for zip-level regressions
preserve
keep n norm_pc1
duplicates drop
save "${int}/norm_pc1.dta", replace
restore

* orthogonalized str and pc
reg stringencyindex teleworkable_cbsa if yvar=="zhvi_zoriav"&month==731&n>=1&n<=30 //same for any yvar
predict pred_str
predict eps_str, residuals
	
reg norm_pc1 teleworkable_cbsa eps_str if yvar=="zhvi_zoriav"&month==731&n>=1&n<=30
predict pred_pc1
predict eps_pc1, residuals
	
label var eps_str "Orthogonalized Stringency Index"
label var eps_pc1 "Orthogonalized Supply Inelasticity"


estimates clear

local yvar "zhvi_zoriav zori_zoriav zhvi zhvi_pop zhvi_pw zhvib1 zhvib2 zhvicondo zhvisfr"
foreach y of local yvar {
	* Dingel-Neiman WFH measure
	reg coef_dist_log_ch teleworkable_cbsa if yvar=="`y'"&month==731&n>=1&n<=30
	estimates store wfm_`y'
	
	* stringency measure
	reg coef_dist_log_ch stringencyindex if yvar=="`y'"&month==731&n>=1&n<=30
	estimates store str_`y'
	
	* pc alone
	reg coef_dist_log_ch norm_pc1 if yvar=="`y'"&month==731&n>=1&n<=30
	estimates store pc1_`y'
	
	* all three together
	reg coef_dist_log_ch teleworkable_cbsa stringencyindex norm_pc1 if yvar=="`y'"&month==731&n>=1&n<=30
	estimates store three_`y'
	
	* all three together -- orthogonalized
	reg coef_dist_log_ch teleworkable_cbsa eps_str eps_pc1 if yvar=="`y'"&month==731&n>=1&n<=30
	estimates store three_orth_`y'
	if inlist("`y'", "zhvi", "zhvi_pop", "zhvi_pw", "zhvib1", "zhvib2", "zhvicondo", "zhvisfr") continue
	gen b_teleworkable_`y' = _b[teleworkable_cbsa] if yvar == "`y'"
	gen b_eps_str_`y' = _b[eps_str] if yvar == "`y'"
	gen b_eps_pc1_`y' = _b[eps_pc1] if yvar == "`y'"
	
	
}
	

* Exporting tables to latex -- pc

	* Table 1 (Panel A) -- ZORI
	esttab wfm_zori_zoriav str_zori_zoriav pc1_zori_zoriav three_zori_zoriav three_orth_zori_zoriav ///
	using "${tables}/pc_zori_rr.tex", ///
	se r2 ///
	star(* 0.10 ** 0.05 *** 0.01) nonotes label compress collabels(none) ///
	replace booktabs
	
	* Table 1 (Panel B) -- ZHVI
	esttab wfm_zhvi_zoriav str_zhvi_zoriav pc1_zhvi_zoriav three_zhvi_zoriav three_orth_zhvi_zoriav ///
	using "${tables}/pc_zhvi_rr.tex", ///
	se r2 ///
	star(* 0.10 ** 0.05 *** 0.01) nonotes label compress collabels(none) ///
	replace booktabs
	
	* Table A.II -- Robustness table
	esttab three_orth_zhvi_zoriav three_orth_zhvi three_orth_zhvi_pop three_orth_zhvi_pw three_orth_zhvib1 three_orth_zhvib2 three_orth_zhvicondo three_orth_zhvisfr using "${tables}/pc_zhvi_rob.tex", ///
	se r2 ar2 ///
	star(* 0.10 ** 0.05 *** 0.01) label compress collabels(none) ///
	mtitle("Benchmark" "All ZIPs" "Pop$>$5000" "Pop Weight" "Bed1" "Bed2" "Condo" "SFR") ///
	replace booktabs
	
	
* calculations for bar plots
gen wfh_zhvi = b_teleworkable_zhvi_zoriav*teleworkable_cbsa if yvar=="zhvi_zoriav"&month==731&n>=1&n<=30
gen str_zhvi = b_eps_str_zhvi_zoriav* eps_str if yvar=="zhvi_zoriav"&month==731&n>=1&n<=30
gen pc1_zhvi = b_eps_pc1_zhvi_zoriav* eps_pc1 if yvar=="zhvi_zoriav"&month==731&n>=1&n<=30

gen wfh_zori = b_teleworkable_zori_zoriav*teleworkable_cbsa if yvar=="zori_zoriav"&month==731&n>=1&n<=30
gen str_zori = b_eps_str_zori_zoriav* eps_str if yvar=="zori_zoriav"&month==731&n>=1&n<=30
gen pc1_zori = b_eps_pc1_zori_zoriav* eps_pc1 if yvar=="zori_zoriav"&month==731&n>=1&n<=30

* fig A.12 of the paper
	graph hbar wfh_zhvi str_zhvi pc1_zhvi if yvar=="zhvi_zoriav"&month==731&n>=1&n<=30, over(n, sort(wfh_zhvi) descending label(labsize(vsmall)) relabel(1 "New York" 2 "Los Angeles" 3 "Chicago" 4 "Dallas" 5 "Houston" 6 "Washington" 7 "Miami" 8 "Philadelphia" 9 "Atlanta" 10 "Phoenix" 11 "Boston" 12 "San Francisco" 13 "Riverside" 14 "Detroit" 15 "Seattle" 16 "Minneapolis" 17 "San Diego" 18 "Tampa" 19 "Denver" 20 "St. Louis" 21 "Baltimore" 22 "Charlotte" 23 "Orlando" 24 "San Antonio" 25 "Portland" 26 "Sacramento" 27 "Pittsburgh" 28 "Las Vegas" 29 "Austin" 30 "Cincinnati")) nofill stack ///
	bar(1, fcolor(edkblue) lcolor(edkblue)) bar(2, fcolor(cranberry) lcolor(cranberry)) bar(3, fcolor(green) lcolor(green)) ///
	legend(order(1 "Work from Home" 2 "Stringency" 3 "Supply Inelasticity")) ylabel(0(0.025)0.1, angle(360)) ytitle("Coefficient times Variable") b1title(" ") graphregion(color(white))
	
	gr export "${figures}/msa_contr_zhvi.pdf", replace

	
* fig A.12 of the paper
	graph hbar wfh_zori str_zori pc1_zori if yvar=="zori_zoriav"&month==731&n>=1&n<=30, over(n, sort(wfh_zori) descending label(labsize(vsmall)) relabel(1 "New York" 2 "Los Angeles" 3 "Chicago" 4 "Dallas" 5 "Houston" 6 "Washington" 7 "Miami" 8 "Philadelphia" 9 "Atlanta" 10 "Phoenix" 11 "Boston" 12 "San Francisco" 13 "Riverside" 14 "Detroit" 15 "Seattle" 16 "Minneapolis" 17 "San Diego" 18 "Tampa" 19 "Denver" 20 "St. Louis" 21 "Baltimore" 22 "Charlotte" 23 "Orlando" 24 "San Antonio" 25 "Portland" 26 "Sacramento" 27 "Pittsburgh" 28 "Las Vegas" 29 "Austin" 30 "Cincinnati")) nofill stack ///
	bar(1, fcolor(edkblue) lcolor(edkblue)) bar(2, fcolor(cranberry) lcolor(cranberry)) bar(3, fcolor(green) lcolor(green)) ///
	legend(order(1 "Work from Home" 2 "Stringency" 3 "Supply Inelasticity")) ylabel(0(0.05)0.15, angle(360)) ytitle("Coefficient times Variable") b1title(" ") graphregion(color(white))
	
	gr export "${figures}/msa_contr_zori.pdf", replace


*================================ end of code =================================*








