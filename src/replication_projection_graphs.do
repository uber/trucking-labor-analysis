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


clear all
set more off

*Graphs


*CHOOSE A FILE - SEE readme.txt and equilibrium.m for more information
*Needs to be one of "p1","p1_with_growth"
local use_estimates = "p1_with_growth"

assert inlist("`use_estimates'","p1","p1_with_growth")
insheet using "output/`use_estimates'.csv", comma clear


rename v1 projection
rename v2 multiplier
rename v3 year
rename v4 lh_wage
rename v5 sh_wage
rename v6 lh_jobs
rename v7 sh_jobs

replace sh_wage = sh_wage/1000
replace lh_wage = lh_wage/1000
replace sh_jobs = sh_jobs/1000000
replace lh_jobs = lh_jobs/1000000

sort projection multiplier
by projection multiplier: egen maxl = max(lh_jobs)
by projection multiplier: egen mins = min(sh_jobs)
gen unemployed_lh = maxl - lh_jobs
gen employed_sh = sh_jobs - mins
gen unemployed = unemployed_lh - employed_sh

gen id = 10*projection + multiplier
drop projection multiplier maxl mins

reshape wide lh_wage sh_wage lh_jobs sh_jobs unemployed unemployed_lh employed_sh, i(year) j(id)

forvalues proj = 1/3{
*Overall Employment
twoway (connected  lh_jobs`proj'2 year, msymbol(circle) mcolor(red) lcolor(red) msize(vsmall) legend(label(1 "LH 2x Multiplier"))) ( connected  lh_jobs`proj'3 year, msymbol(triangle) mcolor(red) lcolor(red) msize(vsmall) legend(label(2 "LH 3x Multiplier"))) ( connected  lh_jobs`proj'5 year, msymbol(square) mcolor(red) lcolor(red) msize(vsmall) legend(label(3 "LH 5x Multiplier"))) /// 
       (connected sh_jobs`proj'2 year, msymbol(circle) mcolor(blue) lcolor(blue) msize(vsmall) legend(label(4 "SH 2x Multiplier"))) ( connected  sh_jobs`proj'3 year, msymbol(triangle) mcolor(blue) lcolor(blue) msize(vsmall) legend(label(5 "SH 3x Multiplier"))) ( connected  sh_jobs`proj'5 year, msymbol(square) mcolor(blue) lcolor(blue) msize(vsmall) legend(label(6 "LH 5x Multiplier")) ///
       legend(rows(2) size(small)) xtitle("Year") ytitle("Employment (Millions)") graphregion(fcolor(white)) ylabel(,nogrid) xlabel(2017(3)2029) xscale(range(2017 2028)))
graph export "output/pictures/`use_estimates'_employment_s`proj'.pdf", replace
	   
*Unemployment Change
twoway connected  unemployed`proj'2 year, msize(tiny) xlabel(2017(3)2029) xscale(range(2017 2028))|| connected  unemployed`proj'3 year, msize(tiny) || connected  unemployed`proj'5 year, xtitle("Year") ytitle("Unemployment Change (Millions)")  legend(rows(1) order(1 "2x Multiplier" 2 "3x Multiplier" 3 "5x Multiplier")) graphregion(fcolor(white)) ylabel(,nogrid) msize(tiny)
graph export "output/pictures/`use_estimates'_unemployment_s`proj'.pdf", replace

*Long-Haul Wages
twoway connected lh_wage`proj'2 year, msize(tiny) xlabel(2017(3)2029) xscale(range(2017 2028)) || connected lh_wage`proj'3 year, msize(tiny) || connected lh_wage`proj'5 year , xtitle("Year") ytitle("Long-Haul Wage (Thousands)")  legend(rows(1) order(1 "2x Multiplier" 2 "3x Multiplier" 3 "5x Multiplier")) graphregion(fcolor(white)) ylabel(,nogrid) msize(tiny)
graph export "output/pictures/`use_estimates'_lhwage_s`proj'.pdf", replace


*Short-Haul Wages
twoway connected sh_wage`proj'2 year, msize(tiny) xlabel(2017(3)2029) xscale(range(2017 2028)) || connected sh_wage`proj'3 year, msize(tiny) || connected sh_wage`proj'5 year , xtitle("Year") ytitle("Short-Haul Wage (Thousands)")  legend(rows(1) order(1 "2x Multiplier" 2 "3x Multiplier" 3 "5x Multiplier")) graphregion(fcolor(white)) ylabel(,nogrid) msize(tiny)
graph export "output/pictures/`use_estimates'_shwage_`proj'.pdf", replace

}
