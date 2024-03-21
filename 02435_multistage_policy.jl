using Random
using JuMP
using Gurobi
using Printf

""" Task 2: Make Policy
Input = number_of_sim_periods, tau, c_stock, current_prices
Output = Here-and-now decisions """

include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/V2_02435_multistage_problem_data.jl")
include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/V2_price_process.jl")

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
    num_scenarios = length(scenarios)
    if num_scenarios < max_scenarios
        while length(scenarios) < max_scenarios
            scenario = rand(scenarios)
            push!(scenarios, scenario)
        end
        return scenarios
    else
        return scenarios
    end
end

function reassign_probabilites(scenarios)
    probabilities = fill(1/length(scenarios), length(scenarios)) 
    return probabilities
end

# Create non-anticipativity sets
function create_non_anticipativity_sets(scenarios)
    return scenarios
end

function make_multistage_here_and_now_decision(number_of_sim_periods, tau, current_stock, current_prices)
    # Get data from multi-stage file 
    number_of_warehouses, W, cost_miss_b, cost_tr_e, warehouse_capacities, transport_capacities, initial_stock, number_of_simulation_periods, sim_T, demand_trajectory = load_the_data()
    max_scenarios = 10 

    # At each time step create scenarios 
    scenarios = generate_scenarios(initial_prices,initial_scenarios)
    discrete_scen = discretize_scenarios(scenarios)
    scenarios_reduced = reduce_scenarios(discrete_scen, 10)

    probabilities = reassign_probabilites(scenarios_reduced)
    expected_price = sum(scenarios_reduced .* probabilities)

    x_results = []
    send_results = []
    rec_results = []
    z_results = []
    m_results = []
    cost_results = []

    println("scenarios_red", length(scenarios_reduced))
    # for s in 1:length(scenarios_reduced)

    #     ## Make model with Gurobi
    #     model_multistage = Model(Gurobi.Optimizer)

    #     # Define our variables, all positive
    #     @variable(model_multistage, x[w = W] >= 0) 
    #     @variable(model_multistage, z[w = W] >= 0)  
    #     @variable(model_multistage, y_send[w = W, q = W] >= 0) 
    #     @variable(model_multistage, y_rec[w = W, q = W] >= 0) 
    #     @variable(model_multistage, m[w = W] >= 0) 

    #     # Define our objective function 
    #     OB = sum(probabilities[s] * (
    #             sum(expected_price[w] * x[w] for w in W) +
    #             sum((cost_tr_e[w] * y_rec[w, q]) + (cost_miss_b[w] * m[w]) for w in W, q in W)))

    #     @objective(model_multistage, Min, OB)

    #     # Define our constraints 
    #     # 1. Constraints for storage limits
    #     for w in W
    #         @constraint(model_multistage, z[w] <= warehouse_capacities[w])
    #     end

    #     # 2. Constraint for transportation limits 
    #     for w in W
    #         @constraint(model_multistage, sum(y_send[w, q] for q in W if q != w) <= sum(transport_capacities[w, q] for q in W if q != w)) 
    #     end

    #     # 3. Constraint for initial storage
    #     for w in W
    #         @constraint(model_multistage, sum(y_send[w, q] for q in W if q != w) <= z[w]) 
    #     end

    #     # 4. Ensure that the coffee demand is always met 
    #     for w in W
    #         @constraint(model_multistage, z[w] + sum(y_rec[w, q] for q in W if q != w) >= demand_trajectory[w])
    #     end

    #     # 5. Balance constraint
    #     for w in W
    #         @constraint(model_multistage, (x[w] + m[w] + z[w]
    #             + sum(y_rec[w, q] for q in W if q != w) 
    #             - sum(y_send[w, q] for q in W if q != w) 
    #             - demand_trajectory[w]) == z[w])
    #     end

    #     # 6. What has been sent is equal to what has been received throughout the entire network
    #     for w in W
    #         @constraint(model_multistage, sum(y_rec[w, q] for q in W if q != w) == sum(y_send[w, q] for q in W if q != w))
    #     end

    #     # 7. All variables greater or equal to zero 
    #     for w in W 
    #         for q in W 
    #             @constraint(model_multistage, y_send[w, q] >= 0)
    #             @constraint(model_multistage, y_rec[w, q] >= 0)
    #         end 
    #         @constraint(model_multistage, x[w] >= 0)
    #         @constraint(model_multistage, z[w] >= 0)
    #         @constraint(model_multistage, m[w] >= 0)
    #     end

    #     # 8. Constraint for non-anticipativity
    #     if s != 1
    #         for w in W
    #             @constraint(model_multistage, x[w] == x_results[s-1][w])
    #             @constraint(model_multistage, z[w] == z_results[s-1][w])
    #             @constraint(model_multistage, m[w] == m_results[s-1][w])
    #             for q in W
    #                 @constraint(model_multistage, y_send[w, q] == send_results[s-1][w, q])
    #                 @constraint(model_multistage, y_rec[w, q] == rec_results[s-1][w, q])
    #             end
    #         end
    #     end

    #     # Solve 
    #     optimize!(model_multistage)

    #     if termination_status(model_multistage) == MOI.OPTIMAL
    #         println("Optimization succeeded for scenario $s")
    #         push!(x_results, value.(x))
    #         push!(send_results, value.(y_send))
    #         push!(rec_results, value.(y_rec))
    #         push!(z_results, value.(z))
    #         push!(m_results, value.(m))

    #         push!(cost_results, objective_value(model_multistage))
    #     else
    #         println("Optimization failed for scenario $s")
    #     end 

    # end 

    # min_cost_index = argmin(cost_results) 
    # return x_results[min_cost_index], send_results[min_cost_index], rec_results[min_cost_index], z_results[min_cost_index], m_results[min_cost_index]

end

# Define parameters 
# Max scenarios 86 
initial_scenarios = 50
max_scenarios = 10 

initial_price1 = 2
initial_price2 = 2
initial_price3 = 2
initial_prices = [initial_price1, initial_price2, initial_price3]

tau = 1 
number_of_sim_periods = 5 
current_stock = [2,2,2]
current_prices = [1,2,1]
decision =  make_multistage_here_and_now_decision(number_of_sim_periods, tau, current_stock, current_prices)
print(decision)
