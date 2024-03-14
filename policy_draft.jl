using Random

#change if needed
lookahead_days = 5 
initial_scenarios = 1000

inital_price1 = 2
inital_price2 = 5
inital_price3 = 10
initial_prices = [inital_price1, inital_price2, inital_price3]



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

# Discretize scenarios
function discretize_scenarios(scenarios)
    # Define discrete price values
    # Round each price to closest values
    return round.(scenarios)
end

# Reduce scenarios
function reduce_scenarios(scenarios, max_scenarios)
end





