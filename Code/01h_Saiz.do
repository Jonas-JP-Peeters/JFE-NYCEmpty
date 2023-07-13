/*==============================================================================
Date: January 2021
Project: NYC Empty

Description: Load Prof. Albert Saiz's supply elasticity data.
==============================================================================*/

// Configure the script
cd "/scratch/jp5642/JFEfinal_09062021/Code"

// Load the data
import delimited "../Data/Source/supply_elasticity.csv", stringcols(1) clear 

// Drop and rename columns
drop cbsa
rename msa cbsa
keep cbsa supplyelasticity
drop if supplyelasticity == .

// Save the data
save "../Data/Intermediate/supply_elasticity.dta", replace
