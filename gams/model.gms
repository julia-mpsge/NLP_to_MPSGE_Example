



parameters
    sigma  "Elasiticity of substitution"  /.2/,
    omega   "Elasticity of Transformation" /.2/,
    E0      "Initial Exports" /25/,
    M0      "Initial Imports" /25/,
    XBAR    "Produciton Possiblity" /100/,
    X0      "Initial value of XBAR" /100/,
    Q0      "Consumption possiblity" /100/,
    D0      "Initial value of domestic demand" /75/,
    BBAR    "Exogenous value of commercial balance" /0/,
    P0      "Initial consumer price index" /1/,
    PWE0    "Initial world export price" /1/,
    PWE     "World Export Price" /1/,
    PWM0    "Initial work import price" /1/,
    PWM     "World Import Price" /1/,
    PDD0    "Initial domestic price" /1/,

    rho     "Armington Exponent",
    h       "CET Exponent",
    alpha   "CET Proportion Parameter",
    beta    "Armmington proportion parameter",
    A       "CET dimension parameter",
    B       "Armington dimension parameter";


* Calibration

rho = (1/sigma) - 1;
h = (1/omega) + 1;
alpha = 1/ ( PDD0/PWE0 * (E0/D0)**(1/omega) +1);

beta = ((PWM0/PDD0)*(M0/D0)**(1/sigma))/((PWM0/PDD0)*(M0/D0)**(1/sigma)+1);
A = X0*(alpha*E0**h + (1-alpha)*D0**h)**(-1/h);
B = Q0*(beta*M0**(-rho) + (1-beta)*D0**(-rho))**(1/rho);


display rho, h, alpha, beta, A, B;


positive variables
    E       "Exports",
    DD      "Domestic Demand",
    DS      "Domestic Supply",
    M       "Imports",
    X       "Compound good?",
    PX      "Producer price index",
    PQ      "Consumer price index",
    PED     "Export price including subsidy",
    PMD     "Import price including duties",
    PDT     "Domestic Price including taxes",
    PDD     "Domestic Price excluding taxes",
    ER      "Nominal exchange rate",
    Y       "PNB";

FREE VARIABLES
    Q       "Consumption of the compound good",
    TM      "Customs duty rate",
    TE      "Export subsidy",
    TD      "Domestic tax",
    GR      "Government Revenue";


Equation
    OUTPUT  "Domestic Production",
    CONS    "Good consumption",
    EXPRAT  "Export-domestic supply ratio",
    IMPRAT  "Import-domestic ratio"
    EXCH    "Exchange rate",
    PEXP    "Export Price",
    PIMP    "Import Price",
    PDOM    "Domestic good price",
    PDTEQ   "Domestic price including all taxes",
    GREQ    "Budget Deficit",
    YEQ     "Definition of PNB",
    G       "Production constraint",
    D       "Domestic market balance",
    BOP     "Trade balance";


OUTPUT.. X =E= A * ((alpha*(E**h)) + ((1-alpha)*(DS**h)))**(1/h);
CONS.. Q =E= B*(((beta*(M**(-rho))) + ((1-beta)*(DD**(-rho))))**(-1/rho));
EXPRAT.. E =E= DS*((PED/PDD)*((1-alpha)/alpha))**omega;
IMPRAT.. M =E= DD*((PDT/PMD)*(beta/(1-beta)))**sigma;
EXCH.. PED =E= ER*PWE*(1+TE);
PEXP.. PX =E= (PED*E + PDD*DS)/X;
PIMP.. PMD =E= PWM*ER*(1+TM);
PDOM.. PDT*DD + PMD*M =E= PQ*Q;
PDTEQ.. PDT =E= (1+TD)*PDD;
GREQ.. GR =E= (TM*ER*PWM*M) + (TD*PDD*DD) - (TE*ER*PWE*E);
YEQ.. Y =E= (PX*X) + (ER*BBAR) + GR;
G.. X =E= XBAR;
D.. DD =E= DS;
BOP.. PWM*M - PWE*E =E= BBAR;

* Initial Conditions
DD.L = 75;
DS.L = 75;
M.L = 25;
E.L = 25;
X.L = 100;
Q.L = 100;
PED.L = 1.00;

Y.L = 100;
ER.L = 1;


PX.L = 1;
PQ.L = 1;
PED.L = 1;
PMD.L = 1;
PDT.L = 1;
PDD.L = 1;


TM.fx = 0;
TE.fx = 0;
TD.fx = 0;


PQ.fx = 1;

model GSS /ALL/;

solve GSS using NLP maximizing Q;

* Dutch Disease
$Title Dutch Disease Scenario
BBAR = 10;
PWE = 1.1;
PWM = 1.0;


solve GSS using NLP maximizing Q;


parameter report;

report('sigma') = sigma;
report('omega') = omega;
report('Q') = Q.l;
report('PD') = PDD.L;
report('TCR') = PED.L/PDD.L;
report('TCRE') = PED.L/PDD.L;
report('TCRM') = PMD.L/PDD.L;
report('TCERQ') = ER.L/PQ.L;
report('TCERX') = ER.L/PX.L;
report('TCN') = ER.L/PQ.L;
report('E') = E.L/PQ.L;
report('DD') = DD.L/PQ.L;
report('M') = M.L/PQ.L;

display report;