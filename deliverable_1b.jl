# Assingment 1b 

using Gurobi
using JuMP
using Printf
using Pkg
using DataFrames
using CSV
using Distributions  # Adding Distributions package
using XLSX

Pkg.add("Distributions")

# import data from 
# include("/Users/marloanzarut/Downloads/decisionmaking_under_uncertainty/V2_02435_two_stage_problem_data.jl")
# include("/Users/marloanzarut/Downloads/decisionmaking_under_uncertainty/V2_price_process.jl")

# Elinoprs files 
include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/V2_02435_two_stage_problem_data.jl")
include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/V2_price_process.jl")
# include("C://Users//helle//Desktop//02435Decision making under uncertainty//Julia codes//decision_making//Assignment_A//decisionmaking_under_uncertainty//V2_02435_two_stage_problem_data.jl")
# include("C://Users//helle//Desktop//02435Decision making under uncertainty//Julia codes//decision_making//Assignment_A//decisionmaking_under_uncertainty//V2_price_process.jl")


# The Expected-Value benchmark 
function Make_EV_here_and_now(prices_day_one)
    global sim_T  # Added to access sim_T globally

    # Read the data and constants from other file 
    number_of_warehouses, W, cost_miss_b, cost_tr_e, warehouse_capacities, transport_capacities, initial_stock_z, number_of_simulation_periods, sim_T, demand_trajectory = load_the_data()

    # Set random inital prices and get prices for next (?) day 
    prices_samples = [[sample_next(prices_day_one[1]), sample_next(prices_day_one[2]), sample_next(prices_day_one[3])] for _ in number_of_simulation_periods]
    expected_price = mean(prices_samples)

    # # Make model with Gurobi
    model = Model(Gurobi.Optimizer)

    # Define our variables, all positive
    @variable(model, x[w = W, t = sim_T] >= 0) # The amount of coffee bought for external suppliers for warehouse w at time t 
    @variable(model, z[w = W, t = sim_T] >= 0) # The amount of coffee stored at warehouse w at time t 
    @variable(model, y_send[w = W, q = W, t = sim_T] >= 0) # The amount of coffee sent by warehouse w to warehouse q at time t
    @variable(model, y_rec[w = W, q = W, t = sim_T] >= 0) # The amount of coffee received by warehouse w from warehouse q at time t
    @variable(model, m[w = W, t = sim_T] >= 0) # The amount of coffee missing from the daily demand for warehouse w 

    # Define our objective function 
    OB = sum(sum(expected_price[w] * x[w, t] for w in W, t in sim_T) + sum((cost_tr_e[w, t] * y_rec[w, q, t]) + (cost_miss_b[w] * m[w, t]) for w in W, q in W, t in sim_T))
    @objective(model, Min, OB)

    # # Define our constraints 

    # 1. Constraints for storage limits
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
    

    # 4. Ensure that the coffee demand is always met 
    for t in sim_T
        for w in W
            @constraint(model, z[w,t] + sum(y_rec[w,q,t] for q in W if q != w) >= demand_trajectory[w,t])
        end 
    end 

    # 5. Balance constraint
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

    # 6. All variables greater or equal to zero 
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

    #7. What has been sent is equal to what has been received throughout the all networks

    for t in sim_T
        for w in W
            @constraint(model, sum(y_rec[w,q,t] for q in W if q != w) == sum(y_send[w,q,t] for q in W if q != w))
        end
    end 

    # Solve 
    optimize!(model)

    if termination_status(model) == MOI.OPTIMAL
        println("All went good")
        obj_val = objective_value(model)
        values = [value(variable) for variable in all_variables(model)]

        # for (i, variable) in enumerate(all_variables(model))
        #     #println("$(variable) = $(values[i])")
        #     pass
        # end
        # for w in W, t in sim_T
        #     #println("x[$w, $t] = ", value(x[w, t]), ", m[$w, $t] = ", value(m[w, t]), ", z[$w, $t] = ", value(z[w, t]))
        #     pass 
        # end
        # Save results to dataframe, if necessary 
        # result_df = DataFrame(Variable = string.(names(model)), Value = values)
        # CSV.write("Result_assignemnt1b.csv", result_df)
    end
    return [values], obj_val, expected_price 
end

# Set initial prices 
inintal_price1 = 2
inintal_price2 = 5
inintal_price3 = 10
initial_prices = [inintal_price1, inintal_price2, inintal_price3]
here_and_now_dec = Make_EV_here_and_now(initial_prices)

