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


global data_dir = "../data/"

* Keep the 2015 dollars figures
import excel "$data_dir\h08.xls", sheet("h08") cellrange(A63) clear
drop if _n > 51

rename B median2015
rename C std2015
rename D median2014
rename E std2014
rename F median2013
rename G std2013
rename H median2012
rename I std2012
rename J median2011
rename K std2011
rename L median2010
rename M std2010
rename N median2009
rename O std2009
rename P median2008
rename Q std2008
rename R median2007
rename S std2007
rename T median2006
rename U std2006
rename V median2005
rename W std2005
rename X median2004
rename Y std2004
rename Z median2003
rename AA std2003
rename AB median2002
rename AC std2002
rename AD median2001
rename AE std2001
rename AF median2000
rename AG std2000

rename A state
keep state median* std*
reshape long median std, i(state) j(year)

generate state_id =  .
replace state_id =  1 if state ==  "Alabama"
replace state_id =  2 if state ==  "Alaska"
replace state_id =  4 if state ==  "Arizona"
replace state_id =  5 if state ==  "Arkansas"
replace state_id =  6 if state ==  "California"
replace state_id =  8 if state ==  "Colorado"
replace state_id =  9 if state ==  "Connecticut"
replace state_id =  10 if state ==  "Delaware"
replace state_id =  11 if state ==  "D.C."
replace state_id =  12 if state ==  "Florida"
replace state_id =  13 if state ==  "Georgia"
replace state_id =  15 if state ==  "Hawaii"
replace state_id =  16 if state ==  "Idaho"
replace state_id =  17 if state ==  "Illinois"
replace state_id =  18 if state ==  "Indiana"
replace state_id =  19 if state ==  "Iowa"
replace state_id =  20 if state ==  "Kansas"
replace state_id =  21 if state ==  "Kentucky"
replace state_id =  22 if state ==  "Louisiana"
replace state_id =  23 if state ==  "Maine"
replace state_id =  24 if state ==  "Maryland"
replace state_id =  25 if state ==  "Massachusetts"
replace state_id =  26 if state ==  "Michigan"
replace state_id =  27 if state ==  "Minnesota"
replace state_id =  28 if state ==  "Mississippi"
replace state_id =  29 if state ==  "Missouri"
replace state_id =  30 if state ==  "Montana"
replace state_id =  31 if state ==  "Nebraska"
replace state_id =  32 if state ==  "Nevada"
replace state_id =  33 if state ==  "New Hampshire"
replace state_id =  34 if state ==  "New Jersey"
replace state_id =  35 if state ==  "New Mexico"
replace state_id =  36 if state ==  "New York"
replace state_id =  37 if state ==  "North Carolina"
replace state_id =  38 if state ==  "North Dakota"
replace state_id =  39 if state ==  "Ohio"
replace state_id =  40 if state ==  "Oklahoma"
replace state_id =  41 if state ==  "Oregon"
replace state_id =  42 if state ==  "Pennsylvania"
replace state_id =  44 if state ==  "Rhode Island"
replace state_id =  45 if state ==  "South Carolina"
replace state_id =  46 if state ==  "South Dakota"
replace state_id =  47 if state ==  "Tennessee"
replace state_id =  48 if state ==  "Texas"
replace state_id =  49 if state ==  "Utah"
replace state_id =  50 if state ==  "Vermont"
replace state_id =  51 if state ==  "Virginia"
replace state_id =  53 if state ==  "Washington"
replace state_id =  54 if state ==  "West Virginia"
replace state_id =  55 if state ==  "Wisconsin"
replace state_id =  56 if state ==  "Wyoming"



save "$data_dir/state_incomes.dta", replace


