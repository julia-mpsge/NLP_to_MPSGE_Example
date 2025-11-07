# Conversion Process


At it's core, MPSGE represents economic models using only prices and quantities. A standard MPSGE input block is structured as follows:
```julia
@input(P, Qref, nest, reference_price=rp, taxes = [Tax(consumer, tax_rate)])
```
where `reference_price` and `taxes` are optional, `P` is a commodity variable representing the price paid from the goods, `Qref` is the reference quantity and `nest` is the parent nest of the commodity. MPSGE uses this to build the tax-adjusted price, which in this example would be:
```math
\bar{P} = \frac{P(1+\text{tax\_rate})}{rp}
```
The reference price is typically used to negate a tax or subsidy on a good at the benchmark equilibrium, so that the benchmark price is 1. This is useful for calibration, as all prices will be unital at the benchmark. However, adjusting the price with the reference price also alters the reference quantity,
```math
\overline{Qref} = Qref \cdot rp
```
This ensures that the overall value of the transaction remains the same.

With this in mind, we can begin converting our NLP model to MPSGE. We are going to initially write the model ignoring taxes and price adjustments, and then add them in later. This will demonstrate the power and flexibility of MPSGE, you can easily add or remove taxes and price adjustments without needing to re-derive the entire model.


## Ignoring Parameters

First we define our model:
```julia
using MPSGE

mpsge = MPSGEModel()
```

Reading the description of the model, there are two `sectors`: the "Activity" account and "Goods" account. We will follow the convention of naming the activity account `X` and the goods account `Q`. Let's add these two:
```julia
@sectors(mpsge, begin
    X, (description = "Activity Sector")
    Q, (description = "Goods Sector")
end)
```

The NLP model has 7 prices:
* `PX` - Producer price index, can be viewed as the value added price
* `PQ` - Consumer price index, or the Armington composite price
* `PFX` - Exchange rate
* `PDD` - Domestic good price
* `PMD` - Import price including duties, $PMD = PFX\cdot PWM\cdot (1 + TM)$
* `PED` - Export price including subsidies, $PED = PFX\cdot PWE\cdot (1 + TE)$
* `PDT` - Domestic price including taxes, $PDT = PDD\cdot (1 + TD)$

Since 3 of these prices are actually tax-adjusted values, we are going to have 4 commodities in MPSGE: `PX`, `PQ`, `PFX`, and `PDD`. A commodity in MPSGE can be thought of as a price. Let's add the four commodities:
```julia
@commodities(mpsge, begin
    PX, (description = "Producer Price Index")
    PQ, (description = "Consumer Price Index")
    PFX, (description = "Exchange Rate")
    PDD, (description = "Domestic Good Price")
end)
```

The final variable is the consumer. Based on the model description and SAM, it appears there are three consumers: "Households", "Government", and "Rest of World". However, each of these is really just a different source of income for the single consumer in the model. Therefore, we will just add one consumer, `Y`:
```julia
@consumer(mpsge, Y, description = "Representative Agent")
```
This consumer will receive the tax revenue, endow the market with the initial production and the trade imbalance, and demand the consumed goods. We will discuss the consumer in more detail below. I will also note that we would typically call this consumer `RA` for "representative agent", but to keep consistent with the NLP model, we will call it `Y`.

### The `X` Sector

Let's start by determining the inputs and outputs of the `X` sector. The SAM is not structured to show inputs and outputs, it only shows inputs and we need to infer the appropriate output. 

From a high-level perspective, the `X` sector takes in goods and labor and produces goods that are demanded elsewhere. In this very simply model, `X` takes in no goods, only labor, with an initial value of $X_0 = 100$. The goods produced by `X` can either be exported or go into the domestic supply market. 

Here is the production block for `X`:
```julia
@production(mpsge, X, [t=1,s=0], begin
    @output(PFX, E0, t)
    @output(PDD, DS0, t)
    @input(PX, X0, s)
end)
```
Let's break this down. The `@production` macro takes four arguments:
1. The model, `mpsge`
2. The sector, `X`
3. A vector defining the nesting structure and elasticities. Here we just use `[t=1,s=0]` to indicate an elasticity of transformation of 1 and substitution of 0. This will get modified with a parameter later.
4. A block defining the inputs and outputs.

