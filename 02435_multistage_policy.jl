using Gurobi
using JuMP
using Printf
using Pkg
using DataFrames
using CSV
using Distributions  # Adding Distributions package
using XLSX
using Random

Pkg.add("Distributions")

include("/Users/marloanzarut/Downloads/decisionmaking_under_uncertainty/V2_02435_two_stage_problem_data.jl")
include("/Users/marloanzarut/Downloads/decisionmaking_under_uncertainty/V2_price_process.jl")

# Task 2: Make Policy
# Input = number_of_sim_periods, tau, current_stock, current_prices
# Output = Here-and-now decisions

function make_multistage_here_and_now_decision(num_sim_periods, tau, current_stock, current_prices)

    # Set initial prices 
    inital_price1 = 2
    inital_price2 = 5
    inital_price3 = 10
    initial_prices = [inital_price1, inital_price2, inital_price3]

    lookahead_days = tau
    initial_scenarios = 1000  #Adjust number if necessary

    # Make emmpty 3D array
    scenarios = zeros(num_sim_periods, length(current_prices), initial_scenarios)

    # Stage 1: prices are set to current_prices
    scenarios[1, :, :] .= reshape(current_prices, 1, length(current_prices))

    # Stage 2 until num_sim_periods
    for t in 2:num_sim_periods
        for s in 1:initial_scenarios
            # sample next prices
            price_samples = [[sample_next(prices_day_one[1]), sample_next(prices_day_one[1]), sample_next(prices_day_one[2])] for _ in num_sim_periods]
            
            #Assume a random variation of scenarios?? Im not sure about this
            scenarios[t, :, s] .= scenarios[t - 1, :, s] .* rand(0.8:0.01:1.2, length(current_prices))

        end
    end
    
    #Discretize scenarios
    discrete_scenarios = round.(scenarios, digits=2)


    # Create and populate non-anticipativty Make_Stochastic_here_and_now_decision




        
    






