"""
    MPSGE_model(data::ModelData)

Creates an MPSGEModel based on the provided `ModelData`. The numeraire is `PQ`, 
the consumer price index, which is fixed to 1.

# Parameters

- `sigma`: Elasticity of substitution
- `omega`: Elasticity of transformation
- `BBAR`: Balance of payments
- `PWE`: World export price
- `PWM`: World import price
- `TM`: Import tax rate
- `TE`: Export subsidy rate
- `TD`: Domestic tax rate

# Sectors

- `X`: Production sector
- `Q`: Consumption sector

# Commodities

- `PFX`: Nominal exchange rate
- `PX`: Producer price index
- `PQ`: Consumer price index
- `PDD`: Domestic price excluding taxes

# Consumers

- `Y`: Representative Agent

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
        sigma, .2, (description = "Elasticity of Substitution in Goods Sector")
        omega, .2, (description = "Elasticity of Transformation in Activity Sector")
        BBAR, 0.0, (description = "Trade Imbalance")

        PWE, 1, (description = "World Export Price Index")
        PWM, 1, (description = "World Import Price Index")
        TM, 0.0, (description = "Import Tariff Rate")
        TE, 0.0, (description = "Export Subsidy Rate")
        TD, 0.0, (description = "Domestic Tax Rate on Demand")
    end)

    @sectors(MP, begin
        X, (description = "Activity Sector")
        Q, (description = "Goods Sector")
    end)

    @commodities(MP, begin
        PFX, (description = "Nominal Exchange Rate")
        PX, (description = "Producer Price Index")
        PQ, (description = "Consumer Price Index")
        PDD, (description = "Domestic Good Price")
    end)

    @consumers(MP, begin
        Y, (description = "Representative Agent")
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