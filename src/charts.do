/*
Copyright (c) 2018 Uber Technologies, Inc.  

Permission is hereby granted, free of charge, to any person obtaining a copy of 
this software and associated documentation files (the "Software"), to deal in 
the Software without restriction, including without limitation the rights to 
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of 
the Software, and to permit persons to whom the Software is furnished to do so, 
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all 
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
SOFTWARE.
*/


*Create Chart
clear all
set obs 12
generate time = _n + 2016

*Scenario number (in terms of speed of adoption) from Matlab Code
*Scenario 1 = 70% deployment
*Scenario 2 = 50% deployment
*Scenario 3 = 20% deployment
local scen_number = 2
*Intensity is the number of driver equivalents provided by an autonomous truck (2, 3, 5)
local inten_number = 2
*Growth rates as provided by ATA Freight Transportation Forecast
local growth_early = 0.027
local growth_late = 0.020

*Checks to make sure the chosen scenario number and intensity multiplier are valid
assert inlist(`scen_number',1,2,3)
assert inlist(`inten_number',2,3,5)

local file_name = "p1_with_growth.csv"

*Extract Jobs Predictions
preserve
	clear all
	import delimited "output/`file_name'"
	rename (v1 v2 v3 v4 v5 v6 v7)(scenario intensity time lwage swage lemp semp) 
	keep if scenario == `scen_number' & intensity == `inten_number'
	keep time lemp semp
	save "intermediate/employment_projections.dta"
restore

*Extract AV Numbers from Deployment Projections
preserve 
	clear all 	
	import delimited "data/deployment.csv"
	xpose, clear
	generate time = 2017 + _n
	
	if `scen_number' == 3 {
		keep time v3
		rename v3 deployment
	}
	
	if `scen_number' == 2 {
		keep time v2
		rename v2 deployment
	}

	if `scen_number' == 1 {
		keep time v1
		rename v1 deployment
	}
	
	set obs `=_N + 1'
	replace time = 2017 if time == .
	replace deployment = 0 if time == 2017
	
	save "intermediate/deployment_projections.dta"
restore

*Extract Retirements from Retirement Projections
preserve
	clear all
	use "intermediate/retirement_employment_by_year.dta"
	keep year number_retired_
	rename year time
	save "intermediate/retirement_projections.dta"
restore

*Merge All files together 
merge 1:1 time using "intermediate/employment_projections.dta", nogenerate 
merge 1:1 time using "intermediate/deployment_projections.dta", nogenerate
merge 1:1 time using "intermediate/retirement_projections.dta", nogenerate

*Erase Temporary Files
capture erase "intermediate/employment_projections.dta"
capture erase "intermediate/deployment_projections.dta"
capture erase "intermediate/retirement_projections.dta"



*Generate the Area Chart 
generate bottom = lemp / 10^6 /*long-haul employment (in millions) */
generate top = (lemp + semp) / 10^6 /*short-haul employment (in millions) */
generate full = (lemp + semp + `inten_number' * deployment) / 10^6 /* total driver equivalents (in millions) */

twoway (rarea full top time, xtitle("Year") xlabel(2018(2)2028) ylabel(#6,gstyle(dot)) legend(order(3 2 1) label(1 "Total Truck Equivalents")) fcolor(navy%80) lcolor(bg%1)) ///
	(rarea top bottom time, legend(label(2 "Short-Haul Jobs")) fcolor(maroon%80) lcolor(bg%1) yscale(range(0))) ///
	(area bottom time, xscale(range(2017 2028)) graphregion(fcolor(white)) fcolor(dkgreen%80) legend(label(3 "Long-Haul Jobs")) lcolor(bg%1) ytitle("Millions"))
graph export "output/pictures/area_chart_s`scen_number'_i`inten_number'.svg", replace
graph export "output/pictures/area_chart_s`scen_number'_i`inten_number'.pdf", replace
export delimited time bottom top full using "output/pictures/area_chart_s`scen_number'_i`inten_number'", replace

*Generate the Bar Chart Figure
keep time lemp semp

foreach x in lemp semp{
	generate `x'_status_quo = .
	*Impose the status quo growth rates from ATA
	replace `x'_status_quo = `x' if time == 2017
	replace `x'_status_quo = `x'_status_quo[_n-1] * ///
		((inrange(time,2018,2023)) * (1 + `growth_early') + (inrange(time,2024,2028) * (1 + `growth_late'))) if time > 2017
	}	

rename (lemp semp)(lemp1 semp1)
rename (lemp_status_quo semp_status_quo)(lemp0 semp0)

reshape long lemp semp, i(time) j(sq)
generate lemp_ = lemp / 10^6
generate semp_ = semp / 10^6

graph bar lemp_ semp_, legend(label(1 "Long-Haul") label(2 "Short-Haul")) ///
	ytitle("Millions of Jobs") ylabel(,gstyle(dot)) graphregion(fcolor(white)) ///
	over(sq, label(labsize(tiny) angle(45)) relabel(1 "Baseline" 2 "With AVs")) ///
	over(time, label(angle(22.5))) stack bar(1, color(maroon%80)) bar(2, color(dkgreen%80)) 
graph export "output/pictures/bar_chart_s`scen_number'_i`inten_number'.svg", replace
graph export "output/pictures/bar_chart_s`scen_number'_i`inten_number'.pdf", replace
export delimited time lemp_ semp_ using "output/pictures/bar_chart_s`scen_number'_i`inten_number'", replace
