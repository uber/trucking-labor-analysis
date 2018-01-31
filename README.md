# Trucking Labor Analysis
## Overview

An economic analysis of the potential effects on the trucking labor market from self-driving trucks. This analysis uses publicly-available historical data on demographics, employment, income, and other freight and truck industry inputs, as well as hypothetical scenarios of adoption and utilization of self-driving trucks over the next ten years, to estimate supply and demand curves and equilibrium employment for truck driving. Trucking jobs are split into two categories: long haul and short haul. The output of the analysis is an estimate of equilibrium employment in long haul and short haul for each year from 2018 to 2028.

We welcome input on this analysis. To comment, please open an issue. We will not be accepting pull requests but encourage further analysis and additional scenarios.

The following article provides the overview and backgroud of this work.

* [The Future of Trucking: Mixed Fleets, Transfer Hubs, and More Opportunity for Truck Drivers](https://medium.com/@UberATG/the-future-of-trucking-b3d2ea0d2db9 )

The doc folder contains an overview of the economic methodology used in this analysis.

## Requirements

Access to the following software: Stata, R, and MATLAB.

## Data

### Current Population Survey

The CPS data cannot be hosted due to file size. The CPS data that is used in this analysis can be freely downloaded from the Integrated Public Use Microdata Series website (https://cps.ipums.org/cps/)
Slight differences in results may occur due to changes in weights and reclassification of occupations that IPUMS updates to maintain data quality.

To obtain the data we use, download the "basic monthly data" for all month and year combinations from January 2000 through December 2016. The variables you will need to select (in addition to the preselected variables) include "union", "statefip", "earnwt", "occ2010", and "age". Documentation and codebooks are available from this website as well. Once the data is downloaded it should be converted to Stata format using the IPUMS-produced code and named cps_all.dta. It should be placed in the data folder.

### Bureau of Labor Statistics Occupational Statistics

BLS data on occupational employment by state is available at https://www.bls.gov/oes/tables.htm. All state data files must be downloaded for each year from 2000 to 2016. These files should be converted into Stata .dta files with the same names as the .xls files supplied by the BLS. ÊThese .dta files should be placed in the /data/ subdirectory.

Running occ_state_wage.do will then convert these files into ./data/occ_state_wage.dta. This is an input file used in the estimation described below.

### State Income Data

Data on state median incomes comes from the census. It can be downloaded here: http://www2.census.gov/programs-surveys/cps/tables/time-series/historical-income-households/h08.xls.

This excel file should be placed in the /data/ subdirectory. Running state_median_incomes.do will then convert this file to ./data/state_incomes.dta, an input file for the estimation described below.

### Deployment Scenarios
The deployment scenarios are available in the data folder. Each row represents a different deployment timeline. Column A represents the number of trucks deployed in 2018 for each scenario, column B represents the number of trucks deployed in 2019 for each scenario, and so on through column K which represents the number of trucks deployed in 2028 for each scenario. Note that these are hypothetical scenarios and do not represent any specific plans or expectations for UberÕs self-driving truck program. They have been selected to show very fast adoption of self-driving trucks for the purpose of highlighting the effects of such a significant change to the industry.

## File Explanations/Instructions

This section explains the file paths in the replication folder. There are four main folders. The src folder contains all of the code to replicate results. The data folder is where the appropriate data should be saved. It also contains the autonomous vehicle deployment projections that we used. The intermediate folder saves intermediate results, files, and estimates. It also is a repository for temporary files that are created in the estimation process. The output folder stores the files that are outputted with results in table and graph form.

This code runs on Stata 15 (for *.do* files) or MATLAB R2017a (for *.m* files).

### Estimation

#### *master_do_file.do*
This file encompasses the four main *.do* files for estimating the retirement curves (*replication_retirementcurve.do*), the union membership instrument (*replication_union.do*), and the demand (*replication_demand.do*) and supply (*replication_labor_supply.do*) specifications.

The retirement curve replication creates projections of truck driver retirements until 2028 using data from the CPS. It also plots some diagrams highlighting the age distribution of working drivers and trends in retirement ages of drivers.

The union replication file generates statistics on union membership of workers within a state-year. This instrument is used in the estimation of the driver demand specification.

The demand specification do file estimates the elasticity of driver demand with respect to the wage rate using data on driver wages and employment at the state-year level. It estimates this parameter separately for long-haul and short-haul driving.

The supply specification *.do* file estimates the elasticity of driver supply with respect to the wage rate using data on driver wages and employment at the state-year level.

### Running the Simulations
The estimated parameters are fed into simulation code, which finds equilibrium employment in wages in the short and long haul sectors for future years up to 2028 under different deployment scenarios.

#### *equilibrium.m*

This MATLAB file takes the estimated parameters from the demand and supply models, and the deployment projections in ./data/deployment.csv, and generates CSV files with projected future employment and wages. The output file contains 9 simulations. There are 3 deployment scenarios and 3 intensity levels which indicate the size of the multiplier which converts automated vehicle work to human driver equivalents.

Each run of the program will only output one of the files. The file that is produced depends on the indicator variables at lines 10 and 16. See also lines 228-236 where the output file is selected. The structural parameters - demand and supply elasticities etc. - are hard coded, and can be changed by changing the relevant lines of code.

#### *baseline.m*

This file generates MATLAB data files that are required to run the simulations that include baseline industry growth. Running this file will generate *./intermediate/lf_adjust.mat* and *./intermediate/intercept_adjust.mat*, which contain adjustment factors for the demand intercept and labor force size which generate 27% long haul industry growth from 2017 to 2028.

#### *equilibrium_with_growth.m*

This file is identical in structure to *equilibrium.m*, but uses the intermediate inputs generated by *baseline.m* to generate simulations that include an underlying growth trend.

The CSV file that is outputted by this code is *p1_with_growth.csv*.

### Generating Graphs

#### *charts.do*

This Stata file produces the area chart and the bar chart, the final two figures, in the blog post. One can change the scenario number (1, 2, 3) and the intensity number - that is, the multiplier on the ratio of autonomous truck to human driver productivity - that describes the efficiency of the autonomous truck (2, 3, 5). One can also change the results file that is called (see choices in section 2.2) to generate the corresponding graphs for different assumptions on phase in and feedback.

#### *replication_projection_graphs.do*

For each output file (the different scenarios discussed in section 2.2), this Stata file produces graphs of projections for overall industry employment levels, the change in unemployment, long-haul annual wages, and short-haul annual wages.

## Contributing

To comment, please open an issue. We will not be accepting pull requests but encourage further analysis and additional scenarios.
