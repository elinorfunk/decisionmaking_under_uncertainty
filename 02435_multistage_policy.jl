using Random

# Task 2: Make Policy
# Input = number_of_sim_periods, tau, current_stock, current_prices
# Output = Here-and-now decisions


include("C:\\Users\\helle\\Desktop\\02435Decision making under uncertainty\\Julia codes\\decision_making\\Assignment_A\\decisionmaking_under_uncertainty\\V2_02435_two_stage_problem_data.jl")
include("C:\\Users\\helle\\Desktop\\02435Decision making under uncertainty\\Julia codes\\decision_making\\Assignment_A\\decisionmaking_under_uncertainty\\V2_price_process.jl")


# !!!!! change if needed
lookahead_days = 5 
initial_scenarios = 1000

inital_price1 = 2
inital_price2 = 5
inital_price3 = 10
initial_prices = [inital_price1, inital_price2, inital_price3]

# Scenario Generation
function generate_scenarios(current_prices, lookahead_days, initial_scenarios)
    scenarios = Array{Float64}(undef, length(current_prices), lookahead_days, initial_scenarios)
    for s in 1:initial_scenarios
        scenarios[:, 1: s] = current_prices
        for t in 2:lookahead_days
            price_samples = [sample_next(prices_day_one[1]), sample_next(prices_day_one[2]), sample_next(prices_day_one[3])]
            scenarios[:, t, s] = sample_next(current_prices)
        end
    end
    return scenarios
end

# Discretize scenarios: Define discrete price values
function discretize_scenarios(scenarios)
    # Round each price to closest values
    return round.(scenarios)
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

function reassign_probabilites(scenarios)
    num_scenarios = size(scenarios, 3)
    probabilities = ones(num_scenarios) / num_scenarios
    return probabilities
end

# Create & populate non-anticipativity sets
function create_non_anticipativity_sets(scenarios)
    return nothing
end

function make_multistage_here_and_now_decision(number_of_sim_periods, tau, current_stock, current_prices)

    scenarios = generate_scenarios(current_prices, lookahead_days, initial_scenarios)

    discretize_scenarios = discretize_scenarios(scenarios)

    # !!!! HERE WE MUST DETERMINE WHAT MAX_SCENARIOS IS need to fill it in with our number
    scenarios_reduced = reduce_scenarios(discretize_scenarios, max_scenarios)

    probabilities = reassign_probabilites(scenarios_reduced)

    create_non_anticipicity_sets(scenarios_reduced)

    # Here is where we make our here-and-now decision based on allllll of that...
    # -- make sure to use the discretized scenarios in order to encode non-anticipativity


    # return decision

end











