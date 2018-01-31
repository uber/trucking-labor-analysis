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

*Open CPS data
use "data/cps_all.dta"
tabulate union, generate(union_status_)

*Label union status variables
label variable union_status_1 "Not in Universe"
label variable union_status_2 "No union coverage"
label variable union_status_3 "Member of labor union"
label variable union_status_4 "Covered by union but not a member"

*Use the earnings weights (recommended for union variable) from CPS
*Weights should help the CPS population better approximate actual population
generate earn_weight_recip = 1/earnwt

*Calculate number unionized (in union or covered by union in a state-year)
*Note we ignore union_status_1 since these people aren't in the universe asked this question

collapse union_status_* [pweight = earn_weight_recip], by(year state)
generate union = (union_status_3 + union_status_4) / (union_status_2 + union_status_3 + union_status_4)
keep year statefip union

save "intermediate/cps_state_union_year.dta", replace
