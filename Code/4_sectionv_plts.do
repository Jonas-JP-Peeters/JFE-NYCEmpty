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
	* To implement Section V plots

Input:
	* pdcals_all_final.csv, which is the output of 3_sectionv.do

Output:
	(a): Figures
		* Fig 13: Evolution of Rent Growth when Pandemic is Transitory and 
				   Permanent along with a Combination of Two Regimes
		* Fig A18: Evolution of Price-Rent Ratio when Pandemic is Transitory 
				   and Permanent along with a Combination of Two Regimes
	
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

* loading data
import delimited using "${int}/pdcals_all_final.csv", clear
drop if n==. //MSA pop weighted average row deleted

* gbar_us
gen prep_g_us = d_pre_urban_ - d_pre_suburban_
gen prep_g_us_pop = prep_g_us*pop_2019

* xbar_us
gen prep_x_us = xbar_u - xbar_s
gen prep_x_us_pop = prep_x_us*pop_2019

* pdbar_us
gen prep_pd_us = pd_pre_urban_ - pd_pre_suburban_
gen prep_pd_us_pop = prep_pd_us*pop_2019

* A
gen A_msa = 1/(1-rho_j_a*rho_g)
gen A_msa_pop = A_msa*pop_2019

* B
gen B_msa = 1/(1-rho_j_a*rho_x)
gen B_msa_pop = B_msa*pop_2019

* lt g_us chx0
gen perm_gus_ass5_pop = rent_diff_perm1*pop_2019

* lt g_us chx 0.01
gen perm_gus_ass6_pop = rent_diff_perm2*pop_2019

* pdpost_us
gen postp_pd_us = pd_post_urban_ - pd_post_suburban_
gen postp_pd_us_pop = postp_pd_us*pop_2019

local sumlist "prep_g_us_pop prep_x_us_pop prep_pd_us_pop A_msa_pop B_msa_pop perm_gus_ass5_pop perm_gus_ass6_pop postp_pd_us_pop pop_2019"
foreach sum of local sumlist {
	egen `sum'_s = sum(`sum')
}
gen gbar_us = prep_g_us_pop_s/pop_2019_s
gen xbar_us = prep_x_us_pop_s/pop_2019_s
gen pdbar_us = prep_pd_us_pop_s/pop_2019_s
gen A = A_msa_pop_s/pop_2019_s
gen B = B_msa_pop_s/pop_2019_s
gen perm_gus_ass5 = perm_gus_ass5_pop_s/pop_2019_s
gen perm_gus_ass6 = perm_gus_ass6_pop_s/pop_2019_s
gen pdpost_us = postp_pd_us_pop_s/pop_2019_s

drop prep_g_us prep_g_us_pop prep_g_us_pop_s ///
		prep_x_us prep_x_us_pop prep_x_us_pop_s ///
		prep_pd_us prep_pd_us_pop prep_pd_us_pop_s ///
		A_msa A_msa_pop A_msa_pop_s ///
		B_msa B_msa_pop B_msa_pop_s ///
		perm_gus_ass5_pop perm_gus_ass5_pop_s ///
		perm_gus_ass6_pop perm_gus_ass6_pop_s ///
		postp_pd_us postp_pd_us_pop postp_pd_us_pop_s

* chx_0 chx_0_01 x_ass4
gen chx_0_t1 = rent_diff_kappa0_lt*(1-rho_j_a*rho_g)
gen chx_0_01_t1 = rent_diff_xbar02_lt*(1-rho_j_a*rho_g)
gen x_ass4_t1 = (xbar_u - xbar_s) + 1

* msa by msa
local i
forvalues t = 2(1)60{
	local i = `t'-1
	display `i'
	
	* chx_0
	gen chx_0_t`t' = (1-rho_g)*(d_pre_urban_-d_pre_suburban_)+(rho_g*chx_0_t`i')
	* chx_0_01
	gen chx_0_01_t`t' = (1-rho_g)*(d_pre_urban_-d_pre_suburban_)+(rho_g*chx_0_01_t`i')
	* x_ass4
	gen x_ass4_t`t' = ((1-rho_x)*(xbar_u - xbar_s))+ (rho_x*x_ass4_t`i')
}

* MSA population weighted
forvalues t = 1(1)60{
	
	* chx_0
	gen chx_0_t`t'_pop = chx_0_t`t'*pop_2019
	egen chx_0_t`t'_pop_s = sum(chx_0_t`t'_pop)
	gen chx_0_`t' = chx_0_t`t'_pop_s/pop_2019_s
	
	* chx_0_01
	gen chx_0_01_t`t'_pop = chx_0_01_t`t'*pop_2019
	egen chx_0_01_t`t'_pop_s = sum(chx_0_01_t`t'_pop)
	gen chx_0_01_`t' = chx_0_01_t`t'_pop_s/pop_2019_s
	
	* x_ass4
	gen x_ass4_t`t'_pop = x_ass4_t`t'*pop_2019
	egen x_ass4_t`t'_pop_s = sum(x_ass4_t`t'_pop)
	gen x_ass4_`t' = x_ass4_t`t'_pop_s/pop_2019_s
}
drop chx_0_t* chx_0_*_pop chx_0_*_pop_s ///
	chx_0_01_t* chx_0_01_*_pop chx_0_01_*_pop_s ///
	x_ass4_t* x_ass4_*_pop x_ass4_*_pop_s

* keep relevant variables
keep gbar_us chx_0_* chx_0_01_* xbar_us x_ass4_* pdbar_us A B perm_gus_ass5 perm_gus_ass6 pdpost_us
duplicates drop

