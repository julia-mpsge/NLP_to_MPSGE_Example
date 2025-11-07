

parameters
    sigma /.2/,
    omega /.2/,
    BBAR /0/,
    PWE /1.0/,
    PWM /1.0/,
    TD  /0.0/,
    TE  /0.0/,
    TM  /0.0/,

    E0 /25/,
    DD0 /75/,
    DS0 /75/,
    M0 /25/,
    X0 /100/,
    Q0 /100/,
    PWE0 /1.0/,
    PWM0 /1.0/;



$ontext
$model:modelname

$sectors:
	X
    Q

$commodities:
	PFX
    PX
    PQ
    PDT

$consumer:
	Y

$prod:X t:omega
    o:PFX   q:(E0*PWE) p:(1/PWE) a:Y t:(-TE)
    o:PDT   q:(DS0)  
    i:PX    q:X0    

$prod:Q s:sigma
    o:PQ    q:Q0
    i:PFX   q:(M0*PWM) p:(1/PWM) a:Y t:(TM)
    i:PDT   q:(DD0)   a:Y t:(TD)
    

$demand:Y 
    d:PQ   q:Q0
    e:PX   q:X0
    e:PFX  q:BBAR
$offtext
$sysinclude mpsgeset modelname

PQ.fx = 1;

modelname.iterlim = 0
$include modelname.GEN
solve modelname using mcp;

sigma = .2;
omega = 15;
BBAR = 10;
PWE = 1.2;
PWM = 1.1;
TD = .5;
TE = .2;
TM = .1;



modelname.iterlim = 1000;
$include modelname.GEN
solve modelname using mcp;
