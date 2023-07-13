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
	* To implement Section V of the paper

Input:
	* preprocessed.dta

Output:
	(a): Figures
		* Fig A17: Change in Urban Minus Suburban Rent Growth Relative to Pre-Pandemic 
				   for Combination of Transitory and Permanent Regime

	(b): Tables
		* Table III: Backing Out Expected Rents
	
	(c): Data
		* pdratios.dta
		* pdcals_all_final.csv, which is the input of 4_sectionv_plts.do
	 

*================================================================================================**/

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

* replace ZORI = ZORI*12
replace ZORI_ = ZORI_*12 //annualizing zori

gen ZORI_m_ = ZORI_/12
* log distance log of prices and rents
gen distance_log = log(1+distance)

local ylist "ZHVI_ ZORI_ ZORI_m_"
foreach y of local ylist {
	gen `y'log = log(`y')
}
gen pd = ZHVI_log - ZORI_log
gen PD_raw = ZHVI_/ZORI_ //for graph -- plotting in levels

bysort n zip (month): gen l_pd = pd[_n-12]

* rent and price growth
local loglist "ZHVI_log ZORI_log ZORI_m_log"
foreach log of local loglist {
	bysort n zip (month): gen l_`log'= `log'[_n-12]
	gen ch_`log' = `log' - l_`log'
}


local changelist "ch_ZHVI_log ch_ZORI_log"
foreach change of local changelist {
	bysort n distance (month): egen `change'_pre = mean(`change') if month<=719
	bysort n distance (month): replace `change'_pre = `change'_pre[1] if missing(`change'_pre)
	bysort n distance (month): egen `change'_post = mean(`change') if month>=729&month<=731
	bysort n distance (month): replace `change'_post = `change'_post[_N] if missing(`change'_post)
}


* ploting pd ratio against distance for NY prepandemic -- Fig for Section III.F
//all
bysort n distance (month): egen pd_pre = mean(PD_raw) if month<=719
bysort n distance (month): replace pd_pre = pd_pre[1] if missing(pd_pre)
bysort n distance (month): egen pd_post = mean(PD_raw) if month>=729&month<=731
bysort n distance (month): replace pd_post = pd_post[_N] if missing(pd_post)
	
save "${int}/pdratios.dta", replace

drop pd_pre pd_post

sort n zip month

* getting inputs for section V at MSA level
sort n zip month // pre pandemic all

egen tag_allzip = tag(n zip) 
forval n = 1(1)30 {
	bysort zip (month): egen pd_pre_t_`n' = mean(pd) if month<=719&n==`n'
	gen share_`n' = pd_pre_t_`n' * cns_pop if tag_allzip==1&n==`n'&!missing(pd_pre_t_`n')
	egen num_`n' = total(share_`n') if tag_allzip==1&n==`n'&!missing(pd_pre_t_`n')
	egen den_`n' = total(cns_pop) if tag_allzip==1&n==`n'&!missing(pd_pre_t_`n')
	gen pd_pre_`n' = num_`n'/den_`n' 
	drop pd_pre_t_`n' share_`n' num_`n' den_`n'
}
drop tag_allzip

sort n zip month // pre pandemic urb sub 
egen tag_urban = tag(n zip) if urban==1
egen tag_suburban = tag(n zip) if suburban==1

forval n = 1(1)30 { 
local urbsub "urban suburban"
foreach us of local urbsub {
	// pd 
	bysort zip (month): egen pd_pre_t_`us'_`n' = mean(pd) if month<=719&n==`n'&`us'==1
	gen share_`us'_`n' = pd_pre_t_`us'_`n' * cns_pop if tag_`us'==1&n==`n'&!missing(pd_pre_t_`us'_`n')
	egen num_`us'_`n' = total(share_`us'_`n') if tag_`us'==1&n==`n'&!missing(pd_pre_t_`us'_`n')
	egen den_`us'_`n' = total(cns_pop) if tag_`us'==1&n==`n'&!missing(pd_pre_t_`us'_`n')
	gen pd_pre_`us'_`n' = num_`us'_`n'/den_`us'_`n'
	drop pd_pre_t_`us'_`n' share_`us'_`n' num_`us'_`n' den_`us'_`n'
	
	// g
	bysort zip (month): egen d_pre_t_`us'_`n' = mean(ch_ZORI_log) if month<=719&n==`n'&`us'==1
	gen share_`us'_`n' = d_pre_t_`us'_`n' * cns_pop if tag_`us'==1&n==`n'&!missing(d_pre_t_`us'_`n')
	egen num_`us'_`n' = total(share_`us'_`n') if tag_`us'==1&n==`n'&!missing(d_pre_t_`us'_`n')
	egen den_`us'_`n' = total(cns_pop) if tag_`us'==1&n==`n'&!missing(d_pre_t_`us'_`n')
	gen d_pre_`us'_`n' = num_`us'_`n'/den_`us'_`n'
	drop d_pre_t_`us'_`n' share_`us'_`n' num_`us'_`n' den_`us'_`n'
}
}

