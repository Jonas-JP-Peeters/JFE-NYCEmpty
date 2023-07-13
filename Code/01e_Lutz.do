/*==============================================================================
Date: January 2021
Project: NYC Empty

Description: Load Prof. Chandler Lutz's land unavailability data.
==============================================================================*/

// Configure the script
cd "/scratch/jp5642/JFEfinal/Code"

// Load the ZIP data
import delimited "../Data/Source/31-us_zip2010_total_unavailable.csv", stringcols(1 5) clear

// Prepare the data for the merge
rename geoid zip
rename totalunavailable totalunavailable_zip
keep zip totalunavailable_zip

// Save the ZIP level data
save "../Data/Intermediate/landunavail.dta", replace

// Load the CBSA-ZIP crosswalk
import excel "../Data/Source/CBSA_ZIP_032020.xlsx", ///
	sheet("CBSA_ZIP_032020") firstrow case(lower) clear
keep cbsa zip tot_ratio

// Merge with the ZIP-level data
merge n:1 zip using "../Data/Intermediate/landunavail.dta", ///
	nogenerate keep(matched)

// Aggregate the data to the CBSA level
collapse (mean) totalunavailable_zip [aw = tot_ratio], by(cbsa)
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
rename totalunavailable_zip totalunavailable_cbsa
keep cbsa totalunavailable_cbsa

// Save the CBSA-level data
save "../Data/Intermediate/landunavail_cbsa.dta", replace
