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
	* Section V zip level analysis for Fig A13

Input:
	* preprocessed.dta

Output:
	(a): Data
		* g_zip.dta -- is the input for Fig A13	
	
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

drop rltr_* ZHVI_B1_* ZHVI_B2_* ZHVI_condo_* ZHVI_sfr_*

gen urban = 1 if distance <= 10
replace urban=0 if missing(urban)
gen suburban = 1 if distance >= 40
replace suburban=0 if missing(suburban)

* long
reshape long ZHVI_ ZORI_ , i(zip) j(month) string

* formatting month
gen miy = substr(month,1,2)
gen year = substr(month,3,4)
destring miy year, replace
drop month
gen month = ym(year, miy)
format month %tm
drop miy year
order n cbsa zip distance month

* annualizing zori
replace ZORI_ = ZORI_*12

* monthly ZORI
gen ZORI_m_ = ZORI_/12

* log distance
gen distance_log = log(1+distance)

*  log of prices and rents
local ylist "ZHVI_ ZORI_ ZORI_m_"
foreach y of local ylist {
	gen `y'log = log(`y')
}

gen pd = ZHVI_log - ZORI_log
gen PD_raw = ZHVI_/ZORI_ //for graph -- plotting in levels

* calculating zip level pd ratios

* pd_t^i = pdbar^i + A (g_t^i - gbar_i) - B (x_t^i - xbar^i)
* pdbar^i corresponds to pdbar from jan 2014 to dec 2019

* rent growth, price growth and pd growth
local loglist "ZORI_log ZHVI_log ZORI_m_log pd"
foreach log of local loglist {
	bysort n zip (month): gen l_`log'= `log'[_n-12]
	gen ch_`log' = `log' - l_`log'
}
drop l_ZORI_log l_ZHVI_log l_ZORI_m_log l_pd

* pdbar and gbar
bysort zip (month): egen pdbar = mean(pd) if month<=719 //pdbar
bysort zip (month): replace pdbar = pdbar[1] if missing(pdbar)
bysort zip (month): egen gbar = mean(ch_ZORI_log) if month<=719 //gbar
bysort zip (month): replace gbar = gbar[1] if missing(gbar)

* pd post
bysort zip (month): egen pdpost = mean(pd) if month>=729&month<=731
bysort zip (month): replace pdpost = pdpost[_N] if missing(pdpost)

* pd_ch
gen pd_ch = pdpost - pdbar

* collapse at zip level
keep n cbsa zip distance distance_log pdpost pdbar pd_ch gbar cns_pop
//pop_2019
fcollapse (first) cns_pop n cbsa distance distance_log pdpost pdbar pd_ch gbar, by(zip)
//pop_2019

* rho_j @ zip level
gen pdbar_exp = exp(pdbar)
gen rho_z = pdbar_exp/(1+pdbar_exp)
* rho_g and rho_x
gen rho_g = 0.747
gen rho_x = 0.917
* assumptions on change in x: deltax=0, deltax=0.01
gen chx0 = 0
gen chx001 = 0.01

* cumulative change transitory @ zip level
gen cumg_chx0 = (gbar/(1-rho_z*rho_g)) + pd_ch + (chx0/(1-rho_z*rho_x))
gen cumg_chx001 = (gbar/(1-rho_z*rho_g)) + pd_ch + (chx001/(1-rho_z*rho_x))
* for plotting
replace cumg_chx0 = cumg_chx0*100
replace cumg_chx001 = cumg_chx001*100

* save file to generate fig A15 of the paper
save "${int}/g_zip.dta", replace

*================================ end of code =================================*

	
	


	
	
	
