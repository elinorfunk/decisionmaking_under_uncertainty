using Random

# Task 2: Make Policy
# Input = number_of_sim_periods, tau, current_stock, current_prices
# Output = Here-and-now decisions


include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/V2_02435_multistage_problem_data.jl")
include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/V2_price_process.jl")


# !!!!! change if needed
#lookahead_days = 5 
initial_scenarios = 1000

inital_price1 = 2
inital_price2 = 5
inital_price3 = 10
initial_prices = [inital_price1, inital_price2, inital_price3]

# Get data from multistage file 
number_of_warehouses, W, cost_miss, cost_tr_e, warehouse_capacities, transport_capacities, initial_stock, number_of_simulation_periods, sim_T, demand_trajectory = load_the_data()

# Scenario Generation
# function generate_scenarios(current_prices, lookahead_days, initial_scenarios)
#     scenarios = Array{Float64}(undef, length(current_prices), lookahead_days, initial_scenarios)
#     for s in 1:initial_scenarios
#         scenarios[:, 1: s] = current_prices
#         for t in 2:lookahead_days
#             price_samples = [sample_next(prices_day_one[1]), sample_next(prices_day_one[2]), sample_next(prices_day_one[3])]
#             scenarios[:, t, s] = sample_next(current_prices)
#         end
#     end
#     return scenarios
# end

function generate_scenarios(initial_prices, initial_scenarios)
    scenarios = [[sample_next(initial_prices[1]), sample_next(initial_prices[2]), sample_next(initial_prices[3])] for _ in 1:initial_scenarios]
    return scenarios
end

# Discretize scenarios: Define discrete price values
function discretize_scenarios(scenarios)
    # Round each price to closest values
    rounded_scenarios = [[round(x) for x in subscenario] for subscenario in scenarios]
    return rounded_scenarios #round.(scenarios, digits=0)
end

# Reduce scenarios
function reduce_scenarios(scenarios, max_scenarios)
    num_scenarios = size(scenarios, 3)
    if num_scenarios > max_scenarios
        indices = randperm(num_scenarios)[1:max_scenarios]
        return scenarios[:, :, indices]
    else
        return scenarios
    end
end

function reassign_probabilites(scenarios)
    probabilities = fill(1/length(scenarios), length(scenarios)) 
    # num_scenarios = size(scenarios, 3)
    # probabilities = ones(num_scenarios) / num_scenarios
    return probabilities
end

# Create & populate non-anticipativity sets
# function create_non_anticipicity_sets(scenarios)
#     return 0
# end

