"""
    NLP_model(data::ModelData)

Creates a JuMP model representing the NLP economic model based on the provided `ModelData`.

The numeraire is `PQ`, the consumer price index, which is fixed to 1.
"""
function NLP_model(data::ModelData)

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
    

    GSS = Model(Ipopt.Optimizer)

    @variables(GSS, begin
        sigma in JuMP.Parameter(.2) #Elasticity of substitution
        omega in JuMP.Parameter(.2) #Elasticity of Transformation
        BBAR in JuMP.Parameter(0)   #Exogenous value of commercial balance

        PWE in JuMP.Parameter(PWE0) #World Export Price
        PWM in JuMP.Parameter(PWM0) #World Import Price
        TM in JuMP.Parameter(0) # Customs duty rate
        TE in JuMP.Parameter(0) # Export subsidy
        TD in JuMP.Parameter(0) # Domestic tax
    end)

    @expressions(GSS, begin
        rho, (1/sigma) - 1
        h, (1/omega) + 1
        alpha, 1/ (PDD0/PWE0 * (E0/DS0)^(1/omega) +1)
        beta, ((PWM0/PDD0)*(M0/DD0)^(1/sigma))/((PWM0/PDD0)*(M0/DD0)^(1/sigma)+1)
        A, X0*(alpha*E0^h + (1-alpha)*DS0^h)^(-1/h)
        B, Q0*(beta*M0^(-rho) + (1-beta)*DD0^(-rho))^(1/rho)
    end)


    @variables(GSS, begin
        DD >= 0,     (start = DD0) # Domestic Demand
        DS >= 0,     (start = DS0) # Domestic Supply
        M >= 0,      (start = M0) # Imports
        E >= 0,      (start = E0) # Exports
        X >= 0,      (start = X0) # Compound good?
        Y >= 0,      (start = X0) # PNB
        PX >= 0,     (start = 1,) # Producer price index
        PQ >= 0,     (start = 1,) # Consumer price index
        PED >= 0,    (start = 1,) # Export price including subsidy
        PMD >= 0,    (start = 1,) # Import price including duties
        PDT >= 0,    (start = 1,) # Domestic Price including taxes
        PDD >= 0,    (start = 1,) # Domestic Price excluding taxes
        PFX >= 0,     (start = 1,) # Nominal exchange rate
        
        Q,      (start = 100) # Consumption of the compound good
        GR,     (start = 0) # Government Revenue
    end)



    @objective(GSS, Max, Q)

    @constraints(GSS, begin
        OUTPUT, X == A * ((alpha*(E^h)) + ((1-alpha)*(DS^h)))^(1/h);
        CONS, Q == B*(((beta*(M^(-rho))) + ((1-beta)*(DD^(-rho))))^(-1/rho));

        EXPRAT, E == DS*((PED/PDD)*((1-alpha)/alpha))^omega;
        IMPRAT, M == DD*((PDT/PMD)*(beta/(1-beta)))^sigma;

        PEXP, X*PX == (PED*E + PDD*DS);
        PDOM, PDT*DD + PMD*M == PQ*Q;

        EXCH, PED == PFX*PWE*(1+TE); 
        PIMP, PMD == PWM*PFX*(1+TM);
        
        PDTEQ, PDT == (1+TD)*PDD;

        GREQ, GR == (TM*PFX*PWM*M) + (TD*PDD*DD) - (TE*PFX*PWE*E);
        YEQ, Y == (PX*X) + (PFX*BBAR) + GR;
        G, X == X0;
        D, DD == DS;
        BOP, PWM*M - PWE*E == BBAR;
    end)

    fix(PQ, 1; force=true)

    return GSS
end

"""
    report(M::JuMP.Model)
    report(M::MPSGEModel)

Generates a report DataFrame summarizing key variables from the provided model `M`.

# Columns

- `sigma`: Elasticity of substitution
- `omega`: Elasticity of transformation
- `BBAR`: Balance of payments
- `PWM`: World import price
- `PWE`: World export price
- `TX`: Export subsidy
- `TM`: Import tax
- `TD`: Domestic tax
- `PED`: Export price including subsidy
- `PMD`: Import price including duties
- `Q`: Consumption of the compound good
- `PD`: Domestic price excluding taxes
- `TCR`: Real exchange rate
- `TCRE`: Real exchange rate for exports
- `TCRM`: Real exchange rate for imports
- `TCERQ`: Real effective echange rate for consumption
- `TCERX`: Real effective exchange rate for production
- `TCN`: Nominal exchange rate
- `E`: Exports
- `DD`: Domestic demand
- `M`: Imports
"""
function report(M::JuMP.Model)
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
        PED = value(M[:PED]),
        PMD = value(M[:PMD]),
        Q = value(M[:Q]),
        PD = value(M[:PDD]),
        TCR = value(M[:PED]/M[:PDD]),
        TCRE = value(M[:PED]/M[:PDD]),
        TCRM = value(M[:PMD]/M[:PDD]),
        TCERQ = value(M[:PFX]/M[:PQ]),
        TCERX = value(M[:PFX]/M[:PX]),
        TCN = value(M[:PFX]/M[:PQ]),
        E = value(M[:E]/M[:PQ]),
        DD = value(M[:DD]/M[:PQ]),
        M = value(M[:M]/M[:PQ]),
    )])
end

function set_parameter_values(M::JuMP.Model, params::ModelParameters)
    set_parameter_value(M[:BBAR], params.balance_of_payments)
    set_parameter_value(M[:sigma], params.elas_substitution)
    set_parameter_value(M[:omega], params.elas_transformation)
    set_parameter_value(M[:PWE], params.price_world_export)
    set_parameter_value(M[:PWM], params.price_world_import)
    set_parameter_value(M[:TM], params.tax_import)
    set_parameter_value(M[:TE], params.subsidy_export)
    set_parameter_value(M[:TD], params.tax_domestic)
end