drop tag_urban tag_suburban


sort n zip month // post pandemic urb sub 
egen tag_urban = tag(n zip) if urban==1&month>=729&month<=731
egen tag_suburban = tag(n zip) if suburban==1&month>=729&month<=731

forval n = 1(1)30 { 
local urbsub "urban suburban"
foreach us of local urbsub {
	// pd 
	bysort zip (month): egen pd_post_t_`us'_`n' = mean(pd) if month>=729&month<=731&n==`n'&`us'==1
	gen share_`us'_`n' = pd_post_t_`us'_`n' * cns_pop if tag_`us'==1&n==`n'&!missing(pd_post_t_`us'_`n')
	egen num_`us'_`n' = total(share_`us'_`n') if tag_`us'==1&n==`n'&!missing(pd_post_t_`us'_`n')
	egen den_`us'_`n' = total(cns_pop) if tag_`us'==1&n==`n'&!missing(pd_post_t_`us'_`n')
	gen pd_post_`us'_`n' = num_`us'_`n'/den_`us'_`n'
	drop pd_post_t_`us'_`n' share_`us'_`n' num_`us'_`n' den_`us'_`n'
	
	// g
	bysort zip (month): egen d_post_t_`us'_`n' = mean(ch_ZORI_log) if month>=729&month<=731&n==`n'&`us'==1
	gen share_`us'_`n' = d_post_t_`us'_`n' * cns_pop if tag_`us'==1&n==`n'&!missing(d_post_t_`us'_`n')
	egen num_`us'_`n' = total(share_`us'_`n') if tag_`us'==1&n==`n'&!missing(d_post_t_`us'_`n')
	egen den_`us'_`n' = total(cns_pop) if tag_`us'==1&n==`n'&!missing(d_post_t_`us'_`n')
	gen d_post_`us'_`n' = num_`us'_`n'/den_`us'_`n'
	drop d_post_t_`us'_`n' share_`us'_`n' num_`us'_`n' den_`us'_`n'

}
}

drop tag_urban tag_suburban

* structuring the data
keep n pop_2019 cbsa pd_* d_*
fcollapse (min) pop_2019 (min) pd_* d_* (first) cbsa, by(n)
order n cbsa pop_2019


drop n

reshape long pd_pre_  pd_pre_urban_ pd_pre_suburban_ d_pre_urban_ d_pre_suburban_ pd_post_urban_ pd_post_suburban_ d_post_urban_ d_post_suburban_ , i(cbsa) j(n) string
drop if pd_pre_==.&pd_pre_urban_==.
destring n, replace
sort n
order n cbsa pop_2019

* dropping MSAs which have no zips for suburban
drop if pd_pre_suburban_==.
drop if pd_pre_urban_==.
//drop if n==14 | n==16 | n==20 | n==25 | n==27 | n==30

* calculations
* exp(pdbar^u), exp(pdbar^s), exp(pd^u), exp(pd^s)

local explist "pd_pre_ pd_pre_urban_ pd_pre_suburban_ pd_post_urban_ pd_post_suburban_"
foreach e of local explist {
	gen `e'exp = exp(`e')
}

