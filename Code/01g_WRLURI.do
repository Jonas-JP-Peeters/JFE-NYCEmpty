 /*==============================================================================
Date: January 2021
Project: NYC Empty

Description: Load the WRLURI and prepare for combining it with the data file.
==============================================================================*/

// Configure the script
cd "/scratch/jp5642/JFEfinal/Code"

// Load the data
use "../Data/Source/WRLURI_01_15_2020.dta", clear

// Convert the county code to a string
drop if countycode18 == .
gen county = string(statecode, "%02.0f") + string(countycode18, "%03.0f")

// Collapse per county
// weight_metro is missing sometimes
collapse (mean) WRLURI18, by(county)

// Drop irrelevant variables
keep county WRLURI18

// Add the WRLURI for Las Vegas
local plus1 = _N + 1
set obs `plus1'
replace county = "32003" if mi(county)
replace WRLURI18 = -0.34 if county == "32003"

// Save the County-level data
save "../Data/Intermediate/WRLURI.dta", replace

// Load the ZIP-County crosswalk
import excel "../Data/Source/ZIP_COUNTY_032020.xlsx", ///
	sheet("ZIP_COUNTY_032020") firstrow case(lower) clear
keep zip county tot_ratio
rename tot_ratio tot_ratio_x

// Save the ZIP-County crosswalk
tempfile tmp
save `tmp', replace

// Load the CBSA-ZIP crosswalk
import excel "../Data/Source/CBSA_ZIP_032020.xlsx", ///
	sheet("CBSA_ZIP_032020") firstrow case(lower) clear
keep cbsa zip tot_ratio
rename tot_ratio tot_ratio_y

// Merge with the ZIP-County crosswalk
joinby zip using `tmp'

// Calculate cross-walk weights
gen tot_ratio = tot_ratio_x * tot_ratio_y
drop tot_ratio_*
collapse (sum) tot_ratio, by(cbsa county)

// Merge with the County-level data
merge n:1 county using "../Data/Intermediate/WRLURI.dta", ///
	nogenerate keep(matched)
	
// Deaggregate the data to the ZIP level
drop if mi(WRLURI18)
gen temp = WRLURI18*tot_ratio
collapse (sum) temp tot_ratio, by(cbsa)
gen WRLURI18 = temp/tot_ratio
rename cbsa cbsacode

// Save the CBSA-level data
tempfile tmp
save `tmp', replace

// Load the CBSA-name map
import excel "../Data/Source/CBSAs.xls", ///
	sheet("List 1") cellrange(A3:L1923) firstrow case(lower) clear
keep cbsacode cbsatitle
duplicates drop

// Merge with the CBSA-level data
merge 1:1 cbsacode using `tmp', ///
	nogenerate keep(matched)
rename cbsatitle cbsa
rename WRLURI18 WRLURI18_cbsa
keep cbsa WRLURI18_cbsa

// Save the CBSA-level data
save "../Data/Intermediate/WRLURI_cbsa.dta", replace
