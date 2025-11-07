"""
    MPSGE_model(data::ModelData)

Creates an MPSGEModel based on the provided `ModelData`. The numeraire is `PQ`, 
the consumer price index, which is fixed to 1.
"""
function MPSGE_model(data::ModelData)

    E0 = data.initial_exports
    M0 = data.initial_imports
    X0 = data.initial_production
    Q0 = data.initial_consumption
    DD0 = data.domestic_demand
    DS0 = data.domestic_supply
    P0 = data.initial_consumer_price_index
    PDD0 = data.initial_domestic_price
    PWE0 = data.initial_world_export_price
    PWM0 = data.initial_world_import_price

    MP = MPSGEModel()

    @parameters(MP, begin
        sigma, .2
        omega, .2
        BBAR, 0.0

        PWE, PWE0
        PWM, PWM0
        TM, 0.0
        TE, 0.0
        TD, 0.0
    end)

    @sectors(MP, begin
        X
        Q
    end)

    @commodities(MP, begin
        PFX
        PX
        PQ
        PDD
    end)

    @consumers(MP, begin
        #world
        Y
    end)


    @production(MP, X, [t=omega,s=0], begin
        @output(PFX, E0*PWE, t, reference_price = 1/PWE, taxes = [Tax(Y, -TE)]) # Negative tax for export subsidy
        @output(PDD, DS0, t)
        @input(PX, X0, s)
    end)


    @production(MP, Q, [t=0,s=sigma], begin
        @output(PQ, Q0, t)
        @input(PFX, M0*PWM, s, reference_price = 1/PWM, taxes = [Tax(Y, TM)])
        @input(PDD, DD0, s, taxes = [Tax(Y, TD)])
        
    end)

    @demand(MP, Y, begin
        @final_demand(PQ, Q0)
        @endowment(PX, X0)
        @endowment(PFX, BBAR)
    end)

    fix(PQ, 1)

    return MP
end


function set_parameter_values(M::MPSGEModel, params::ModelParameters)
    set_value!(M[:sigma], params.elas_substitution)
    set_value!(M[:omega], params.elas_transformation)
    set_value!(M[:BBAR], params.balance_of_payments)
    set_value!(M[:PWE], params.price_world_export)
    set_value!(M[:PWM], params.price_world_import)
    set_value!(M[:TM], params.tax_import)
    set_value!(M[:TE], params.subsidy_export)
    set_value!(M[:TD], params.tax_domestic)

    return
end


function report(M::MPSGEModel)

    PDD = value(M[:PDD])#*(1 - M[:TD]))
    DD = value(compensated_demand(M[:Q], M[:PDD];virtual=true)*M[:Q]/M[:PQ])


    PED = value(M[:PFX]*(1 + M[:TE])*M[:PWE])
    PMD = value(M[:PFX]*(1 + M[:TM])*M[:PWM])

    E = -value(compensated_demand(M[:X], M[:PFX];virtual=true)*M[:X]/(M[:PQ]*M[:PWE]))
    imp = value(compensated_demand(M[:Q], M[:PFX];virtual=true)*M[:Q]/(M[:PQ]*M[:PWM]))


    return DataFrame([
    (
        sigma = value(M[:sigma]),
        omega = value(M[:omega]),
        BBAR = value(M[:BBAR]),
        PWM = value(M[:PWM]),
        PWE = value(M[:PWE]),
        TX = value(M[:TE]),
        TM = value(M[:TM]),
        TD = value(M[:TD]),
        PED = PED,
        PMD = PMD,
        Q = -value(compensated_demand(M[:Q], M[:PQ])*M[:Q]),
        PD = PDD,
        TCR =  PED/PDD,
        TCRE = PED/PDD,
        TCRM = PMD/PDD,
        TCERQ = value(M[:PFX]/M[:PQ]),
        TCERX = value(M[:PFX]/M[:PX]),
        TCN = value(M[:PFX]/M[:PQ]),
        E = E,
        DD = DD,
        M = imp,
    )])
end