There is a `@input` with price `PX` and quantity `X0`, and two outputs with prices `PFX` and `PDD` and quantities `E0` and `DS0`. This is the exact structure we discussed and the quantities are as given in the NLP model description. 

The NLP model has the following constraint:
```math
X\cdot PX = (PED\cdot E + PDD\cdot DS)
```
This (almost) exactly matches the inputs and outputs we defined. The difference being a reference to `PED` instead of `PFX`. However, since we are ignoring taxes for now and the world export price, we can treat `PED` as `PFX`. This constraint indicates the activity of the `X` sector. 


### The `Q` Sector
The `Q` sector describes the flow of goods, the inputs are where the goods come from and the outputs are where the goods go. Similar to the previous discussion, 
we have a constraint that describes the flow of goods:
```math
PDT\cdot DD + PMD\cdot M = PQ\cdot Q
```
In words, goods come from domestic supply `DD` and imports `M`, and go to consumption `Q`. Ignoring taxes again, we can treat `PDT` as `PDD` and `PMD` as `PFX`. Therefore, we can define the production block for `Q` as:
```julia
@production(mpsge, Q, [t=0,s=1], begin
  @output(PQ, Q0, t)
  @input(PDD, DD0, s)
  @input(PFX, M0, s)
end)
```

### The `Y` Consumer
It may appear that we require new logic to define the consumer, but in reality we are still looking for inputs (final demands) and outputs (endowments). The sneaky way to do this is to find any inputs/outputs with no outputs/inputs, like `PX` and `PQ`. In this example, `PX` is only an input to the `X` sector, so it must be an endowment from the consumer. Similarly, `PQ` is only an output from the `Q` sector, so it must be a final demand from the consumer. Therefore, we can define the demand block as:
```julia
@demand(mpsge, Y, begin
   @final_demand(PQ, Q0)
   @endowment(PX, X0)
end)
```

### The "Final" Model

Putting this all together, we have the following MPSGE model:
```julia
using MPSGE

mpsge = MPSGEModel()

@sectors(mpsge, begin
    X, (description = "Activity Sector")
    Q, (description = "Goods Sector")
end)

@commodities(mpsge, begin
    PX, (description = "Producer Price Index")
    PQ, (description = "Consumer Price Index")
    PFX, (description = "Exchange Rate")
    PDD, (description = "Domestic Good Price")
end)

@consumer(mpsge, Y, description = "Representative Agent")

@production(mpsge, X, [t=1,s=0], begin
    @output(PFX, E0, t)
    @output(PDD, DS0, t)
    @input(PX, X0, s)
end)

@production(mpsge, Q, [t=0,s=1], begin
    @output(PQ, Q0, t)
    @input(PDD, DD0, s)
    @input(PFX, M0, s)
end)

@demand(mpsge, Y, begin
   @final_demand(PQ, Q0)
   @endowment(PX, X0)
end)
```

This is a great first step! This allows us to verify our data is balanced, if not we can easily identify where the problem arise. However, we can't do anything with this model, there are no parameters we can adjust. So let'd do that now. 

## Adding Parameters

We are going to use the same parameters as the NLP model. To add these, we use the `@parameters` macro to specify name and initial value:
```julia
@parameters(mpsge, begin
   sigma, .2, (description = "Elasticity of Substitution in Goods Sector")
   omega, .2, (description = "Elasticity of Transformation in Activity Sector")
   BBAR, 0.0, (description = "Trade Imbalance")

   PWE, 1, (description = "World Export Price Index")
   PWM, 1, (description = "World Import Price Index")
   TM, 0.0, (description = "Import Tariff Rate")
   TE, 0.0, (description = "Export Subsidy Rate")
   TD, 0.0, (description = "Domestic Tax Rate on Demand")
end)
```

### Adding Domestic Taxes

