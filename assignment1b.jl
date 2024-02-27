# Assingment 1b 

# using Gurobi
# using JuMP
# using Printf
# using Pkg
# Pkg.add("Distributions")

# # Include other files 
# include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/V2_02435_two_stage_problem_data.jl")
# include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/V2_price_process.jl")


# # The Expected-Value benchmark 
# function Make_EV_here_and_now(prices_day_one)
#     here_and_now_decision = 0 
#     return here_and_now_decision
# end

# # Read the data and constants from other file 
# number_of_warehouses, W, cost_miss, cost_tr, warehouse_capacities, transport_capacities, initial_stock, number_of_simulation_periods, sim_T, demand_trajectory = load_the_data()

# # # Make model with Gurobi
# model = Model(Gurobi.Optimizer)

# # Define our variables, all positive
# @variable(model, 0 <= x_wt) # The amount of coffee bought for external suppliers for warehouse w at time t 
# @variable(model, 0 <= z_wt) # The amount of coffee stored at warehouse w at time t 
# @variable(model, 0 <= y_wqt_sent) # The amount of coffee sent by warehouse w to warehouse q at time t
# @variable(model, 0 <= y_wqt_recieved) # The amount of coffee recieved by warehouse w to warehouse q at time t
# @variable(model, 0 <= m_wt) # The amount of coffee missing from the daily demand for warehouse w 

# objective_function = 0
# @objective(model, Min, objective_function)

# # Define our constraints 


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

initial_price = 1
price = sample_next(initial_price)

# # Make model with Gurobi
model = Model(Gurobi.Optimizer)

# Add variables
x_wt = []
z_wt = []
y_wqt_sent = []
y_wqt_recieved = [] 
m_wt = [] 

# # Define our variables, all positive


@variable(model, 0 <= x_wt) # The amount of coffee bought for external suppliers for warehouse w at time t 
@variable(model, 0 <= z_wt) # The amount of coffee stored at warehouse w at time t 
@variable(model, 0 <= y_wqt_sent) # The amount of coffee sent by warehouse w to warehouse q at time t
@variable(model, 0 <= y_wqt_recieved) # The amount of coffee recieved by warehouse w to warehouse q at time t
@variable(model, 0 <= m_wt) # The amount of coffee missing from the daily demand for warehouse w 

# # Define our objective function 
objective_function = sum(price[w, t] * x_wt[w, t] for w in W, t in sim_T) +
sum(cost_tr_e[w, t] * y_wqt_sent[w, q, t] + cost_miss_b[w] * m_wt[w, t] for w in W, t in sim_T)
@objective(model, Min, objective_function)

# # Define our constraints 
# @constraint(model, 0 <= z_wt[w, t] <= transport_capacities[w] for w in W, t in T) # 1. constraint about storage
# @constraint(model, sum(y_wqt_send[w, q, t] for q in Q if q != w) <= sum(transport_capacities[w, q] for q in Q if q != w, q in Q)) #2. constraint 
# @constraint(model, sum(y_wqt_send[w, q, t] for q in Q if q != w) <= z_wt[w, t-1] for w in W, t in sim_T) # 3. constraint 

# @constraint(model, z_wt[w,t] + y_wqt_recieved[w, q, t] >= demand_trajectory[w, t] for w in W, q in W, t in sim_T)
# @constraint(model, (x_wt[w,t] + m_wt[w,t] + z_wt[w,t-1] + sum(y_wqt_recieved[w, q, t] for q in Q if q != w) - sum(y_wqt_send[w, q, t] for q in Q if q != w) - demand_trajectory for w in W, t in sim_T, q in Q) = z_wt[w,t])

