rm(list=ls())
require(deSolve)
#----- The differential equations -----
sir <- function(t, x, p) {
  with(as.list(c(x,p)),{
    
    dS <- -beta*S*(I+A) - nu*S + w1*V + w2*R
    dE <- beta*S*(I+A) - e*E 
    dA <- mu1*e*E- nu*A - gamma1*A
    dI <- mu1*e*E - gamma2*I - phi*I  - delta1*I
    dH <- mu2*e*E + phi*I - gamma3*H - delta2*H
    dR <- gamma1*A + gamma2*I + gamma3*H - nu*R - w2*R
    dV <- nu*S + nu*A + nu*R - w1*v 
      
    
    list(c(dS, dE, dA, dI, dR, dV))
  })
}
beta = 0.00001
nu =  0.00001 #rate of vaccination, how many vaccines given in a day
w1 = 1/90 #waning rate if you are vaccinated, assuming immunity lasts for 90 days
w2 = 1/180 #assuming natural immunity lasts for 180 days 
e = 1/10 #10 days from exposure to infection 
mu1 = .25 # percent asymptomatic 15-60% from various sources
mu2 = 0.0002 #percent to hospital from cdc data from Sept 29, 2022
gamma1 =  1/9 # asymptomatic recovery, guessing same as mild case or less
gamma2 = 1/10 #sick for 7-14 days 
gamma3 = 1/50 #sick for 6 weeks or more
phi =  0.00004 #rate from mild to severe cases, guessing part of thospitalized rates from here
delta1 = 0.0
delta2 = 0.011/50 #caase fatality divided by a length of infection 


mu = 1/(75*365)
beta <- 0.1 # infection rate
gamma <- 0.1 # recovery rate

S_0 <- 500.0 # Initial conditions
I_0 <- 5.0 # initial conditions
R_0 <- 0.0 # initial conditions

times <- seq(0.0, 100.0, 0.1) # Time sequence
parms <- c(mu=mu, beta=beta, gamma=gamma)

xstart <- c(S=S_0, I=I_0, R= R_0) # Initial conditions
my.atol <- c(1e-16,1e-16,1e-16); # Abs. accuracy - remember to add a term for each equation
my.rtol <- 1e-12 # Rel. accuracy
out <- as.data.frame(lsoda(xstart, times,
                           sir, parms, my.rtol, my.atol)) # Solve the eqns.
#----- Plot the output -------
plot(out$time, out$I, col="black", type="l", lwd=5,
     ylim=c(0,500), xlab="Time", ylab="Number")
#lines(out$time, out$I, col="red", lwd=5)
#lines(out$time, out$R, col="blue", lwd=5)
grid(NULL, NULL, lty=1,lwd=1)

#N_star <- m/b
#print(N_star) # Print out equilibria values
#print((r/a)*(1-m/(b*K)))
