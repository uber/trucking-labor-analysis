%{
Copyright (c) 2018 Uber Technologies, Inc.  

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the 
"Software"), to deal in the Software without restriction, including 
without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject to 
the following conditions:

The above copyright notice and this permission notice shall be included  
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS 
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF 
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
%}




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Solves for Intercepts and Labor Force growth that generates 27% job growth in no-AV Scenario %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function baseline

scenario = 1;
multi = 0;

% read in csv
data = csvread('../data/deployment.csv',0,0);
output = zeros(12,7);
deployment = data(scenario,:)';
deployment = [0; deployment];
deployment = zeros(size(deployment));
stop_feedback = 0;

% Labor Demand Parameters: Long Haul
lh_intercept = 34.8;
lh_demand_e = -3.657;

% Intercept Adjustment
lh_intercept_base = lh_intercept;
intercept_adjust = zeros(12,1);

% Labor force
% We set the baseline labor force to 4 million.  This is based on BLS statistics for people in "driving" occupations.
lf = 4000000;
lf_base = lf;
lf_adjust = zeros(12,1);


% Set Labor Supply Parameters from Estimates
fe_other = -45.46;
fe_long =  fe_other -1.486;
fe_short = fe_other -0.986;
wage_supply_e = 4.66;

% Demand intercepts are set to calibrate wages in year 1
% Other parameters from estimation
% Target wages for calibration
% LH: 43090
% SH: 33778



% Labor Demand Parameters: Short Haul
sh_intercept = 9.6;
sh_demand_e = -1.639;

sh_lh_response = 0.0000596/49;

% Outside wage
% We set the outide wage to $30,000. This is based on BLS statistics for non-trunking driving occupations.
O_wage = 30000;

% Loop over forward years
for year = 1:12


%%%%%%%%%%%%%%%%%%%
% Find intercepts %
%%%%%%%%%%%%%%%%%%%

if year > 1
	%target_q = base_q + ((year-1)*delta);
	target_q = base_q + (delta);
	q_diff_level = 100;
	while q_diff_level > 10
		lh_intercept = lh_intercept_base + intercept_adjust(year);
		q = lh_demand(base_w,[lh_intercept,lh_demand_e]);
		if q > target_q
			intercept_adjust(year) = intercept_adjust(year) - 0.00001;
		else
			intercept_adjust(year) = intercept_adjust(year) + 0.00001;
		end
		(q - target_q)
		q_diff_level = abs(q - target_q)
	end
end






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Find labor force adjustment that keeps the wage constant %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
zero_test = 1000

while zero_test > 100

lh_intercept = lh_intercept_base + intercept_adjust(year);
lf = lf_base + lf_adjust(year);

demand_shift = 0;

% Loop over wage changes until convergence
LH_wage_lagged = 40000;
SH_wage_lagged = 40000;
step = 100;
while step > 0.001

    % Find equilibrium LH wage
    params = [lh_intercept,lh_demand_e,fe_long,fe_short,fe_other,wage_supply_e,lf,demand_shift];
    w0 = 10000;
    f = @(w) excess_demand_lh(w,SH_wage_lagged,O_wage,params);
    LH_wage = fmincon(f,w0);
    
    % Get LH employment
    lh_employment = lh_demand(LH_wage,params);
    lh_employment_true = lh_employment;
    lh_employment = lh_employment + demand_shift;
    
    % Graph LH market
    for i = 1:20
        w1(i) = 1000*(i+35);
        q1(i) = lh_demand(w1(i),params);
        if q1(i) < 0
            q1(i) = 0;
        end     
    end

    for i = 1:20
        w2(i) = 1000*(i+35);
        q2(i) = lh_supply(w2(i),params,30000,30000);
        if q2(i) < 0
            q2(i) = 0;
        end
    end
    
    for i = 1:20
        w3(i) = 1000*(i+35);
        q3(i) = lh_demand(w3(i),params) - 2000000;
        if q3(i) < 0
            q3(i) = 0;
        end    
    end

    
    
    
    % Find equilibrium SH wage
	params = [sh_intercept,sh_demand_e,sh_lh_response,fe_long,fe_short,fe_other,wage_supply_e,lf];
    w0 = 10000;
    if stop_feedback == 0
        f = @(w) excess_demand_sh(w,LH_wage,O_wage,lh_employment,params);
    end
    if stop_feedback == 1
        f = @(w) excess_demand_sh(w,LH_wage,O_wage,stop_feedback_lhe,params);
    end
    SH_wage = fmincon(f,w0);

    
    % Get SH employment
    if stop_feedback == 0
        sh_employment = sh_demand(SH_wage,lh_employment,params);
    end
    if stop_feedback == 1
        sh_employment = sh_demand(SH_wage,stop_feedback_lhe,params);
    end
    
    % Check if converged and don't let SH wage go above 60,000 
    % (this is the point whhere LH labor supply has switched entirely to SH)
    step = (LH_wage - LH_wage_lagged)^2 + (SH_wage - SH_wage_lagged)^2;
    if  step <= 0.001
        if SH_wage > 60000 & stop_feedback == 0
            stop_feedback = 1;
            stop_feedback_lhe = lh_employment;
        end
    end
    LH_wage_lagged = (LH_wage + LH_wage_lagged + LH_wage_lagged )/3;
    SH_wage_lagged = (SH_wage + SH_wage_lagged + SH_wage_lagged )/3;
    
    zero_test
