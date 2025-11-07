# # Issues with PATHSolver

# While writing and debugging this model I found an issue that I think should be
# reported. The issue is that when using subexpressions in a PATHSolver MCP
# model, the solver fails to find a solution even when the same model without
# subexpressions solves fine. This issue also appears in MPSGE models, which
# use subexpressions by default.

using NLP_to_MPSGE_Example
using JuMP, MPSGE, DataFrames


# Initialize the data
data = ModelData()

# Initialize the models
nlp = NLP_model(data)
mcp = MCP_model(data)
mcp_sub = MCP_model(data; subexpressions = true)
mpsge = MPSGE_model(data)

# Notice that we have two versions of the MCP model, one with subexpressions
# and one without. This is going to demonstrate an issue with the PATHSolver
# when subexpressions are used. 

# Define a shock. Notice this is a fairly large shock, which is necessary to 
# demonstrate the issue.

params = ModelParameters(
    elas_substitution = .2, 
    elas_transformation = 15, 
    balance_of_payments = 10, 
    price_world_export = 1.2, 
    price_world_import = 1.1, 
    tax_domestic = .5, 
    subsidy_export = .2, 
    tax_import = .1
    );


set_parameter_values(nlp, params)
set_parameter_values(mcp, params)
set_parameter_values(mcp_sub, params)
set_parameter_values(mpsge, params)

# The NLP model solves fine.
optimize!(nlp)

# As does the MCP model without subexpressions.
optimize!(mcp)

# However, the MCP model with subexpressions fails to solve.
optimize!(mcp_sub)

# This MPSGE model uses subexpressions, so it also fails to solve.
solve!(mpsge)


# The issue appears to be related to the use of subexpressions in PATHSolver.
# Both the NLP and MCP models without subexpressions solve fine, while
# both models with subexpressions fail to solve.

# One way to solve this is to slowly approach the counterfactual by solving 
# the model multiple times with smaller shocks. This is known as "parameter
# homotopy" or "path-following". Below is an example of how to do this.

# The following is a function allowing us to set the value of `elas_transformation`
# without changing the other parameters.

transformation_shock(x) = ModelParameters(
    elas_substitution = .2, 
    elas_transformation = x, 
    balance_of_payments = 10, 
    price_world_export = 1.2, 
    price_world_import = 1.1, 
    tax_domestic = .5, 
    subsidy_export = .2, 
    tax_import = .1
    )

# We are going to solve the model many times, so it's a good idea to set it to silent mode.

set_silent(mpsge)

# Now we can loop over a range of values for `elas_transformation`,
# gradually increasing it to the target value.

for param in transformation_shock.(1:15)
    set_parameter_values(mpsge, param)
    solve!(mpsge)

    jm = jump_model(mpsge)
    set_start_value.(all_variables(jm), value.(all_variables(jm)))

    println("Omega=$(param.elas_transformation): Solved = $(is_solved_and_feasible(jm))")

end

# A couple of notes. First, the `all_variables` function is defined in MPSGE, but 
# it does not grab all the variables, just the ones that are explicitly defined. 
# By using first extracting the JuMP model using `jump_model`, we can use
# `all_variables` from JuMP, which grabs all variables including subexpressions.
# I plan to add a keyword to `all_variables` in MPSGE to allow this behavior
# directly in the future.

# Second, this approach may not always work. It depends on the model and the
# size of the shock. However, it is a useful technique to have in your toolbox
# when dealing with difficult-to-solve models.