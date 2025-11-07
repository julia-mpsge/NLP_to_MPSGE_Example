using NLP_to_MPSGE_Example
using JuMP, MPSGE, DataFrames



############################
## Part 1: Initialization ##
############################

# Initialize the data
data = ModelData()

# Initialize the models
nlp = NLP_model(data)
mpsge = MPSGE_model(data)

# Verify the model by solving the baseline scenario
optimize!(nlp)
solve!(mpsge; cumulative_iteration_limit=0)



#################################
## Part 2: Comparing Solutions ##
#################################

# The NLP version of the model has more variables the MPSGE version, however, the
# solutions to both are the same. 


# Set parameter values for a counterfactual
params = ModelParameters(
    balance_of_payments = 10.0, 
    elas_substitution = 0.5, 
    elas_transformation = 0.5, 
    tax_domestic = .1, 
    tax_import = .2,
    price_world_export = 1.1,
    price_world_import = 1.2,
    subsidy_export = 0.05,
    )

set_parameter_values(nlp, params)
set_parameter_values(mpsge, params)

optimize!(nlp)
solve!(mpsge)


# This is a method to view all the variable values in a DataFrame.
# Let's use this to compare the two models. Note that I've used some fancy operations,
# I've tried to space things out for clarity, you can extract each piece and run
# it separately to understand what is happening.
outerjoin(
    
    zip(JuMP.name.(all_variables(nlp)), value.(all_variables(nlp))) |> 
        x -> DataFrame(var = first.(x), nlp = last.(x)),
    
    generate_report(mpsge) |>
        x -> transform(x, :var => ByRow(y -> JuMP.name(y)) => :var) |>
        x -> select(x, :var, :value => :mpsge),
    
    on = :var,
)


# The variables present in the MPSGE model can be directly compared to the NLP model.
# However, neither `X` nor `Q` match. This is because in MPSGE, these are activity levels
# that produce quantities of goods, whereas in the NLP model, these are quantities
# of goods themselves. Let's focus on `X` as `Q` is similar. 
#
# Look at the MPSGE model and search for any productions that use `X0`. That would be the `X` block

production(mpsge[:X])

# Or, in the code: 
#
#    @production(MP, X, [t=omega,s=0], begin
#        @output(PFX, E0*PWE, t, reference_price = 1/PWE, taxes = [Tax(Y, -TE)]) # Negative tax for export subsidy
#        @output(PDD, DS0, t)
#        @input(PX, X0, s)
#    end)
#
# `PX` is the commodity associated with `X0`, so to get `X` we compute the compensated
# demand for `X` with respect to `PX`, and scale it by the activity level of `X`:

X = value(compensated_demand(mpsge[:X], mpsge[:PX])*mpsge[:X])
Q = value(compensated_demand(mpsge[:Q], mpsge[:PQ])*mpsge[:Q])

# The `-` on `Q` is signifying that the value comes from an output. 


# Next up, parameters. MPSGE does not report the parameter values. We can display these using:

parameters(mpsge)
value.(parameters(mpsge))

# The above displays two vectors. It would be a good exercise to put these in a 
# DataFrame, and `vcat` it to the previous mpsge dataframe.

# Next, the four quantities, `DD`, `DS`, `E`, and `M`. The idea is identical to 
# `X` and `Q`. The exception is for `E` and `M`, which require scaling by the world prices.

DD = value(compensated_demand(mpsge[:Q], mpsge[:PDD])*mpsge[:Q])
DS = value(compensated_demand(mpsge[:X], mpsge[:PDD])*mpsge[:X])
E = value(compensated_demand(mpsge[:X], mpsge[:PFX])*mpsge[:X]/mpsge[:PWE])
M = value(compensated_demand(mpsge[:Q], mpsge[:PFX])*mpsge[:Q]/mpsge[:PWM])

# The `GR` variable in the NLP model corresponds to the tax revenues in MPSGE. 
# There should be a better function for this, but for now we can compute it as:

value(MPSGE.tax_revenue(mpsge[:X], mpsge[:Y]; virtual = true)) + 
value(MPSGE.tax_revenue(mpsge[:Q], mpsge[:Y]; virtual = true))

# Finally, the three prices. I am first going to demonstrate a method to extract
# the price directly from the MPSGE model, then show how to compute them manually.
# This should be a function in MPSGE, I will work on it for a future release.

P = production(mpsge[:Q])
O = input(P)
N = O.children[2]
CF = cost_function(N)
PDT = value(CF)

# Manually:

PDT = value(mpsge[:PDD]*(1 + mpsge[:TD]))
PMD = value(mpsge[:PFX]*(1 + mpsge[:TM])*mpsge[:PWM])
PED = value(mpsge[:PFX]*(1 + mpsge[:TE])*mpsge[:PWE])



###############################
## Part 3: Recreating Tables ##
###############################

# In this part we will recreate tables `5.4` and `5.5` from the reference paper.
# These tables are on pages 42 (45 of document) and 45 (48 of document). These tables
# show the effects of changing the elasticity parameters and balance of payments
# on key variables in the model.

shocks = [
    ModelParameters(balance_of_payments = 0,    elas_substitution = 0.2, elas_transformation = 0.2,),
    ModelParameters(balance_of_payments = 10.0, elas_substitution = 0.2, elas_transformation = 0.2,),
    ModelParameters(balance_of_payments = 10.0, elas_substitution = 0.5, elas_transformation = 0.5,),
    ModelParameters(balance_of_payments = 10.0, elas_substitution = 2,   elas_transformation = 2,  ),
    ModelParameters(balance_of_payments = 10.0, elas_substitution = 5,   elas_transformation = 5,  ),
    ModelParameters(balance_of_payments = 10.0, elas_substitution = 15,  elas_transformation = .2, ),
    ModelParameters(balance_of_payments = 10.0, elas_substitution = .2,  elas_transformation = 15, ),

    ModelParameters(price_world_import = 1.1, elas_substitution = 0.2, elas_transformation = 0.2,),
    ModelParameters(price_world_import = 1.1, elas_substitution = 0.5, elas_transformation = 0.5,),
    ModelParameters(price_world_import = 1.1, elas_substitution = 2,   elas_transformation = 2,  ),
    ModelParameters(price_world_import = 1.1, elas_substitution = 5,   elas_transformation = 5,  ),
    ModelParameters(price_world_import = 1.1, elas_substitution = 15,  elas_transformation = .2, ),
    ModelParameters(price_world_import = 1.1, elas_substitution = .2,  elas_transformation = 15, ),
];

# We will also set the models to silent mode to avoid cluttering the output
set_silent(nlp)
set_silent(mpsge)

# To run the shocks and collect the results, we do two steps:
# 
#   1. Create empty DataFrames to hold the results
#   2. Loop through each shock, set the parameters, solve the models,
#      generate the reports, and append them to the results DataFrames.
#
# However, this requires the DataFrame be empty at the start of each loop. 

nlp_results = DataFrame();
mpsge_results = DataFrame();
for shock in shocks
    set_parameter_values(nlp, shock)
    set_parameter_values(mpsge, shock)

    optimize!(nlp)
    solve!(mpsge)

    nlp_report = report(nlp)
    mpsge_report = report(mpsge)

    nlp_results = vcat(nlp_results, nlp_report)
    mpsge_results = vcat(mpsge_results, mpsge_report)
end


# The table results can be viewed by simply typing the DataFrame name.
nlp_results

# MPSGE results
mpsge_results

# Are these the same? Substract and round:
round.(nlp_results .- mpsge_results, digits=6)

# What do the columns in the report mean? Check the doc string for `report`. You 
# can do this either by entering the help mode in the REPL, just type `?` in the REPL
# to switch to help mode and type `report`, or by using the `@doc` macro:

@doc report

## Part 4: Issues