* rho_j
gen rho_j_u = pd_pre_urban_exp/(1+pd_pre_urban_exp)
gen rho_j_s = pd_pre_suburban_exp/(1+pd_pre_suburban_exp)
gen rho_j_a = pd_pre_exp/(1+pd_pre_exp)

* k
gen k_u = log(1+pd_pre_urban_exp)-rho_j_u*pd_pre_urban_
gen k_s = log(1+pd_pre_suburban_exp)-rho_j_s*pd_pre_suburban_

gen test_u = log(1+pd_pre_urban_exp)-rho_j_u*log(pd_pre_urban_exp)
gen test_s = log(1+pd_pre_suburban_exp)-rho_j_s*log(pd_pre_suburban_exp)
drop test_u test_s

* xbar
gen xbar_u = k_u + d_pre_urban_ - (1-rho_j_u)*pd_pre_urban_
gen xbar_s = k_s + d_pre_suburban_ - (1-rho_j_s)*pd_pre_suburban_

* change in pd
gen pd_j_ch = (pd_post_urban_exp-pd_pre_urban_exp) - (pd_post_suburban_exp-pd_pre_suburban_exp)
rename pd_j_ch pd_j_tab
gen pd_j_ch = (pd_post_urban_-pd_pre_urban_) - (pd_post_suburban_-pd_pre_suburban_)

* parameters
gen rho_g = 0.747
gen rho_x = 0.917
gen kappa0 = 0

* change in xbar
gen xbar_ch_kappa0 = kappa0*(xbar_s-xbar_u)

* change in xbar -- permanent
gen xbar_ch_02 = 0.01

* rent differential
gen rent_pre_us = d_pre_urban_ - d_pre_suburban_
gen T2 = (1-rho_j_a*rho_g)*pd_j_ch
gen T3kappa0 = ((1-rho_j_a*rho_g)/(1-rho_j_a*rho_x))*xbar_ch_kappa0
gen T3xbar02 = ((1-rho_j_a*rho_g)/(1-rho_j_a*rho_x))*xbar_ch_02

gen rent_diff_kappa0 = rent_pre_us + T2 + T3kappa0
gen rent_diff_xbar02 = rent_pre_us + T2 + T3xbar02

* long term rent differential
gen rent_diff_kappa0_lt = rent_diff_kappa0/(1-rho_j_a*rho_g)
gen rent_diff_xbar02_lt = rent_diff_xbar02/(1-rho_j_a*rho_g)

* permanent shocks
* case 1
gen rent_diff_perm1 = (pd_post_urban_-pd_post_suburban_)-(log(1+pd_post_urban_exp)-log(1+pd_post_suburban_exp)) + (xbar_u-xbar_s)
* case 2
gen rent_diff_perm2 = (pd_post_urban_-pd_post_suburban_)-(log(1+pd_post_urban_exp)-log(1+pd_post_suburban_exp)) + (xbar_u-xbar_s) + 0.01

order n cbsa pd_pre_urban_exp pd_pre_suburban_exp d_pre_urban_ d_pre_suburban_ xbar_u xbar_s pd_post_urban_exp pd_post_suburban_exp pd_j_ch rent_diff_kappa0_lt rent_diff_xbar02_lt rent_diff_perm1 rent_diff_perm2 d_post_urban_ d_post_suburban_

save "${int}/sectioniv.dta", replace

* Pop weighted averages
use "${int}/sectioniv.dta", replace

gen dummy=1
fcollapse (mean) pd_j_ch rent_diff_kappa0_lt rent_diff_xbar02_lt rent_diff_perm1 rent_diff_perm2 [aw=pop_2019], by(dummy)

append using "${int}/sectioniv.dta"
drop dummy

order n cbsa pd_pre_urban_exp pd_pre_suburban_exp d_pre_urban_ d_pre_suburban_ xbar_u xbar_s pd_post_urban_exp pd_post_suburban_exp pd_j_ch rent_diff_kappa0_lt rent_diff_xbar02_lt rent_diff_perm1 rent_diff_perm2 d_post_urban_ d_post_suburban_

replace n=100 if n==.
sort n
replace cbsa = "MSA Population Weighted Average" if n==100
replace n=. if n==100

