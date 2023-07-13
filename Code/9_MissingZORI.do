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
use "Data/Intermediate/zori_mi_analysis_data.dta", clear

// Prepare data
drop index
replace month = mofd(dofc(month))
format month %tm

replace cns_median_income = cns_median_income/1000
replace cns_pop = cns_pop/1000
replace cns_pop_density = cns_pop_density/1000

// Label the variables
label variable ZORI_avail "ZORI Reported"
label variable cns_median_age "Median Age"
label variable cns_median_income "Median Income (1000)"
label variable cns_pop "Population (1000)"
label variable cns_black_ratio "Share Black"
label variable cns_rich_ratio "Share income $>$ \\$ 150k"
label variable cns_pop_density "Density ($1000/km^2$)"
label variable cns_renter_ratio "Rentership"
label variable log_distance "Log Distance"

// Get sample
keep if month == tm(2020m12)

// Time Series Plot
forval i = 40(10)80 {
	xtile log_dist_qs_`i' = log_distance, nq(`i')
	
	logit ZORI_avail cns* ib(last).log_dist_qs_`i'

	estimates store model_x
		
	esttab model_x ///
		using "${path}/Tables//ZORI_Avail_bin_dist_`i'.csv", ///
		se label nogaps not replace ///
		star(* 0.10 ** 0.05 *** 0.01)
	estimates clear
	
	preserve
	pctile cutoffs = log_distance, nq(`i')
	save "${path}/Tables//bin_log_dist_`i'.dta", replace
	restore
}

// Table I.B
logit ZORI_avail ///
	log_distance
estimates store model_col1
logit ZORI_avail ///
	cns_renter_ratio
estimates store model_col2
logit ZORI_avail ///
	log_distance cns_renter_ratio
estimates store model_col3
logit ZORI_avail ///
	cns_median_income cns_rich_ratio cns_median_age ///
	cns_black_ratio cns_pop cns_pop_density ///
	cns_renter_ratio
estimates store model_col4
logit ZORI_avail ///
	log_distance ///
	cns_median_age cns_median_income cns_pop ///
	cns_black_ratio cns_rich_ratio cns_pop_density ///
	cns_renter_ratio
estimates store model_col5

esttab model_* ///
	using "${path}/Tables/ZORI_avail_model_logit.tex", ///
	noomitted ///
	se ///
	label compress nogaps ///
	tex replace ///
	stats(N, labels(Observations)) ///
	star(* 0.10 ** 0.05 *** 0.01)
