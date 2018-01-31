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

*Load data
use "data/cps_all.dta", clear

*Define two time periods (early and late)
*Can't use more granular time periods because of data limitations
generate time_dim = 1 * inrange(year, 2000, 2008) + 2 * inrange(year, 2009, 2016)
label variable time_dim "Time Period"
	label define tdd 1 "2000-2008" 2 "2009-2016"
	label values time_dim tdd

*Need to generate this...makes it easier to add things up later
generate one = 1

*Restrict to adult population
keep if age >= 16

*Create trucker and "not working" dummies
*Create a labor force status variable
generate trucker = (occ2010 == 9600)
generate notworking = (occ2010 == 9920)

generate labor_status = trucker + 2 * notworking
	label define labstat 0 "Not Trucking" 1 "Trucking" 2 "Not Working"
	label values labor_status labstat

*Generate count and fraction by age, labor status, and early/late designation
collapse (sum) one, by(age labor_status time_dim)
bysort age: egen total1 = sum(one)
generate fraction_truck = one/total1

rename (one fraction_truck)(one_ fraction_truck_)

drop total1

*Reshape the data for computational ease
reshape wide one_ fraction_truck_ , i(age time_dim) j(labor_status)

keep age fraction_truck_1 time_dim


label variable fraction_truck_1 "Fraction in Trucking"
replace fraction_truck_1 = 0 if fraction_truck_1 == .

xtset time_dim age
generate retirement = S.fraction_truck_1
	label variable retirement "Retirement Rate (Percentage Points)"

*Generate a graph of percent in a cohort in trucking over early/late
twoway (connected fraction_truck_1 age if time_dim == 1 & inrange(age,61,70), ///
	graphregion(fcolor(white)) ylabel(,nogrid) msize(tiny) xlabel(61(3)70) ytitle("Fraction in Trucking") xtitle("Age") legend(label(1 "2000-2008"))) ///
	(connected fraction_truck_1 age if time_dim == 2 & inrange(age,61,70), ///
	msize(tiny) legend(label(2 "2009-2016")))


*Create new variable that scales up all fractions by a common factor so that the data works for a histogram
keep age time_dim fraction_truck_1
replace fraction_truck_1 = round(fraction_truck_1 * 10^8,1)
replace fraction_truck_1 = 1 if age > 70

*Generate a histogram of age of drivers over early or late
preserve
	drop if age > 75
	twoway (histogram age if time_dim == 1 [fweight = fraction_truck_1], width(1) start(16)  ///
		graphregion(fcolor(white)) ylabel(,nogrid) xlabel(15(15)75) ytitle("Fraction in Trucking") xtitle("Age") legend(label(1 "2000-2008")) fcolor(navy%40) lcolor(navy%40)) ///
		(histogram age if time_dim == 2 [fweight = fraction_truck_1], width(1) start(16) ///
		legend(label(2 "2009-2016")) fcolor(red%40) lcolor(red%40) )
restore
save "intermediate/retirement_scenario.dta", replace




*This section produces projections of age patterns over time
use "intermediate/retirement_scenario.dta", clear
	keep age fraction time_dim
	
	*This is to clean up the time series and generate a new era
	xtset age time_dim
	count
	set obs `=`r(N)'+1'
	replace age = 90 if _n == _N
	replace time_dim = 2 if _n == _N
	replace fraction = 0 if age == 90

	tsfill, full
	replace fraction = 0 if fraction == .
	count
	set obs `= `r(N)' * 1.5'
	local min = `=`r(N)' + 1'
	count
	local max = `r(N)'

	forvalues t = `min'/`max'{
		replace age = mod(`t',75) + 15 if _n == `t'
	}
	replace time_dim = 3 if _n >= `min'
	replace age = 90 if age == 15
	label define tdd 3 "Future", add

	xtset age time_dim
	
	*Set number of drivers to zero for ages > 71
	replace fraction_truck_1 = 0 if inrange(age,71,.)
	
	*Generate retirement rates by projecting forward average trend
	generate change_rate = (fraction_truck_1 - L.fraction_truck_1)/L.fraction_truck_1
	generate age_group = 1 * (inrange(age,60,70) != 1) + 2 * (inrange(age,60,70) == 1)
	bysort age_group: egen meannn = mean(change_rate)
		replace meannn = . if age_group == 1
	xtset age time_dim
	generate future = .
		replace future = L.fraction_truck_1 * (1 + meannn) if time_dim == 3 & age_group == 2
		replace future = L.fraction_truck_1 * (1 + L.change_rate) if time_dim == 3 & age_group == 1
		replace future = 0 if time_dim == 3 & inrange(age,71,.)
	replace fraction = 0 if fraction == .

	rename future future_3
	keep age future_3 time_dim 
	keep if time_dim == 3
	drop time_dim
	tsset age
	
	*Smooth the retirement where necessary
	forvalues t= 61/70{
	replace future_3 = (L.future_3 + F.future_3)/2 ///
		if age == `t' & future_3 > L.future_3
	}	
	replace future_3 = 0 if inrange(age,16,70) == 0
	keep if inrange(age,16,90)
save "intermediate/retirement_scenario_projections.dta", replace

*Import retirement rates and generate current age distribution
use "intermediate/retirement_scenario_projections.dta", clear
	merge 1:m age using "intermediate/retirement_scenario.dta", nogenerate
	keep if time_dim == 2
	drop time_dim
	sort age
	*use this to get at number in age group
	keep if inrange(age,16,70)
	egen total_fraction = sum(fraction_truck_1)
	generate number_here = fraction_truck_1 / total_fraction * 1704520
	*According to the BLS there are 1,704,520 "Heavy and Tractor-Trailer Truck Drivers" (as of May 2016)
	*https://www.bls.gov/oes/current/oes_nat.htm#53-0000
	tsset age
	generate retirement_rate = S.future_ / L.future_
	
	
