/*==============================================================================
Date: May 2020
Project: NYC Empty

Append all the Zillow variables together into one dataset. We have the 
Zillow Home Value Index (ZHVI), Zillow Observed Rent Index (ZORI), sale prices,
sale counts and the number of new monthly listings.

==============================================================================*/

cd "/scratch/jp5642/JFEfinal_09062021/Code"

local zhvi_date "20210129"
local zori_date "20210129"

* Import the home value index of Zillow
import delimited "../Data/Source/zillow_zhvi_smoothed_`zhvi_date'.csv", ///
	stringcols(1 3) numericcols(2) clear
rename m* ZHVI*

tempfile tmp
save `tmp', replace

* Import the rent index of Zillow Seasonally Adjusted
import delimited "../Data/Source/zillow_zori_ALHPF_smoothed_`zori_date'.csv", ///
	encoding(Big5) stringcols(1 2) clear
rename m* ZORI*

* Merge both files
merge 1:1 regionname using `tmp', nogenerate
save `tmp', replace

* Import the home value index of Zillow 1 bedroom
import delimited "../Data/Source/zillow_zhvi_b1_`zhvi_date'.csv", ///
	encoding(Big5) stringcols(1 3) clear
rename m* ZHVI_B1*

* Merge both files
merge 1:1 regionname using `tmp', nogenerate
save `tmp', replace

* Import the home value index of Zillow 2 bedrooms
import delimited "../Data/Source/zillow_zhvi_b2_`zhvi_date'.csv", ///
	encoding(Big5) stringcols(1 3) clear
rename m* ZHVI_B2*

* Merge both files
merge 1:1 regionname using `tmp', nogenerate
save `tmp', replace

* Clean up the variables
rename ZHVIetro metro
replace state = statename if state == ""
drop statename

rename regionname zip
replace zip = substr("00000", 1, 5 - length(zip)) + zip
drop regionid sizerank regiontype
order state metro county city zip ZORI* ZHVI*

save "../Data/Intermediate/zillow.dta", replace
