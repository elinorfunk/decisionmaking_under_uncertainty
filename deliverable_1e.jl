
# Evaluation and comparison 

"""evaluate the Expected-Value Program, the Optimal-in-Hindsight solution, 
and three versions of your Stochastic Program: one for N equals 5, one for N equals 20, and one for N equals 50
scenarios """

using Gurobi
using JuMP
using Printf
using Pkg

N1 = 5
N2 = 20 
N3 = 50 
nr_experiments = 100 

include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/deliverable_1b.jl")
include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/deliverable_1c.jl")
include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/deliverable_1d.jl")

# Generate nr_experiments number of random inital prices

inital_prices = rand(nr_experiments)