*Exercise: Fix the number of drivers in each trucking cohort
*Keep this number fixed until they hit age 60
*Then for each year from 60 --> 70 "retire" them at the rate specified
*Once they hit 71 they are retired with probability one
keep age number_here retirement_rate

save "intermediate/temporary.dta", replace
	keep if age>= 61
	drop number_here 
	generate one = 1
	reshape wide retirement_rate, i(one) j(age)
save "intermediate/retirement_rates.dta", replace

use "intermediate/temporary.dta", clear
	drop retirement_rate
	erase "intermediate/temporary.dta"
generate one = 1
merge m:1 one using "intermediate/retirement_rates.dta", nogenerate
drop one

*Generate retirement rate by year-cohort
forvalues s = 2017/2028{
	generate retirement_`s' = .
	}
forvalues t = 0/9{
	replace retirement_2017 = retirement_rate`=`t' + 61' if age == `=`t' + 60'
}
forvalues t = 0/9{
	replace retirement_2018 = retirement_rate`=`t' + 61' if age == `=`t' + 59'
}
forvalues t = 0/9{
	replace retirement_2019 = retirement_rate`=`t' + 61' if age == `=`t' + 58'
}
forvalues t = 0/9{
	replace retirement_2020 = retirement_rate`=`t' + 61' if age == `=`t' + 57'
}
forvalues t = 0/9{
	replace retirement_2021 = retirement_rate`=`t' + 61' if age == `=`t' + 56'
}
forvalues t = 0/9{
	replace retirement_2022 = retirement_rate`=`t' + 61' if age == `=`t' + 55'
}
forvalues t = 0/9{
	replace retirement_2023 = retirement_rate`=`t' + 61' if age == `=`t' + 54'
}
forvalues t = 0/9{
	replace retirement_2024 = retirement_rate`=`t' + 61' if age == `=`t' + 53'
}
forvalues t = 0/9{
	replace retirement_2025 = retirement_rate`=`t' + 61' if age == `=`t' + 52'
}
forvalues t = 0/9{
	replace retirement_2026 = retirement_rate`=`t' + 61' if age == `=`t' + 51'
}
forvalues t = 0/9{
	replace retirement_2027 = retirement_rate`=`t' + 61' if age == `=`t' + 50'
}
forvalues t = 0/9{
	replace retirement_2028 = retirement_rate`=`t' + 61' if age == `=`t' + 49'
}

*Assign the correct retirement rate to a cohort
tsset age
forvalues s = 2017/2028{
	replace retirement_`s' = -1 if age == `=2087-`s'' & retirement_`s' == .
}
forvalues s = 2017/2028{
	replace retirement_`s' = -1 if L.retirement_`s' == -1
	replace retirement_`s' = 0 if retirement_`s' == .
}

drop retirement_rate*

*Generate number employed/retired in a cohort
forvalues s = 2017/2028{
	generate number_retired_`s' = .
	generate number_employed_`s' = .
}

replace number_employed_2017 = (1 + retirement_2017) * number_here

forvalues s = 2018/2028{
	replace number_employed_`s' = (1 + retirement_`s') * number_employed_`=`s'-1'
}

forvalues s = 2017/2028{
	replace number_retired_`s' = number_here - number_employed_`s'
	}
	
collapse (sum) number_employed_* number_retired_* number_here

sum number_here, d
local total = `r(mean)'
display `total'
generate one = 1
reshape long number_retired_ number_employed_, i(one) j(year)
drop one

assert abs(number_retired_ + number_employed_ - `total') < 0.01

*Create per-thousand variable
generate number_retired_rounded = round(number_retired_/1000,.001)

*Generate bar graph of cumulative retirees per year
graph bar number_retired_rounded, over(year) ylabel(,nogrid) graphregion(fcolor(white)) ytitle("Cumulative Projected Number of Retirees (in Thousands)")
save "intermediate/retirement_employment_by_year.dta", replace


*Generate retirement survival curve
use "intermediate/retirement_rates.dta", clear
reshape long retirement_rate, i(one) j(age)
set obs 11
replace age = 60 if _n == _N
replace one = 1 if age == 60
replace retirement_rate = 0 if age == 60
tsset age
replace one = L.one * (1 + retirement_rate) if age > 60
replace one = 100 * one
label variable one "Percentage Not Retired"
set obs 12
replace age = 71 if _n == _N
replace one = 0 if age == 71
set obs 13
replace age = 72 if _n == _N
replace one = 0 if age == 72

twoway connected one age, ///
	graphregion(fcolor(white)) ylabel(,nogrid) xtitle("Age") msize(tiny) xlabel(60(2)72)


*Generate number of retirees per year graph
use "intermediate/retirement_employment_by_year.dta", clear
tsset year
count 
set obs `=`r(N)'+1'
replace year = 2016 if year == .
replace number_retired_ = 0 if year == 2016
sort year
generate new_retirees = S.number_retired_
drop if year == 2016

generate new_retirees_rounded = round(new_retirees/1000,0.001)

graph bar new_retirees_rounded, over(year) ylabel(,nogrid) graphregion(fcolor(white)) ///
	ytitle("Projected Number of Retirees (in Thousands)") bar(1,color(maroon)) ///
	yscale(range(0 40)) ylabel(0(10)40)

	
erase "intermediate/retirement_scenario.dta"
erase "intermediate/retirement_scenario_projections.dta"
erase "intermediate/retirement_rates.dta"