replace d_pre_urban_ = d_pre_urban_*100
replace d_pre_suburban_ = d_pre_suburban_*100
replace xbar_u = xbar_u*100
replace xbar_s = xbar_s*100
replace pd_j_ch = pd_j_ch*100
replace rent_diff_kappa0_lt = rent_diff_kappa0_lt*100
replace rent_diff_xbar02_lt = rent_diff_xbar02_lt*100
replace rent_diff_perm1 = rent_diff_perm1*100
replace rent_diff_perm2 = rent_diff_perm2*100
replace d_post_urban_ = d_post_urban_*100
replace d_post_suburban_ = d_post_suburban_*100


format pd_pre_urban_exp pd_pre_suburban_exp d_pre_urban_ d_pre_suburban_ xbar_u xbar_s pd_post_urban_exp pd_post_suburban_exp pd_j_ch rent_diff_kappa0_lt rent_diff_xbar02_lt rent_diff_perm1 rent_diff_perm2 d_post_urban_ d_post_suburban_ %9.2f


export delimited using "${int}/pdcals_all_final.csv", replace

* Table III of the paper
cd "${tables}"
listtex n cbsa pd_pre_urban_exp pd_pre_suburban_exp d_pre_urban_ d_pre_suburban_ xbar_u xbar_s pd_post_urban_exp pd_post_suburban_exp pd_j_ch rent_diff_kappa0_lt rent_diff_xbar02_lt rent_diff_perm1 rent_diff_perm2 using exprents.tex, ///
	replace rstyle(tabular) ///
	head("\begin{tabular}{cl|cccccc|cc|c|cc|cc} \hline & & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) & (9) & (10) & (11) & (12) & (13) \\[2mm] & & \multicolumn{6}{c|}{ Pre-pandemic } & \multicolumn{2}{c|}{ Pandemic } & & \multicolumn{2}{c|}{ Transitory Change } & \multicolumn{2}{c}{ Permanent Change } \\[2mm] \# & MSA & \begin{tabular}{c} $\overline{PD}^{uj}$ \end{tabular} & \begin{tabular}{c} $\overline{PD}^{sj}$ \end{tabular} & \begin{tabular}{c} $\overline{g}^{uj}$ \end{tabular} & \begin{tabular}{c} $\overline{g}^{sj}$ \end{tabular} & \begin{tabular}{c} $\overline{x}^{uj}$ \end{tabular} & \begin{tabular}{c} $\overline{x}^{sj}$ \end{tabular} & \begin{tabular}{c} $ PD_t^{uj} $ \end{tabular} & \begin{tabular}{c} $ PD_t^{sj} $ \end{tabular} & \begin{tabular}{c} $\Delta pd^j$ \end{tabular} & \multicolumn{2}{c|}{ $ ( g_t^{uj} - g_t^{sj} ) / ( 1 - \rho^j \rho_g) $ } & \multicolumn{2}{c}{ $ \hat{g}^{uj} - \hat{g}^{sj} $ } \\[2mm] & & & & & & & & & & & $ $\Delta x^j=0$ $ & \begin{tabular}{c} $\Delta x^{j} = 0.01 \end{tabular} & \begin{tabular}{c} $ \Delta \overline{x}^{j} = 0 $ \end{tabular} & \begin{tabular}{c} $ \Delta \overline{x}^{j} = 0.01 $ \end{tabular} \\[2mm] \hline ") ///
	foot(" \hline \end{tabular} ")
	

* combined case plots
drop if n==.

* weights
gen p = 0.64
gen one_p = 1-p

* Plot 1:
gen rent_diff_x0_t1 = rent_diff_kappa0_lt*(1-rho_j_a*rho_g)
gen rent_diff_comb_x0_t = (rent_diff_x0_t1*p) + (rent_diff_perm1*one_p)

	graph hbar rent_diff_comb_x0_t, over(n, label(labsize(vsmall)) relabel(1 "New York" 2 "Los Angeles" 3 "Chicago" 4 "Dallas" 5 "Houston" 6 "Washington" 7 "Miami" 8 "Philadelphia" 9 "Atlanta" 10 "Phoenix" 11 "Boston" 12 "San Francisco" 13 "Seattle" 14 "San Diego" 15 "Tampa" 16 "Denver" 17 "St. Louis" 18 "Baltimore" 19 "Charlotte" 20 "Orlando" 21 "San Antonio" 22 "Sacramento" 23 "Austin")) nofill ///
	bar(1, fcolor(lavender) lcolor(lavender)) ///
	legend(order(1 "Delta x=0")) ylabel(, angle(360)) ytitle("Change in Urban Minus Suburban Rent Growth") b1title(" ") graphregion(color(white))
