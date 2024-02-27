
# Assingment 1b 

using Gurobi
using JuMP
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

# Read the data and constants from other file 
number_of_warehouses, W, cost_miss_b, cost_tr_e, warehouse_capacities, transport_capacities, initial_stock_z, number_of_simulation_periods, sim_T, demand_trajectory = load_the_data()

# Set random inital prices
inintal_price1 = 1 
inintal_price2 = 1 
inintal_price3 = 1 
prices = [sample_next(inintal_price1), sample_next(inintal_price2), sample_next(inintal_price3)]

# # Make model with Gurobi
model = Model(Gurobi.Optimizer)

# Define our variables, all positive
@variable(model, x[w = W, t = sim_T] >= 0) # The amount of coffee bought for external suppliers for warehouse w at time t 
@variable(model, z[w = W, t = sim_T] >= 0) # The amount of coffee stored at warehouse w at time t 
@variable(model, y_sent[w = W, q = W, t = sim_T] >= 0) # The amount of coffee sent by warehouse w to warehouse q at time t
@variable(model, y_rec[w = W, q = W, t = sim_T] >= 0) # The amount of coffee recieved by warehouse w to warehouse q at time t
@variable(model, m[w = W, t = sim_T] >= 0) # The amount of coffee missing from the daily demand for warehouse w 

# Define our objective function 
OB = sum(sum(prices[w] * x[w, t] for w in W, t in sim_T) 
+ sum((cost_tr_e[w, t] * y_rec[w, q, t]) + (cost_miss_b[w] * m[w, t]) for w in W, q in W, t in sim_T) for t in sim_T)
@objective(model, Min, OB)

# # Define our constraints 

 # Constraints for storage capacities 
@constraint(model, transport1[1, t in sim_T], z[1, t] <= warehouse_capacities[1])
@constraint(model, transport2[2, t in sim_T], z[2, t] <= warehouse_capacities[2]) # 1. constraint about storage from warehouse 2
@constraint(model, transport3[3, t in sim_T], z[3, t] <= warehouse_capacities[3]) # 1. constraint about storage from warehouse 3

# @constraint(model, sum(y_wqt_send[w, q, t] for q in Q if q != w) <= sum(transport_capacities[w, q] for q in Q if q != w, q in Q)) #2. constraint 
# @constraint(model, sum(y_wqt_send[w, q, t] for q in Q if q != w) <= z_wt[w, t-1] for w in W, t in sim_T) # 3. constraint 
# @constraint(model, z_wt[w,t] + y_wqt_recieved[w, q, t] >= demand_trajectory[w, t] for w in W, q in W, t in sim_T)
# @constraint(model, (x_wt[w,t] + m_wt[w,t] + z_wt[w,t-1] + sum(y_wqt_recieved[w, q, t] for q in Q if q != w) - sum(y_wqt_send[w, q, t] for q in Q if q != w) - demand_trajectory for w in W, t in sim_T, q in Q) = z_wt[w,t])

# Solve 
 optimize!(model)
