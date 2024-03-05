
#  make_schocastic_here_and_now_decision = 
#  Function: makes a stochastic here-and-now decision by using a specified number 
#  of scenarios N for the second-stage prices.

# Input: prices at day one, 
# Output: (here-and-now) decisions at day one (by also reasoning about what is expected to happen in day two)

#  generate 1000 equally probable scenarios using sample next
#  (given the initial prices), reduce them to N representative ones with appropriate probabilities, and use those to
#  solve a 2-stage stochastic program.