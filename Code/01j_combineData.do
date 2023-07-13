/*==============================================================================
Date: May 2020
Project: NYC Empty

Merge the Zillow, Safegraph and Census data into a big data set. Also label
the variables.

==============================================================================*/

clear all
set maxvar 8000

cd "/scratch/jp5642/JFEfinal_09062021/Code"

use "../Data/Intermediate/distance.dta", clear
	
merge n:1 zip using "../Data/Intermediate/census.dta", ///
	keep(master matched) nogenerate
	
merge n:1 zip using "../Data/Intermediate/realtor.dta", ///
	keep(master matched) nogenerate
	
merge n:1 zip using "../Data/Intermediate/zillow.dta", ///
	keep(master matched) nogenerate
	
merge n:1 zip using "../Data/Intermediate/zillow_condo.dta", ///
	keep(master matched) nogenerate

merge n:1 zip using "../Data/Intermediate/zillow_sfr.dta", ///
	keep(master matched) nogenerate
	
merge n:1 zip using "../Data/Intermediate/landunavail.dta", ///
	keep(master matched) nogenerate

merge n:1 zip using "../Data/Intermediate/POIs.dta", ///
	keep(master matched) nogenerate
	
merge n:1 zip using "../Data/Intermediate/WFH_zip.dta", ///
	keep(master matched) nogenerate

merge n:1 cbsa using "../Data/Intermediate/WRLURI_cbsa.dta", ///
	keep(master matched) nogenerate
	
merge n:1 cbsa using "../Data/Intermediate/landunavail_cbsa.dta", ///
	keep(master matched) nogenerate
	
merge n:1 cbsa using "../Data/Intermediate/WFH_cbsa.dta", ///
	keep(master matched) nogenerate
	
merge n:1 cbsa using "../Data/Intermediate/supply_elasticity.dta", ///
	keep(master matched) nogenerate
	
merge n:1 cbsa using "../Data/Intermediate/stringency.dta", ///
	keep(master matched) nogenerate
	
merge n:1 cbsa using "../Data/Source/top75msas.dta", ///
	keep(master matched) nogenerate
	
keep if n <= 30

keep ///
	n cbsa zip distance pop_2019 /// Geo
	establishments /// Safegraph
	ZHVI* ZORI* /// Zillow
	cns* /// Census
	rltr_* /// Realtor
	teleworkable* /// Dingel
	WRLURI18* /// Wharton Residential Land Use Regulation Index
	totalunavailable_* /// Chandler Lutz
	supply* /// Albert Saiz
	StringencyIndex // Stringency
	
drop ///
	rltr_nielsen_hh_* rltr_hotness_rank_* rltr_hotness_score_* ///
	rltr_supply_score_* rltr_demand_score_* rltr_med_dom_vs_us_* ///
	rltr_mlp_vs_us_* rltr_new_list_count_* rltr_med_list_price_* ///
	rltr_price_incr_count_* rltr_price_decr_count_* rltr_med_sqft_* ///
	rltr_pend_list_count_* rltr_ave_list_price_* rltr_tot_list_count_* ///
	rltr_tot_list_count_* rltr_pending_ratio_* ZORIsaname ZHVI_B*etro ///
	ZHVI_*1996 ZHVI_*1997 ZHVI_*1998 ZHVI_*1999 ///
	ZHVI_*2000 ZHVI_*2001 ZHVI_*2002 ZHVI_*2003 ///
	ZHVI_*2004 ZHVI_*2005 ZHVI_*2006 ZHVI_*2007 ///
	ZHVI_*2008 ZHVI_*2009 ZHVI_*2010 ZHVI_*2011 ///
	ZHVI_*2012 ZHVI_*2013
	
rename StringencyIndex, lower

// ZIP codes without establishments have a missing where it should be zero
replace establishments = 0 if mi(establishments)

// Set supply elasticity Sacramento to value of Stockton-Lodi, CA
replace supplyelasticity = 2.07 if cbsa == "Sacramento-Roseville-Folsom, CA"

save "../Data/Intermediate/preprocessed.dta", replace