The domestic tax rate `TD` is going to apply to the domestic good price `PDD` in the `Q` sector. There are many ways to see this, but the easiest is to look at the original constraint:
```math
PDT\cdot DD + PMD\cdot M = PQ\cdot Q
```
Notice the `PDT` term, this is the domestic price including taxes. To add this tax, change the input  We do this by adding a tax to the commodity in the production block:
```julia
@input(PDD, DD0, s, taxes = [Tax(Y, TD)])
```
The `Tax` function takes two arguments, the consumer receiving the tax revenue and the tax rate. This is all we need to do to add a tax rate. MPSGE will handle the rest. If the value of `TD` were not zero initially, we would add a reference price to adjust the benchmark price to 1, the reference price would be `(1+TD0)`, or the tax-adjustment, where `TD0` is the initial value of `TD`.

### Adding World Import Price Adjustment

Let's start by looking at the original constraint defining the post-tax import price:
```math
PMD = PFX\cdot PWM\cdot (1 + TM)
```
The inclusion of `PWM` is new. The current way to implement this in MPSGE is to use a reference price and adjust the quantity to cancel the effect of the reference price on the value of the transaction. Therefore, will adjust the `@input` for the `PFX` commodity in the `Q` sector production block by adding 
1. A reference price of `1/PWM`
2. A quantity adjustment of `M0*PWM`
3. A tax for the import tariff `TM`
```julia
@input(PFX, M0*PWM, s, reference_price = 1/PWM, taxes = [Tax(Y, TM)])
```
I plan to add an externality keyword to the `@input` and `@output` macros to handle price adjustments like this without modifying the reference quantity, but for now this is the way to do it.

### Adding World Export Price Adjustment

This is identical to the import price adjustment, with one big difference: the tax is a subsidy, which means it is negative. Therefore, we add the following to the `@output` for `PFX` in the `X` sector production block:
```julia
@output(PFX, E0*PWE, t, reference_price = 1/PWE, taxes = [Tax(Y, -TE)])
```

### Adding Trade Imbalance
The trade imbalance `BBAR` is added as an endowment to the consumer for the export good and a final demand from the consumer for the import good. Therefore, we add an endowment to the demand block:
```julia
@endowment(PFX, BBAR)
```

### The Final Model
```julia
using MPSGE

X0 = 100
Q0 = 100

DD0 = 75
DS0 = 75

E0 = 25
M0 = 25

mpsge = MPSGEModel()

@parameters(mpsge, begin
    sigma, .2
    omega, .2
    BBAR, 0.0
    PWE, 1
    PWM, 1
    TM, 0.0
    TE, 0.0
    TD, 0.0
end)

@sectors(mpsge, begin
    X, (description = "Activity Sector")
    Q, (description = "Goods Sector")
end)

@commodities(mpsge, begin
    PX, (description = "Producer Price Index")
    PQ, (description = "Consumer Price Index")
    PFX, (description = "Exchange Rate")
    PDD, (description = "Domestic Good Price")
end)

@consumer(mpsge, Y, description = "Representative Agent")

@production(mpsge, X, [t=omega,s=0], begin
    @output(PFX, E0*PWE, t, reference_price = 1/PWE, taxes = [Tax(Y, -TE)]) 
    @output(PDD, DS0, t)
    @input(PX, X0, s)
end)

@production(mpsge, Q, [t=0,s=sigma], begin
    @output(PQ, Q0, t)
    @input(PFX, M0*PWM, s, reference_price = 1/PWM, taxes = [Tax(Y, TM)])
    @input(PDD, DD0, s, taxes = [Tax(Y, TD)])
    
end)

@demand(mpsge, Y, begin
    @final_demand(PQ, Q0)
    @endowment(PX, X0)
    @endowment(PFX, BBAR)
end)
```


## Final Thoughts

This model is now functionally equivalent to the NLP model described earlier. You can adjust the parameters and solve the model to see how the economy responds. 

In the NLP formulation, there was much effort to carefully define the tax structure and prices. With MPSGE, we can easily add taxes without needing to update the model structure. This makes MPSGE a powerful tool for economic modeling, allowing for rapid experimentation and analysis of different policy scenarios. 

MPSGE also reduces the potential for typos in the model formulation. For example, it would be easy to type variable of `DD` as `DS`. `DD` is used 5 times in the NLP model. In MPSGE, we don't need to define `DD` at all. It is implicit in the production block for `Q`. This is demonstrated when the models are compared in the next section.