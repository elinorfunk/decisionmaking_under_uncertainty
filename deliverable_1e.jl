
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
nr_experiments = 1

# Generate nr_experiments number of random inital prices
inital_prices = [[rand(), rand(), rand()] for _ in 1:nr_experiments]

for price in inital_prices
    #Expected value decision ´
    EV_dec = Make_EV_here_and_now(price)
    cost_EV_1 = EV_dec[2]

    #Optimal in hindsight 
    stage_one_dec_OiH = optimal_in_hindsight(price)

    # Stochastic decision 
    values, cost_stoch1, expected_price = Make_Stochastic_here_and_now_decision(price, N1)

    # Revealed second stage price 
    second_stage_price = [sample_next(price[1]), sample_next(price[2]), sample_next(price[3])]

    # Solve a deterministic program to make the optimal stage-two decisions 
    stage_two_dec = optimal_in_hindsight(second_stage_price)

    cost_EV_2 = EV_stage_two_dec[2]

    # Record over all cost 
    cost_EV = cost_EV_1 + cost_EV_2
    cost_stochastic = cost_stoch1

    # Cost for OiH? 

end