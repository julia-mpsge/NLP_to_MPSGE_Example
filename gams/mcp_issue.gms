*$if not set subexression $set subexpression no


parameters
    E0      "Initial Exports" /25/,
    M0      "Initial Imports" /25/,
    X0      "Produciton Possiblity" /100/,
    Q0      "Consumption possiblity" /100/,
    D0      "Initial value of domestic demand" /75/;


parameters sigma / .2 /, omega / .2 /, BBAR / 0.0 /, PWE / 1 /, PWM / 1 /, TM / 0.0 /, TE / 0.0 /, TD / 0.0 /;


positive variables  X, Q, PFX, PX, PQ, PDT, Y;
 X.L = 1; Q.L = 1; PFX.L = 1; PX.L = 1; PQ.L = 1; PDT.L = 1; Y.L = 100;

equations zp_X, zp_Q, mc_PFX, mc_PX, mc_PQ, mc_PDT, ib_Y;


$macro export_price (PFX*PWE*(1+TE))
$macro rev_X ((D0/(D0+E0)*(PDT)**(1+omega) + (E0)/(D0+E0)*export_price**(1+omega))**(1/(1+omega)))

$ifthen set subexpression

variables revenue_X, cost_X;
revenue_X.L = 1; cost_X.L = 1;

equations revenue_X_eq, cost_X_eq;
revenue_X_eq.. rev_X =e= revenue_X; cost_X_eq.. PX =e= cost_X;

$else

$macro revenue_X rev_X
$macro cost_X PX

$endif

zp_X.. cost_X =e= revenue_X;

* Compensated Demands for X
$macro cd_X_PFX  (E0*PWE * (revenue_X/export_price)**(-omega))
$macro cd_X_PDT  (D0 * (revenue_X/PDT)**(-omega))
$macro cd_X_PX  (X0)

$macro import_price  (PFX*PWM*(1 + TM))
$macro domestic_price  (PDT*(1+TD))

* Cobb-douglas could be an issue
$macro C_Q ((M0/(M0+D0)*import_price**(1-sigma) + D0/(M0+D0)*domestic_price**(1-sigma))**(1/(1-sigma)))

$ifthen set subexpression

variables revenue_Q, cost_Q;
revenue_Q.L = 1; cost_Q.L = 1;
 
equations revenue_Q_eq, cost_Q_eq;
revenue_Q_eq.. PQ =e= revenue_Q ; cost_Q_eq.. C_Q =e= cost_Q;

$else

$macro revenue_Q PQ
$macro cost_Q C_Q

$endif

* It ends here

zp_Q.. cost_Q =e= revenue_Q;

* Compensated Demands for Q
$macro cd_Q_PFX  (M0*PWM*(cost_Q/import_price)**(sigma))
$macro cd_Q_PDT  (D0*(cost_Q/domestic_price)**(sigma))
$macro cd_Q_PQ  (Q0)

* Market Clearance
mc_PX.. X0 =e= X*cd_X_PX;
mc_PQ.. Q*cd_Q_PQ =e= Y/PQ;
mc_PDT.. X*cd_X_PDT =e= Q*cd_Q_PDT;
mc_PFX.. X*cd_X_PFX + BBAR =e= Q*cd_Q_PFX;

* Income Balance
$macro tax_revenue (Q*cd_Q_PFX*TM*PFX + Q*cd_Q_PDT*TD*PDT-X*cd_X_PFX*TE*PFX)
ib_Y.. Y =e= PX*X0 + BBAR*PFX + tax_revenue;

PQ.fx = 1;


model MCPmodel / zp_X.X, zp_Q.Q, mc_PFX.PFX, mc_PX.PX, mc_PQ.PQ, mc_PDT.PDT, ib_Y.Y,
$ifthen set subexpression
    revenue_X_eq.revenue_X, cost_X_eq.cost_X, revenue_Q_eq.revenue_Q, cost_Q_eq.cost_Q
$endif
    /;


mcpmodel.iterlim = 0;
solve MCPmodel using MCP;

sigma = .2;
omega = 15;
BBAR = 10.0;
PWE = 1.2;
PWM = 1.1;
TD = 0.5;
TE = 0.2;
TM = 0.1;

mcpmodel.iterlim = 10000;
solve MCPmodel using MCP;

*parameter    alpha    Step length;
*set  homotopy /1*10/;
*loop(homotopy,
*    alpha = (homotopy.val-1)/(card(homotopy)-1);
*    omega = 1.5 * (1-alpha)  + 11 * alpha;
*    mcpmodel.iterlim = 10000;
*    solve MCPmodel using MCP;
*);

