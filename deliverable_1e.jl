
# Evaluation and comparison 

"""evaluate the Expected-Value Program, the Optimal-in-Hindsight solution, 
and three versions of your Stochastic Program: one for N equals 5, one for N equals 20, and one for N equals 50
scenarios """

using Gurobi
using JuMP
using Printf
using Pkg

include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/deliverable_1b.jl")
include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/deliverable_1c.jl")
include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/deliverable_1d.jl")

N1 = 5
N2 = 20 
N3 = 50 
nr_experiments = 100

# Generate a list inital_prices of nr_experiments number of random inital prices
inital_prices = [[(rand() .* 10), (rand() .* 10), (rand() .* 10)] for _ in 1:nr_experiments]

costs_EV = []
costs_stochN1 = []
costs_stochN2 = []
costs_stochN3 = []
costs_OiH = []

for price in inital_prices
    #Expected value decision ´
    stage_one_dec_EV = Make_EV_here_and_now(price)

    #Optimal in hindsight 
    stage_one_dec_OiH, costOiH1 = optimal_in_hindsight(price)

    # Stochastic decision 
    stage_one_dec_stoch1, cost_stoch1_1, expected_price = Make_Stochastic_here_and_now_decision(price, N1)
    stage_one_dec_stoch2, cost_stoch1_2, expected_price = Make_Stochastic_here_and_now_decision(price, N2)
    stage_one_dec_stoch3, cost_stoch1_3, expected_price = Make_Stochastic_here_and_now_decision(price, N3)

    # Revealed second stage price 
    second_stage_price = [sample_next(price[1]), sample_next(price[2]), sample_next(price[3])]

    # Solve a deterministic program to make the optimal stage-two decisions 
    stage_two_dec_opt, costOiH2 = optimal_in_hindsight(second_stage_price)
    stage_two_dec_EV = Make_EV_here_and_now(second_stage_price)
    stage_two_dec_stoch1, cost_stoch2_1, expected_price = Make_Stochastic_here_and_now_decision(second_stage_price, N1)
    stage_two_dec_stoch2, cost_stoch2_2, expected_price = Make_Stochastic_here_and_now_decision(second_stage_price, N2)
    stage_two_dec_stoch3, cost_stoch2_3, expected_price = Make_Stochastic_here_and_now_decision(second_stage_price, N3)

    # Record over all cost 
    cost_EV_1 = stage_one_dec_EV[2]
    cost_EV_2 = stage_two_dec_EV[2]

    # Append results to lists
    push!(costs_EV, cost_EV_1 + cost_EV_2)
    push!(costs_stochN1, cost_stoch1_1 + cost_stoch2_1)
    push!(costs_stochN2, cost_stoch1_2 + cost_stoch2_2)
    push!(costs_stochN2, cost_stoch1_3 + cost_stoch2_3)
    push!(costs_OiH, costOiH1 + costOiH2)
    
end

println(f"EV: {costs_EV}")
println(f"{costs_stochN1}")
println(f"{costs_stochN2}")
println(f"{costs_stochN3}")
println(f"{costs_OiH}")
