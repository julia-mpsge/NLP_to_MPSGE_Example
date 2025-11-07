"""
    ModelData

Holds the initial data for the economic model.

# Fields

- `initial_exports::Float64`: Initial exports value.
- `initial_imports::Float64`: Initial imports value.
- `initial_production::Float64`: Initial production value.
- `initial_consumption::Float64`: Initial consumption value.
- `domestic_demand::Float64`: Domestic demand value.
- `domestic_supply::Float64`: Domestic supply value.
- `initial_consumer_price_index::Float64`: Initial consumer price index.
- `initial_world_import_price::Float64`: Initial world import price.
- `initial_world_export_price::Float64`: Initial world export price.
- `initial_domestic_price::Float64`: Initial domestic price.

# Default Values

- `initial_exports = 25.0`
- `initial_imports = 25.0`
- `initial_production = 100.0`
- `initial_consumption = 100.0`
- `domestic_demand = 75.0`
- `domestic_supply = 75.0`
- `initial_consumer_price_index = 1.0`
- `initial_world_import_price = 1.0`
- `initial_world_export_price = 1.0`
- `initial_domestic_price = 1.0`
"""
struct ModelData
    initial_exports::Float64
    initial_imports::Float64
    initial_production::Float64
    initial_consumption::Float64
    domestic_demand::Float64
    domestic_supply::Float64
    initial_consumer_price_index::Float64
    initial_world_import_price::Float64
    initial_world_export_price::Float64
    initial_domestic_price::Float64
    ModelData(; 
        initial_exports=25.0,
        initial_imports=25.0,
        initial_production=100.0,
        initial_consumption=100.0,
        domestic_demand=75.0,
        domestic_supply=75.0,
        initial_consumer_price_index=1.0,
        initial_world_import_price=1.0,
        initial_world_export_price=1.0,
        initial_domestic_price=1.0
    ) = new(
        initial_exports,
        initial_imports,
        initial_production,
        initial_consumption,
        domestic_demand,
        domestic_supply,
        initial_consumer_price_index,
        initial_world_import_price,
        initial_world_export_price,
        initial_domestic_price
    )
end


"""
    ModelParameters

Holds the parameters for the models.

# Fields

- `elas_substitution::Float64`: Elasticity of substitution.
- `elas_transformation::Float64`: Elasticity of transformation.
- `balance_of_payments::Float64`: Balance of payments.
- `price_world_export::Float64`: World export price.
- `price_world_import::Float64`: World import price.
- `tax_import::Float64`: Import tax.
- `subsidy_export::Float64`: Export subsidy.
- `tax_domestic::Float64`: Domestic tax.

# Default Values

- `elas_substitution = 0.2`
- `elas_transformation = 0.2`
- `balance_of_payments = 0.0`
- `price_world_export = 1.0`
- `price_world_import = 1.0`
- `tax_import = 0.0`
- `subsidy_export = 0.0`
- `tax_domestic = 0.0`
"""
struct ModelParameters
    elas_substitution::Float64
    elas_transformation::Float64
    balance_of_payments::Float64
    price_world_export::Float64
    price_world_import::Float64
    tax_import::Float64
    subsidy_export::Float64
    tax_domestic::Float64
    function ModelParameters(; 
        elas_substitution=0.2,
        elas_transformation=0.2,
        balance_of_payments=0.0,
        price_world_export=1.0,
        price_world_import=1.0,
        tax_import=0.0,
        subsidy_export=0.0,
        tax_domestic=0.0
    )
        return new(
            elas_substitution, 
            elas_transformation, 
            balance_of_payments, 
            price_world_export, 
            price_world_import, 
            tax_import, 
            subsidy_export, 
            tax_domestic
            )
    end
end