gr export "/Users/vm2517/Dropbox/PhD/Research/NYCempty_all/NYCempty/JFEfinal/Figures/gus_comb_msa_deltax0.pdf", replace

* per per transitory
gen gtr_chx0_t = rent_diff_kappa0_lt*(1-rho_j_a*rho_g)
gen gtr_chx001_t = rent_diff_xbar02_lt*(1-rho_j_a*rho_g)

* gbar u-s
gen gbarus = d_pre_urban_ - d_pre_suburban_

* eps
gen epst_chx0 = gtr_chx0_t - gbarus //transitory deltax=0
gen epst_chx001 = gtr_chx001_t - gbarus //transitory deltax=0.01
gen epsp_chx0 = rent_diff_perm1 - gbarus //permanent deltax=0
gen epsp_chx001 = rent_diff_perm2 - gbarus //permanent deltax=0.01

* discounted epst and ept
local discepst "epst_chx0 epst_chx001"
foreach epst of local discepst {
	gen `epst'_disc = `epst'/(1-rho_j_a*rho_g)
}

local discepsp "epsp_chx0 epsp_chx001"
foreach epsp of local discepsp {
	gen `epsp'_disc = `epsp'/(1-rho_j_a)
}

gen gbarus_disc = gbarus/(1-rho_j_a)

* discounted cum expected growth
* transitory
gen disc_cumexpgr_tr_chx0 = epst_chx0_disc + gbarus_disc
gen disc_cumexpgr_tr_chx001 = epst_chx001_disc + gbarus_disc

* permanent
gen disc_cumexpgr_p_chx0 = epsp_chx0_disc + gbarus_disc
gen disc_cumexpgr_p_chx001 = epsp_chx001_disc + gbarus_disc


* combined case discounted cum shocks -- weighted average of tr and p cases
gen disc_cumeps_chx0 = (p*epst_chx0_disc) + (one_p*epsp_chx0_disc)
gen disc_cumeps_chx001 = (p*epst_chx001_disc) + (one_p*epsp_chx001_disc)

* combined case expected growth -- weighted average of tr and p cases
gen disc_cumexpgr_c_chx0 = (p*disc_cumexpgr_tr_chx0) + (one_p*disc_cumexpgr_p_chx0)
gen disc_cumexpgr_c_chx001 = (p*disc_cumexpgr_tr_chx001) + (one_p*disc_cumexpgr_p_chx001)

* Fig A17 of the paper: bar plots for combined case
	graph hbar disc_cumeps_chx0 disc_cumeps_chx001, over(n, label(labsize(vsmall)) relabel(1 "New York" 2 "Los Angeles" 3 "Chicago" 4 "Dallas" 5 "Houston" 6 "Washington" 7 "Miami" 8 "Philadelphia" 9 "Atlanta" 10 "Phoenix" 11 "Boston" 12 "San Francisco" 13 "Seattle" 14 "San Diego" 15 "Tampa" 16 "Denver" 17 "St. Louis" 18 "Baltimore" 19 "Charlotte" 20 "Orlando" 21 "San Antonio" 22 "Sacramento" 23 "Austin")) nofill ///
	bar(1, fcolor(edkblue) lcolor(edkblue)) bar(2, fcolor(cranberry) lcolor(cranberry)) ///
	legend(order(1 "Delta x=0" 2 "Delta x=0.01")) ylabel(, angle(360)) ytitle("Change in Urban Minus Suburban Rent Growth") b1title(" ") graphregion(color(white))

gr export "/Users/vm2517/Dropbox/PhD/Research/NYCempty_all/NYCempty/JFEfinal/Figures/g_comb_msa.pdf", replace



*================================ end of code =================================*
