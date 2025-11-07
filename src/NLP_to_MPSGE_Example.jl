module NLP_to_MPSGE_Example

    using JuMP
    using MPSGE
    using Ipopt
    using DataFrames
    using PATHSolver




    include("structs.jl")
    export ModelData, ModelParameters


    include("nlp.jl")
    export NLP_model, report, set_parameter_values

    include("mpsge.jl")
    export MPSGE_model

    include("mcp.jl")
    export MCP_model


end # module NLP_to_MPSGE_Example
