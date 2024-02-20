# Assingment 1b 

using Gurobi
using Printf
using Pkg
Pkg.add("Distributions")

# import data from 
include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/V2_02435_two_stage_problem_data.jl")
include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/V2_price_process.jl")


# The Expected-Value benchmark 
function Make_EV_here_and_now(prices_day_one)
    here_and_now_decision = 0 
    return here_and_now_decision
end

# Make model with Gurobi
model = Model(Gurobi.Optimizer)

# Define our variables, all positive
@variable(model, 0 <= x_wt) # The amount of coffee bought for external suppliers for warehouse w at time t 
@variable(model, 0 <= z_wt) # The amount of coffee stored at warehouse w at time t 
@variable(model, 0 <= y_wqt_sent) # The amount of coffee sent by warehouse w to warehouse q at time t
@variable(model, 0 <= y_wqt_recieved) # The amount of coffee recieved by warehouse w to warehouse q at time t
@variable(model, 0 <= m_wt) # The amount of coffee missing from the daily demand for warehouse w 

# Define our objective function 
# @objective(model, Min)


# Define our constraints 




