# Assingment 1c

# Solve each scenario individually 
# Apply the best solution when uncertainty is resolved 

using Gurobi
using JuMP
using Printf
using Pkg
using DataFrames
using XLSX

#include data from assignment 1b 
include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/deliverable_1b.jl")


function optimal_in_hindsight(prices)

    # Read the data and constants from other file 
    number_of_warehouses, W, cost_miss_b, cost_tr_e, warehouse_capacities, transport_capacities, initial_stock_z, number_of_simulation_periods, sim_T, demand_trajectory = load_the_data()

    # # Make model with Gurobi
    model = Model(Gurobi.Optimizer)

    # Define our variables, all positive
    @variable(model, x[w = W, t = sim_T] >= 0) # The amount of coffee bought for external suppliers for warehouse w at time t 
    @variable(model, z[w = W, t = sim_T] >= 0) # The amount of coffee stored at warehouse w at time t 
    @variable(model, y_send[w = W, q = W, t = sim_T] >= 0) # The amount of coffee sent by warehouse w to warehouse q at time t
    @variable(model, y_rec[w = W, q = W, t = sim_T] >= 0) # The amount of coffee received by warehouse w from warehouse q at time t
    @variable(model, m[w = W, t = sim_T] >= 0) # The amount of coffee missing from the daily demand for warehouse w 

    # Define our objective function 
    OB = sum(sum(prices[w] * x[w, t] for w in W, t in sim_T) + sum((cost_tr_e[w, t] * y_rec[w, q, t]) + (cost_miss_b[w] * m[w, t]) for w in W, q in W, t in sim_T))
    @objective(model, Min, OB)

    # Define our constraints 
    # 1. Constraint for storage limits
    for t in sim_T 
        for w in W
            @constraint(model, z[w, t] <= warehouse_capacities[w])
        end
    end 

    # 2. Constraint for transportation limits 
    for t in  sim_T
        for w in W
            @constraint(model, sum(y_send[w, q, t] for q in W if q != w) <= sum(transport_capacities[w, q] for q in W if q != w)) 
        end
    end 

    # 3. Constraint for initial storage
    for t in sim_T
        for w in W
            if t == 1
                @constraint(model, sum(y_send[w, q, t] for q in W if q != w) <= initial_stock_z[w])  # Constraint for the first time period
            else
                @constraint(model, sum(y_send[w, q, t] for q in W if q != w) <= z[w, t - 1])  # Constraint for subsequent time periods
            end
        end
    end
    

    # 4. Constraint to ensure that the coffee demand is always met 
    for t in sim_T
        for w in W
            @constraint(model, z[w,t] + sum(y_rec[w,q,t] for q in W if q != w) >= demand_trajectory[w,t])
        end 
    end 

    # 5. Constraint to balance everything in the warehouse network
    for t in sim_T 
        for w in W
            if t == 1
                @constraint(model, (x[w,t] + m[w,t] + initial_stock_z[w]
                + sum(y_rec[w,q,t] for q in W if q != w) 
                - sum(y_send[w,q,t] for q in W if q != w) 
                - demand_trajectory[w,t]) == z[w,t])
            else 
                @constraint(model, (x[w,t] + m[w,t] + z[w, t-1]
                + sum(y_rec[w,q,t] for q in W if q != w) 
                - sum(y_send[w,q,t] for q in W if q != w) 
                - demand_trajectory[w,t]) == z[w,t])
            end 
        end
    end 

    #6. Constraint what has been sent is equal to what has been received throughout the all networks
    for t in sim_T
        for w in W
            @constraint(model, sum(y_rec[w,q,t] for q in W if q != w) == sum(y_send[w,q,t] for q in W if q != w))
        end
    end 

    #7. Constraint  All variables greater or equal to zero 
    for t in sim_T 
        for w in W 
            for q in W 
                @constraint(model, y_send[w,q,t] >= 0)
                @constraint(model, y_rec[w,q,t] >= 0)
            end 
            @constraint(model, x[w,t] >= 0)
            @constraint(model, z[w,t] >= 0)
            @constraint(model, m[w,t] >= 0)
        end 
    end 

    # Solve 
    optimize!(model)

    if termination_status(model) == MOI.OPTIMAL
        println("All went well")
        obj_val = objective_value(model)
        values = [value(variable) for variable in all_variables(model)]

        # for (i, variable) in enumerate(all_variables(model))
        #     println("$(variable) = $(values[i])")
        # end
        # for w in W, t in sim_T
        #     println("x[$w, $t] = ", value(x[w, t]), ", m[$w, $t] = ", value(m[w, t]), ", z[$w, $t] = ", value(z[w, t]))
        # end
        # Save results to dataframe, if necessary 
        # XLSX.writexlsx("results_assignment1c.xlsx", 
        # DataFrame = DataFrame(variable = values, value = obj_val))
        
    end
    
    return values, obj_val
end

function Calculate_OiH_solution(prices1, prices2)

    stage_one_decision, cost1 = optimal_in_hindsight(prices1)
    stage_two_decision, cost2 = optimal_in_hindsight(prices2) 
    cost = cost1+cost2

    return [stage_one_decision, stage_two_decision], cost 
end 

# Set inital prices 
inintal_price1 = 10
inintal_price2 = 10
inintal_price3 = 10
initial_prices = [inintal_price1, inintal_price2, inintal_price3]
prices_day_two = [sample_next(inintal_price1), sample_next(inintal_price2), sample_next(inintal_price1)]
here_and_now_dec = Make_EV_here_and_now(initial_prices)

# Run the function to get the data 
decisions, costs = Calculate_OiH_solution(initial_prices, prices_day_two)