end

if year > 1
	wage_diff = LH_wage - base_w;
	zero_test =  abs(wage_diff)
	if wage_diff > 0
		lf_adjust(year) = lf_adjust(year) + 100000;
	else
		lf_adjust(year) = lf_adjust(year) - 100000;
	end
	
	base_q = lh_employment;
	delta = base_q*0.027;
	if year > 7
		delta = base_q*0.02;
	end
	
else 
	base_q = lh_employment;
	delta = base_q*0.027;
	%delta = (lh_employment*0.37)/11;
	base_w = LH_wage;
	zero_test = 0
end

end

end


save('../intermediate/lf_adjust.mat','lf_adjust');
save('../intermediate/intercept_adjust.mat','intercept_adjust');


%%%%%%%%%%%%%
% Functions %
%%%%%%%%%%%%%

function e = excess_demand_lh(wage_lh, wage_sh, wage_o, params)
    lh_intercept = params(1);
    lh_demand_e = params(2);
    fe_long = params(3);
    fe_short = params(4);
    fe_other = params(5);
    supply_e = params(6);
    pool = params(7);
    demand_shift = params(8);
    demand = 140000000*exp(lh_intercept + log(wage_lh)*lh_demand_e) - demand_shift;
    supply_share = exp(fe_long + log(wage_lh)*supply_e)/ ...
                   (1+exp(fe_short + log(wage_sh)*supply_e)+ ...
                   exp(fe_long + log(wage_lh)*supply_e)+ ...
                   exp(fe_other + log(wage_o)*supply_e));
    e = abs(demand - pool*supply_share);
    if wage_lh < 0
        e = 100000000;
    end
end


function e = excess_demand_sh(wage_sh, wage_lh, wage_o, lh_employment, params)
    sh_intercept = params(1);
    sh_demand_e = params(2);
    sh_lh_response = params(3);
    fe_long = params(4);
    fe_short = params(5);
    fe_other = params(6);
    supply_e = params(7);
    pool = params(8);
    demand = 140000000*exp(sh_intercept + log(wage_sh)*sh_demand_e + lh_employment*sh_lh_response) ;
    supply_share = exp(fe_short + log(wage_sh)*supply_e)/ ...
                   (1+exp(fe_short + log(wage_sh)*supply_e)+ ...
                   exp(fe_long + log(wage_lh)*supply_e)+ ...
                   exp(fe_other + log(wage_o)*supply_e));
    e = abs(demand - pool*supply_share);
    if wage_sh < 0
        e = 100000000;
    end
end

function q = lh_demand(w,params)
    lh_intercept = params(1);
    lh_demand_e = params(2);
    q = 140000000*exp(lh_intercept + log(w)*lh_demand_e) - demand_shift;
end

function q = sh_demand(w,lh_employment,params)
    sh_intercept = params(1);
    sh_demand_e = params(2);
    sh_lh_response = params(3);
    q = 140000000*exp(sh_intercept + log(w)*sh_demand_e + lh_employment*sh_lh_response);
end

function q = lh_supply(w,params,ws,wo)
    lh_intercept = params(1);
    lh_demand_e = params(2);
    fe_long = params(3);
    fe_short = params(4);
    fe_other = params(5);
    supply_e = params(6);
    pool = params(7);
    supply_share = exp(fe_long + log(w)*supply_e)/ ...
                   (1+exp(fe_short + log(ws)*supply_e)+ ...
                   exp(fe_long + log(w)*supply_e)+ ...
                   exp(fe_other + log(wo)*supply_e));
   q = pool*supply_share;
end



end