function make_multistage_here_and_now_decision(initial_prices, initial_scenarios, number_of_sim_periods, tau, current_stock, current_prices, max_scenarios, cost_miss_b, cost_tr_e)
    global sim_T 
    global W 

    scenarios = generate_scenarios(initial_prices, initial_scenarios)

    discrete_scen = discretize_scenarios(scenarios)

    # # !!!! HERE WE MUST DETERMINE WHAT MAX_SCENARIOS IS need to fill it in with our number
    scenarios_reduced = reduce_scenarios(discrete_scen, max_scenarios)

    probabilities = reassign_probabilites(scenarios)
    S = collect(1:length(scenarios))

    #create_non_anticipicity_sets(scenarios_reduced)

    expected_price = sum(scenarios_reduced .* probabilities)

    # Here is where we make our here-and-now decision based on allllll of that...
    # -- make sure to use the discretized scenarios in order to encode non-anticipativity

     # # Make model with Gurobi
     model_multistage = Model(Gurobi.Optimizer)

     # Define our variables, all positive
     @variable(model_multistage, x[w = W, t = sim_T, s = S] >= 0) 
     @variable(model_multistage, z[w = W, t = sim_T, s = S] >= 0)  
     @variable(model_multistage, y_send[w = W, q = W, t = sim_T, s = S] >= 0) 
     @variable(model_multistage, y_rec[w = W, q = W, t = sim_T, s = S] >= 0) 
     @variable(model_multistage, m[w = W, t = sim_T, s = S] >= 0) 


    # cost_tr_e is the issue 
    # #Define our objective function 
    OB = sum(probabilities[s] * (
        sum(expected_price[w] * x[w, t, s] for w in W, t in sim_T) + sum((cost_tr_e[w] * y_rec[w, q, t, s]) + (cost_miss_b[w] * m[w, t, s]) for w in W, q in W, t in sim_T)
        ) for s in 1:length(scenarios))


    @objective(model_multistage, Min, OB)

    # Define our constraints 
    # # 1. Constraints for storage limits
    for t in sim_T 
        for w in W
            for s in S
            @constraint(model_multistage, z[w, t, s] <= warehouse_capacities[w])
            end
        end
    end     

    # 2. Constraint for transportation limits 
    for t in  sim_T
        for w in W
            for s in S
            @constraint(model_multistage, sum(y_send[w, q, t, s] for q in W if q != w) <= sum(transport_capacities[w, q] for q in W if q != w)) 
            end
        end
    end 

    # 3. Constraint for initial storage
    for t in sim_T
        for w in W
            for s in S
                 if t == 1
                     @constraint(model_multistage, sum(y_send[w, q, t, s] for q in W if q != w) <= current_stock[w])  # Constraint for the first time period
                 else
                     @constraint(model_multistage, sum(y_send[w, q, t, s] for q in W if q != w) <= z[w, t - 1, s])  # Constraint for subsequent time periods
                end
            end
        end
    end
    

    # 4. Ensure that the coffee demand is always met 
    for t in sim_T
        for w in W
            for s in S
            @constraint(model_multistage, z[w,t,s] + sum(y_rec[w,q,t, s] for q in W if q != w) >= demand_trajectory[w,t])
            end
        end 
    end 

    # 5. Balance constraint
    for t in sim_T 
        for w in W
            for s in S
                if t == 1
                    @constraint(model_multistage, (x[w,t,s] + m[w,t,s] + current_stock[w]
                    + sum(y_rec[w,q,t, s] for q in W if q != w) 
                    - sum(y_send[w,q,t, s ] for q in W if q != w) 
                    - demand_trajectory[w,t]) == z[w,t,s])
                else 
                    @constraint(model_multistage, (x[w,t,s] + m[w,t,s] + z[w, t-1,s]
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
                @constraint(model_multistage, sum(y_rec[w,q,t, s] for q in W if q != w) == sum(y_send[w,q,t, s] for q in W if q != w))
            end
        end

    end 
    #7. What has been sent is equal to what has been received throughout the all networks

        for t in sim_T
            for w in W
                for s in S
                    @constraint(model_multistage, sum(y_rec[w,q,t,s] for q in W if q != w) == sum(y_send[w,q,t,s] for q in W if q != w))
                end
            end
        end 

    # 8. All variables greater or equal to zero 
    for t in sim_T
        for w in W 
            for s in S
                for q in W 
                        @constraint(model_multistage, y_send[w,q,t,s] >= 0)
                        @constraint(model_multistage, y_rec[w,q,t,s] >= 0)
                    end 
                    @constraint(model_multistage, x[w,t,s] >= 0)
                    @constraint(model_multistage, z[w,t,s] >= 0)
                    @constraint(model_multistage, m[w,t,s] >= 0)
            end
        end 
    end 

    # 9. Constraint for non-anticipativity
    for w in W
        for t in sim_T[2:end]  
            for s in S
                @constraint(model_multistage, x[w, t, s] == x[w, t-1, s]) 
                @constraint(model_multistage, z[w, t, s] == z[w, t-1, s])  
                @constraint(model_multistage, m[w, t, s] == m[w, t-1, s])  
                for q in W
                    @constraint(model_multistage, y_send[w, q, t, s] == y_send[w, q, t-1, s]) 
                    @constraint(model_multistage, y_rec[w, q, t, s] == y_rec[w, q, t-1, s])     
                end 
            end
        end
    end
    
    # for w in W
    #     for q in W
    #         for t in 2:sim_T  
    #             for s in S
    #                 @constraint(model, y_send[w, q, t, s] == y_send[w, q, t-1, s])  # Non-anticipativity constraint for y_send
    #                 @constraint(model, y_rec[w, q, t, s] == y_rec[w, q, t-1, s])      # Non-anticipativity constraint for y_rec
    #             end
    #         end
    #     end
    # end


    # Solve 
    optimize!(model_multistage)

    if termination_status(model_multistage) == MOI.OPTIMAL
        println("Optimization succeeded")
        return 1
    else
        return 0
    end 
    

end

tau = 1
current_stock = [2,2,2]
max_scenarios = 10 
decision = make_multistage_here_and_now_decision(initial_prices, initial_scenarios, number_of_simulation_periods, tau, current_stock, initial_prices, max_scenarios, cost_miss, cost_tr_e)


