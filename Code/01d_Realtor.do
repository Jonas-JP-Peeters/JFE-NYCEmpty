/*==============================================================================
Date: October 2020
Project: NYC Empty

Prepare the Realtor information for regressing.

==============================================================================*/

cd "/scratch/jp5642/JFEfinal_09062021/Code"

local date "20210723" // "21_07" "21-01"

import delimited "../Data/Source/realtor_inventory_core_`date'.csv", ///
	stringcols(1 2) clear 

drop if month_date_yyyymm == "* year-over-year figures may be impacted"
gen month = "_" + substr(month_date_yyyymm,5,2) + substr(month_date_yyyymm,1,4)

drop month_date_yyyymm zip_name flag

qui ds, has(type string)
foreach var of varlist `r(varlist)' {
	replace `var' = "" if `var' == "nan"
	destring `var', replace
}

gen zip = string(postal_code, "%05.0f")
drop postal_code

drop *_mm *_yy
rename median_listing_price med_list_price
rename active_listing_count act_list_count
rename median_days_on_market med_dom
rename new_listing_count new_list_count
rename price_increased_count price_incr_count
rename price_reduced_count price_decr_count
rename pending_listing_count pend_list_count
rename median_listing_price_per_square_ med_list_ppsqft
rename median_square_feet med_sqft
rename average_listing_price ave_list_price
rename total_listing_count tot_list_count
drop v27 v28

qui ds zip month, not
reshape wide `r(varlist)', i(zip) j(month) string

tempfile tmp
save `tmp', replace

import delimited "../Data/Source/realtor_inventory_hotness_`date'.csv", ///
	stringcols(1 2) clear
	
drop if month_date_yyyymm == "quality_flag = 1:  year-over-year figures may be impacted"
gen month = "_" + substr(month_date_yyyymm,5,2) + substr(month_date_yyyymm,1,4)

drop month_date_yyyymm zip_name

qui ds, has(type string)
foreach var of varlist `r(varlist)' {
	replace `var' = "" if `var' == "nan"
	destring `var', replace
}

gen zip = string(postal_code, "%05.0f")
drop postal_code

drop *_mm* *_yy*
drop ldpviews_per_property_vs_us
rename median_days_on_market med_dom
rename median_dom_vs_us med_dom_vs_us 
rename median_listing_price mlp
rename median_listing_price_vs_us mlp_vs_us

qui ds zip month, not
reshape wide `r(varlist)', i(zip) j(month) string

merge 1:1 zip using `tmp', nogenerate

ds zip, not
foreach var of varlist `r(varlist)' {
	rename `var' rltr_`var'
}

save "../Data/Intermediate/realtor.dta", replace
