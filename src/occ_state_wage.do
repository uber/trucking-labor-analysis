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


global data_dir = "../data"
global output_dir = "../data"

filelist, directory("$data_dir") pattern("*state*.dta")
drop if regexm(filename,"november")
drop if regexm(filename,"state_by_year")
drop if regexm(filename,"temp")
drop if regexm(filename,"wage_state_year")

levelsof filename, local(filelistnames)

foreach x of local filelistnames{
	use "$data_dir/`x'", clear
		rename *, lower
		destring tot_emp, replace ignore("**")
		replace tot_emp = 0 if tot_emp == .
		bysort area: egen total = sum(tot_emp)
		generate share_in_occ = tot_emp / total
		capture rename occ_titl occ_title
		keep area st share_in_occ a_mean h_mean occ_code occ_title tot_emp
		destring h_mean a_mean, replace ignore("*#")

		label variable occ_title "Occupation Name"
		label variable area "State FIPS"
		label variable st "State Abbreviation"
		label variable occ_code "6-Digit Occupation Code"
		label variable h_mean "Mean Hourly Wage"
		label variable a_mean "Mean Annual Wage"
		label variable share_in_occ "Share of Total State Population in Occupation"
		label variable tot_emp "Total Employment in Occupation for State"

	save "$data_dir/temp_`x'", replace
}

forvalues t = 2000/2002{
	use "$data_dir/temp_state_`t'_dl.dta", clear
		generate year = `t'
	save "$data_dir/temp_state_`t'_dl.dta", replace
}

forvalues t = 2009/2016{
	use "$data_dir/temp_state_M`t'_dl.dta", clear
		generate year = `t'
	save "$data_dir/temp_state_M`t'_dl.dta", replace
}

forvalues t = 2003/2006{
	use "$data_dir/temp_state_may`t'_dl.dta", clear
		generate year = `t'
	save "$data_dir/temp_state_may`t'_dl.dta", replace
}

use "$data_dir/temp_state_May2007_dl.dta", clear
	generate year = 2007
save "$data_dir/temp_state_May2007_dl.dta", replace

use "$data_dir/temp_state__M2008_dl.dta", clear
	generate year = 2008
save "$data_dir/temp_state__M2008_dl.dta", replace
	

filelist, directory("$data_dir") pattern("temp*state*.dta")
levelsof filename, local(flistname)

clear
foreach x of local flistname{
	append using "$data_dir/`x'"
	erase "$data_dir/`x'"
}

order year, after(st)

label variable year "Year (BLS)"
save "$data_dir/wage_state_year_occ.dta", replace
