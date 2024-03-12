
#  make_schocastic_here_and_now_decision = 
#  Function: makes a stochastic here-and-now decision by using a specified number 
#  of scenarios N for the second-stage prices.

# Input: prices at day one, 
# Output: (here-and-now) decisions at day one (by also reasoning about what is expected to happen in day two)

#  generate 1000 equally probable scenarios using sample next
#  (given the initial prices), reduce them to N representative ones with appropriate probabilities, and use those to
#  solve a 2-stage stochastic program.

# Deliverable 1.d

using Gurobi
using JuMP
using Printf
using Pkg
using DataFrames
using CSV
using Distributions  # Adding Distributions package

Pkg.add("Distributions")

# import data from 
include("C://Users//helle//Desktop//02435Decision making under uncertainty//Julia codes//decision_making//Assignment_A//decisionmaking_under_uncertainty//V2_02435_two_stage_problem_data.jl")
include("C://Users//helle//Desktop//02435Decision making under uncertainty//Julia codes//decision_making//Assignment_A//decisionmaking_under_uncertainty//V2_price_process.jl")


function Make_Stochastic_here_and_now_decision(prices_day_one, N)
    global sim_T  # Added to access sim_T globally

    # Read the data and constants from other file 
    number_of_warehouses, W, cost_miss_b, cost_tr_e, warehouse_capacities, transport_capacities, initial_stock_z, number_of_simulation_periods, sim_T, demand_trajectory = load_the_data()

    # generate 1000 equally probable scenarios using sample next (given the initial prices)
    scenarios = [[sample_next(prices_day_one[1]), sample_next(prices_day_one[1]), sample_next(prices_day_one[2])] for _ in 1:1000] ### 1000 SIMULATION PERIODS?
    
    #reduce them to N representative ones with appropriate probabilities
    ## N representative

    N_representative_scenarios_indices = randperm(length(scenarios))[1:N]

    N_representative_scenarios = length(N_representative_scenarios_indices)

    S = 1: N_representative_scenarios

    ## Probabilities
    #probabilities = fill(1/N, N) ### WORK IT OUT
    probabilities = fill(1/length(N_representative_scenarios_indices), N) 


    expected_price = mean(scenarios)

    # # Make model with Gurobi
    model = Model(Gurobi.Optimizer)

    # Define our variables, all positive
    @variable(model, x[w = W, t = sim_T, s = S] >= 0) # N_representative_scenarios because we want to get scenarios according to N chosen scenarios?
    @variable(model, z[w = W, t = sim_T, s = S] >= 0)  
    @variable(model, y_send[w = W, q = W, t = sim_T, s = S] >= 0) 
    @variable(model, y_rec[w = W, q = W, t = sim_T, s = S] >= 0) 
    @variable(model, m[w = W, t = sim_T, s = S] >= 0) 

    
    # Define our objective function 
    OB = sum(probabilities[s] * (
        sum(expected_price[w] * x[w, t, s] for w in W, t in sim_T)
        + sum((cost_tr_e[w, t] * y_rec[w, q, t, s]) + (cost_miss_b[w] * m[w, t, s]) for w in W, q in W, t in sim_T)
    ) for s in S)

    ### EXPECTED PRICE?
    @objective(model, Min, OB)

    # # Define our constraints 

    # # 1. Constraints for storage limits
    for t in sim_T 
        for w in W
            for s in S
            @constraint(model, z[w, t, s] <= warehouse_capacities[w])
            end
        end
    end     

    # 2. Constraint for transportation limits 
    for t in  sim_T
        for w in W
            for s in S
            @constraint(model, sum(y_send[w, q, t, s] for q in W if q != w) <= sum(transport_capacities[w, q] for q in W if q != w)) 
            end
        end
    end 

    # 3. Constraint for initial storage
    for t in sim_T
        for w in W
            for s in S
                 if t == 1
                     @constraint(model, sum(y_send[w, q, t, s] for q in W if q != w) <= initial_stock_z[w])  # Constraint for the first time period
                 else
                     @constraint(model, sum(y_send[w, q, t, s] for q in W if q != w) <= z[w, t - 1, s])  # Constraint for subsequent time periods
                end
            end
        end
    end
    

    # 4. Ensure that the coffee demand is always met 
    for t in sim_T
        for w in W
            for s in S
            @constraint(model, z[w,t,s] + sum(y_rec[w,q,t, s] for q in W if q != w) >= demand_trajectory[w,t])
            end
        end 
    end 

    # 5. Balance constraint
    for t in sim_T 
        for w in W
            for s in S
                if t == 1
                    @constraint(model, (x[w,t,s] + m[w,t,s] + initial_stock_z[w]
                    + sum(y_rec[w,q,t, s] for q in W if q != w) 
                    - sum(y_send[w,q,t, s ] for q in W if q != w) 
                    - demand_trajectory[w,t]) == z[w,t,s])
                else 
                    @constraint(model, (x[w,t,s] + m[w,t,s] + z[w, t-1,s]
                    + sum(y_rec[w,q,t, s] for q in W if q != w) 
                    - sum(y_send[w,q,t, s] for q in W if q != w) 
                    - demand_trajectory[w,t]) == z[w,t,s])
                end
            
            end 
        end
    end 

    #6. What has been sent is equal to what has been received throughout the all networks

    for t in sim_T
        for w in W
            for s in S
                @constraint(model, sum(y_rec[w,q,t, s] for q in W if q != w) == sum(y_send[w,q,t, s] for q in W if q != w))
            end
        end

    end 
    #7. What has been sent is equal to what has been received throughout the all networks

        for t in sim_T
            for w in W
                for s in S
                    @constraint(model, sum(y_rec[w,q,t,s] for q in W if q != w) == sum(y_send[w,q,t,s] for q in W if q != w))
                end
            end
        end 

    # 8. All variables greater or equal to zero 
    for t in sim_T
        for w in W 
            for s in S
                for q in W 
                        @constraint(model, y_send[w,q,t,s] >= 0)
                        @constraint(model, y_rec[w,q,t,s] >= 0)
                    end 
                    @constraint(model, x[w,t,s] >= 0)
                    @constraint(model, z[w,t,s] >= 0)
                    @constraint(model, m[w,t,s] >= 0)
            end
        end 
    end 

    

    # Solve 
    optimize!(model)

    if termination_status(model) == MOI.OPTIMAL
        println("All went good")
        obj_val = objective_value(model)
        values = [value(variable) for variable in all_variables(model)]

        for (i, variable) in enumerate(all_variables(model))
            println("$(variable) = $(values[i])")
        end
        for w in W, t in sim_T, s in 1: N_representative_scenarios
            println("x[$w, $t] = ", value(x[w, t, s]), ", m[$w, $t] = ", value(m[w, t, s]), ", z[$w, $t] = ", value(z[w, t, s]))
        end
        # Save results to dataframe, if necessary 
        # result_df = DataFrame(Variable = string.(names(model)), Value = values)
        # CSV.write("Result_assignemnt1b.csv", result_df)
    end
    return [values], expected_price 
end

# Set initial prices 
inintal_price1 = 2
inintal_price2 = 5
inintal_price3 = 10
initial_prices = [inintal_price1, inintal_price2, inintal_price3]
here_and_now_dec = Make_Stochastic_here_and_now_decision(initial_prices, 10)
