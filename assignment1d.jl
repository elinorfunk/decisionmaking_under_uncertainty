# Assingment 1d 

# Include files with other useful functions 
include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/assignment1b.jl")
include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/assignment1c.jl")
include("/Users/elino/Documents/Decision Making under Uncertainty/decisionmaking_under_uncertainty/assignment1d.jl")

# Generate n random nunbers for the inital price 
n = 100 
price_range = 1:10 

# Nr of scenarios 
N1 = 5
N2 = 20
N3 = 50 

function evaluation(price_range)
    random_price = rand(price_range) 
    # Call each program to make a here and now decision 
    # 
    return random_price
end 
