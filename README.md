# Flattening the Curve: Pandemic-Induced Revaluation of Urban Real Estate

This repository contains all the code used in the paper *Flattening the Curve: Pandemic-Induced Revaluation of Urban Real Estate* by Arpit Gupta, Vrinda Mittal, Jonas Peeters and Stijn Van Nieuwerburgh. The code is divided in two subsequent categories. The first selection of code prepares the source data downloaded from their original sources. The second category will contain all the code pertaining to the regressions, plots and tables used in the paper.

The Python environment could be installed according to `environment.yml`.

## Data Sources

| Filename                                  | Source                                                       | Date Collected | URL                                                          |
| ----------------------------------------- | ------------------------------------------------------------ | -------------- | ------------------------------------------------------------ |
| `CBSAs.xls`                               | Census Bureau                                                | 01/07/2021     | https://www.census.gov/geographies/reference-files/time-series/demo/metro-micro/delineation-files.html |
| `zillow_zhvi_smoothed_20210129.csv`       | Zillow                                                       | 07/29/2021     | https://www.zillow.com/research/data/                        |
| `zillow_zori_ALHPF_smoothed_20210129.csv` | Zillow                                                       | 07/29/2021     | https://www.zillow.com/research/data/                        |
| `zillow_zori_NSA_smoothed_20210129.csv`   | Zillow                                                       | 07/29/2021     | https://www.zillow.com/research/data/                        |
| `zillow_zhvi_b1_20210129.csv`             | Zillow                                                       | 07/29/2021     | https://www.zillow.com/research/data/                        |
| `zillow_zhvi_b2_20210129.csv`             | Zillow                                                       | 07/29/2021     | https://www.zillow.com/research/data/                        |
| `zillow_zhvi_condo_20210605.csv`          | Zillow                                                       | 07/29/2021     | https://www.zillow.com/research/data/                        |
| `zillow_zhvi_sfr_20210605.csv`            | Zillow                                                       | 07/29/2021     | https://www.zillow.com/research/data/                        |
| `census.dta`                              | Census Bureau                                                | 07/08/2021     | https://www.census.gov/data/developers/data-sets/acs-5year.html |
| `realtor_inventory_core_20210723.csv`     | Realtor                                                      | 07/23/2021     | https://www.realtor.com/research/data/                       |
| `realtor_inventory_hotness_20210723.csv`  | Realtor                                                      | 07/23/2021     | https://www.realtor.com/research/data/                       |
| `31-us_zip2010_total_unavailable.csv`     | Lutz, C., & Sand, B. (2017). Highly disaggregated topological land unavailability. *Unpublished Working Paper*. | 01/27/2021     | https://github.com/ChandlerLutz/LandUnavailabilityData       |
| `ZIP_TRACT_032020.xlsx`                   | Department of Housing and Urban Development                  | 06/03/2020     | https://www.huduser.gov/portal/datasets/usps_crosswalk.html  |
| `occupations_workathome.csv`              | Dingel, J. I., & Neiman, B. (2020). How many jobs can be done at home?. *Journal of Public Economics*, *189*, 104235. | 03/19/2021     | https://github.com/jdingel/DingelNeiman-workathome           |
| `MSA_workfromhome.csv`                    | Dingel, J. I., & Neiman, B. (2020). How many jobs can be done at home?. *Journal of Public Economics*, *189*, 104235. | 09/29/2020     | https://github.com/jdingel/DingelNeiman-workathome           |
| `MSA_M2019_dl.xlsx`                       | Bureau of Labor Statistics                                   | 04/01/2021     | https://www.bls.gov/oes/                                     |
| `ACS5_2019_S2401_03192021.csv`            | Census Bureau                                                | 03/19/2021     | https://data.census.gov/cedsci/table?q=S2401&tid=ACSST1Y2019.S2401 |
| `WRLURI_01_15_2020.dta`                   | Gyourko, J., Hartley, J. S., & Krimmel, J. (2021). The local residential land use regulatory environment across US housing markets: Evidence from a new Wharton index. *Journal of Urban Economics*, *124*, 103337. | 02/05/2021     | http://real-faculty.wharton.upenn.edu/gyourko/land-use-survey/ |
| `supply_elasticity.csv`                   | Saiz, A. (2010). The geographic determinants of housing supply. *The Quarterly Journal of Economics*, *125*(3), 1253-1296. | 01/27/2021     | https://academic.oup.com/qje/article/125/3/1253/1903664?login=true |
| `USA_ZIPS.geojson`                        | Census Bureau                                                | 12/26/2020     | https://www.census.gov/geographies/mapping-files/time-series/geo/tiger-line-file.html |
| `covid_restrictions.csv`                  | Hale, T., Angrist, N., Goldszmidt, R., Kira, B., Petherick, A., Phillips, T., ... & Tatlow, H. (2021). A global panel database of pandemic policies (Oxford COVID-19 Government Response Tracker). *Nature Human Behaviour*, *5*(4), 529-538. | 02/22/2021     | https://github.com/OxCGRT/covid-policy-tracker               |
| `FMRs.dta`                                | HUD                                                          | 06/07/2021     | https://www.huduser.gov/portal/datasets/fmr.html#2021_query  |
| `ACS5_2019_DP04_03192021.csv`             | Census Bureau                                                | 06/08/2021     | https://data.census.gov/cedsci/table?q=DP04&tid=ACSDP1Y2019.DP04 |

