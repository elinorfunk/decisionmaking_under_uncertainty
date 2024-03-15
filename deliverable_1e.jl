
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
    push!(costs_stochN3, cost_stoch1_3 + cost_stoch2_3)
    push!(costs_OiH, costOiH1 + costOiH2)
    
end

# println("EV: $costs_EV")
# println("Stoch $N1 $costs_stochN1")
# println("Stoch $N2 $costs_stochN2")
# println("Stoch $N3 $costs_stochN3")
# println("OiH $costs_OiH")


using CSV
using Statistics
using Plots

# Save data in Excel sheet 
results_df = DataFrame(
    "Expected Value" => costs_EV,
    "Stochastic $N1 scenarios" => costs_stochN1,
    "Stochastic $N2 scenarios" => costs_stochN2,
    "Stochastic $N3 scenarios" => costs_stochN3,
    "OiH" => costs_OiH)

CSV.write("deliverable1e_results.csv", results_df)


# Calculate mean, min, and max values, and plot 
mean_EV = mean(costs_EV)
min_EV = minimum(costs_EV)
max_EV = maximum(costs_EV)

mean_stochN1 = mean(costs_stochN1)
min_stochN1 = minimum(costs_stochN1)
max_stochN1 = maximum(costs_stochN1)

mean_stochN2 = mean(costs_stochN2)
min_stochN2 = minimum(costs_stochN2)
max_stochN2 = maximum(costs_stochN2)

mean_stochN3 = mean(costs_stochN3)
min_stochN3 = minimum(costs_stochN3)
max_stochN3 = maximum(costs_stochN3)

mean_OiH = mean(costs_OiH)
min_OiH = minimum(costs_OiH)
max_OiH = maximum(costs_OiH)

println("Mean, Min, and Max values for Expected Value:")
println("Mean: $mean_EV, Min: $min_EV, Max: $max_EV")

println("Mean, Min, and Max values for Stochstic optimization $N1:")
println("Mean: $mean_stochN1, Min: $min_stochN1, Max: $max_stochN1")

println("Mean, Min, and Max values for Stochstic optimization $N2:")
println("Mean: $mean_stochN2, Min: $min_stochN2, Max: $max_stochN2")

println("Mean, Min, and Max values for Stochstic optimization $N3:")
println("Mean: $mean_stochN3, Min: $min_stochN3, Max: $max_stochN3")

println("Mean, Min, and Max values for Optimal in Hindsight optimization:")
println("Mean: $mean_OiH, Min: $min_OiH, Max: $max_OiH")

results_plot = plot([costs_EV, costs_stochN1, costs_stochN2, costs_stochN3, costs_OiH],
     label=["Expected Value" "Stochastic Program, $N1 sc." "Stochastic Program, $N2 sc." "Stochastic Program, $N3 sc." "OiH solution"],
     xlabel="Index", ylabel="Value", title="Costs for the different Programs/Solutions",
     marker=:circle)
hline!([mean_EV], label="Mean Expected Value", color=:blue)
hline!([mean_stochN1], label="Mean Stochastic Program, $N1 sc", color=:green)
hline!([mean_stochN2], label="Mean Stochastic Program, $N2 sc", color=:red)
hline!([mean_stochN3], label="Mean Stochastic Program, $N3 sc", color=:purple)
hline!([mean_OiH], label="Mean OiH", color=:orange)
legendfont=font(3)

display(results_plot)
savefig("results_1e.png")