* wide to long
gen dummy = 1
reshape long chx_0_ chx_0_01_ x_ass4_, i(dummy) j(time)

tempfile time1_60
save `time1_60', replace

* adding time = 0 for plots
fcollapse (min) time, by(dummy)
tempfile time0
save `time0', replace

use `time0', clear
append using `time1_60'
replace time = 0 if time==1&gbar_us==.

drop dummy

local fillist "gbar_us xbar_us pdbar_us A B"
foreach var of local fillist {
	replace `var' = `var'[_N] if `var'==.&time==0
}

local fillist "chx_0_ chx_0_01_ perm_gus_ass5 perm_gus_ass6"
foreach var of local fillist {
	replace `var' = gbar_us[1] if `var'==.&time==0
}

replace x_ass4_ = xbar_us[1] if x_ass4_==.&time==0
replace pdpost_us = pdbar_us[1] if pdpost_us==.&time==0

rename chx_0_ chx_0
rename chx_0_01_ chx_0_01
rename x_ass4_ x_ass4

* combining two regimes
	* calculating g
gen p = 0.64
gen one_p = 1-p

gen comb_g_x0 = (p*chx_0) + (one_p*perm_gus_ass5)
gen comb_g_x0_01 = (p*chx_0_01) + (one_p*perm_gus_ass6)

* calculating transitory pd
gen chx_0_100 = chx_0/100
gen gbar_us_100 = gbar_us/100
gen xbar_us_100 = xbar_us/100
gen chx_0_01_100 = chx_0_01/100
gen x_ass4_100 = x_ass4/100

* << logs
gen chx_0_xbar_us = pdbar_us + A*(chx_0_100-gbar_us_100)-B*(xbar_us_100-xbar_us_100) //only g drives
gen chx_0_01_x_ass4 = pdbar_us + A*(chx_0_01_100-gbar_us_100)-B*(x_ass4_100-xbar_us_100)


* calculating pd for combined transitory and permanent regime
gen comb_pd_x0 = (p*chx_0_xbar_us)+(one_p*pdpost_us)
gen comb_pd_x0_01 = (p*chx_0_01_x_ass4)+(one_p*pdpost_us)

gen pdbar_us_e = exp(pdbar_us)
local elist "chx_0_xbar_us pdpost_us comb_pd_x0 chx_0_01_x_ass4 comb_pd_x0_01"
foreach e of local elist {
	gen `e'_e = exp(`e')
}

* plots
	** g*100 **
* Fig 13 (Panel A): g all cases with delta=0
twoway (connected chx_0 time if time <=20, msymbol(o) mcolor(cranberry) lcolor(cranberry)) (line perm_gus_ass5 time if time<=20, lcolor(edkblue)) (connected comb_g_x0 time if time <=20, msymbol(+) mcolor(orange) lcolor(orange)), ///
legend(order(1 "Transitory" 2 "Permanent" 3 "Combined (p=0.64)")) ytitle("Urban Minus Suburban Rent Growth") ///
		ylabel(0(1)4, angle(horizontal) grid glcolor(gs15) format(%9.2fc)) xtitle("Time") ///
		graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) bgcolor(white)
		
		gr export "${figures}/deltax_0_g.pdf", replace
		
* Fig 13 (Panel B): g all cases with delta=0.01
twoway (connected chx_0_01 time if time <=20, msymbol(o) mcolor(cranberry) lcolor(cranberry)) (line perm_gus_ass6 time if time<=20, lcolor(edkblue)) (connected comb_g_x0_01 time if time <=20, msymbol(+) mcolor(orange) lcolor(orange)), ///
legend(order(1 "Transitory" 2 "Permanent" 3 "Combined (p=0.64)")) ytitle("Urban Minus Suburban Rent Growth") ///
		ylabel(0(1)4, angle(horizontal) grid glcolor(gs15) format(%9.2fc)) xtitle("Time") ///
		graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) bgcolor(white)
		
		gr export "${figures}/deltax_0_01_g.pdf", replace

	** pd logs **
* Fig A18 (panel A): pd all cases with delta=0
twoway (connected chx_0_xbar_us time if time <=20, msymbol(o) mcolor(cranberry) lcolor(cranberry)) (line pdpost_us time if time<=20, lcolor(edkblue)) (connected comb_pd_x0 time if time <=20, msymbol(+) mcolor(orange) lcolor(orange)), ///
legend(order(1 "Transitory" 2 "Permanent" 3 "Combined (p=0.64)")) ytitle("Urban Minus Suburban Price-Rent Ratio") ///
		ylabel(0.16(0.02)0.26, angle(horizontal) grid glcolor(gs15) format(%9.2fc)) xtitle("Time") ///
		graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) bgcolor(white)
		
		gr export "${figures}/deltax_0_pd.pdf", replace

* Fig A18 (panel B): pd level all cases with delta=0.01
twoway (connected chx_0_01_x_ass4 time if time <=20, msymbol(o) mcolor(cranberry) lcolor(cranberry)) (line pdpost_us time if time<=20, lcolor(edkblue)) (connected comb_pd_x0_01 time if time <=20, msymbol(+) mcolor(orange) lcolor(orange)), ///
legend(order(1 "Transitory" 2 "Permanent" 3 "Combined (p=0.64)")) ytitle("Urban Minus Suburban Price-Rent Ratio") ///
		ylabel(0.16(0.02)0.26, angle(horizontal) grid glcolor(gs15) format(%9.2fc)) xtitle("Time") ///
		graphregion(fcolor(white) lcolor(white) ifcolor(white) ilcolor(white)) bgcolor(white)
		
		gr export "${figures}/deltax_0_01_pd.pdf", replace


*================================ end of code =================================*




	