## Data Preparation

| Filename                   | Description                                                  |
| -------------------------- | ------------------------------------------------------------ |
| `01a_Distance.ipynb`       | Uses the shapefile published by the census bureau and the manually collected coordinates of the city halls to calculate the distance of the centroid of each ZIP to the city hall. |
| `01b_Zillow.do`            | Loads the ZHVI and ZORI timeseries from the raw data and transforms them a format that is conform with the rest of the data. |
| `01b_Zillow.ipynb`         | Loads the ZHVI timeseries for Condo/Co-ops and Single Family Homes from the raw data and transforms them a format that is conform with the rest of the data. |
| `01c_Census.ipynb`         | Uses the Census Bureau API to pull data from the ACS5 for the year 2019 and uses this data to calculate some ratios. |
| `01d_Realtor.do`           | Loads the Realtor timeseries from the raw data and transforms them to make them in the same wide format as the rest of the data. |
| `01e_Lutz.do`              | Loads the land unavailability data and saves it as a .dta file after renaming some variables. |
| `01f_wfh.ipynb`            | Loads the work-from-home metric devised by Dingel, J. I., & Neiman, B. and transforms it into a ZIP-level metric. The WFH-metric is available at a granular occupations level and the ZIP-level occupations data from the census bureau is only available at a more general level. We use the MSA-level occupation data, which is at the same level as the WFH-metric, to determine the breakdown of the different general occupation classes per MSA into the more granular ones. |
| `01g_WRLURI.do`            | Loads the Wharton Residential Land Use Regulation Index (WRLURI) and transforms it into a format that allows us to merge it with the rest of the data. |
| `01h_Saiz.do`              | Uses the data collected from the paper in the .csv-file and matches the CBSA codes unto the CBSA names and saves it as a .dta file to merge with the rest of the data. |
| `01i_Stringency.ipynb`     | Loads the MSA level stringency COVID measures and saves it in a format ready for merging with the other data. |
| `01j_combineData.do`       | Combine all the previously prepared to get a wide ZIP-level dataset. |

## Analysis

| Filename               | Description                                                  |
| ---------------------- | ------------------------------------------------------------ |
| `1_pricegradient.do`   | Calculates and plots price and rent gradients, carries out the MSA level cross-sectional analysis, and produces tables. Does related robustness checks. |
| `2_csreg_zip.do`       | Carries out ZIP-level cross-sectional analysis and produces tables. Does related robustness checks. |
| `3_sectionv.do`        | Carries out Section V analysis and generates tables and plots. |
| `4_sectionv_plts.do`   | Generates additional plots for Section V.                    |
| `5_sectionv_zip.do`    | Generates data used to generate ZIP-level plots of Section V. |
| `6_cpi.do`             | Compares CPI Rent of Primary Residence and ZORI data at MSA level. |
| `7_PrepPlotData.ipynb` | Prepare the data used for the plots in the paper.            |
| `8_RenderPlots.ipynb`  | Render the plots used in the paper.                          |
| `9_MissingZORI.do`     | Carries out the logit models presented in Table B.1          |
| `10_GenTableMSAs.do`   | Generate Table A.1                                           |
## 
