

rm(list=ls())
require(deSolve)
#----- The differential equations -----
sir <- function(t, x, p) {
  with(as.list(c(x,p)),{
    
  #Country 1
    
    dS_1 <- -S_1*(beta*(I_1+A_1)+m12*beta*(I_2+A_2)) - nu_1*S_1 + w1*V_1 + w2*R_1
    dE_1 <- S_1*(beta*(I_1+A_1)+m12*beta*(I_2+A_2)) - e*E_1
    dA_1 <- mu1*e*E_1 - nu_1*A_1 - gamma1*A_1
    dI_1 <- (1-mu1-mu2)*e*E_1 - gamma2*I_1 - phi*I_1  - delta1*I_1
    dH_1 <- mu2*e*E_1 + phi*I_1 - gamma3*H_1 - delta2*H_1
    dR_1 <- gamma1*A_1 + gamma2*I_1 + gamma3*H_1 - nu_1*R_1 - w2*R_1
    dV_1 <- nu_1*S_1 + nu_1*A_1 + nu_1*R_1 - w1*V_1
    
    #COuntry 2
    dS_2 <- -S_2*(beta*(I_2+A_2)+m12*beta*(I_1+A_1)) - nu_2*S_2 + w1*V_2 + w2*R_2
    dE_2 <- S_2*(beta*(I_2+A_2)+m21*beta*(I_1+A_1)) - e*E_2
    dA_2 <- mu1*e*E_2 - nu_2*A_2 - gamma1*A_2
    dI_2 <- (1-mu1-mu2)*e*E_2 - gamma2*I_2 - phi*I_2  - delta1*I_2
    dH_2 <- mu2*e*E_2 + phi*I_2 - gamma3*H_2 - delta2*H_2
    dR_2 <- gamma1*A_2 + gamma2*I_2 + gamma3*H_2 - nu_2*R_2 - w2*R_2
    dV_2 <- nu_2*S_2 + nu_2*A_2 + nu_2*R_2 - w1*V_2
    
    list(c(dS_1, dE_1, dA_1, dI_1, dH_1, dR_1, dV_1, 
           dS_2,dE_2, dA_2, dI_2,dH_2, dR_2,dV_2))
  })
}

beta = 0.00005
nu_1 = 0.0
nu_2 = 0.001
w1 = 1/90 # assuming vaccine immunity lasts for 90 days
w2 = 1/180 # assuming natural immunity lasts for 180 days
e = 1/10 # 10 days from exposure to infection
mu1 = 0.25 # percent asymptomatic 15-60% from various sources
mu2 = 0.0002 # percent to hospital from CDC data from Sept 29, 2022
gamma1 = 1/9 # guessing same as mild case or less
gamma2 = 1/10 # sick for 7-14 days
gamma3 = 1/50 # sick for 6 weeks or more
phi = 0.00004 # guessing part of hospitalized rates are from here
delta1 = 0.0
delta2 = 0.011/50 # case-fatality divided by length of infection
m12= 0.0
m21= 0.0


S_0 <- 5000.0 # Initial conditions
E_0 <- 0.0
A_0 <- 0.0
I_0 <- 5.0 # initial conditions
H_0 <- 0.0
R_0 <- 0.0 # initial conditions
V_0 <- 0.0

times <- seq(0.0, 1000.0, 0.1) # Time sequence
parms <- c(beta=beta,  nu_1=nu_1, nu_2=nu_2, w1=w1, w2=w2, e=e,
           mu1=mu1, mu2=mu2, gamma1=gamma1, gamma2=gamma2,
           gamma3=gamma3, phi=phi, delta1=delta1, delta2=delta2, m12=m12, m21=m21)

xstart <- c(S_1=S_0, E_1=E_0, A_1=A_0, I_1=I_0, H_1=H_0, R_1= R_0, V_1=V_0,
            S_2= S_0, E_2=E_0, A_2=A_0, I_2=I_0, H_2=H_0, R_2=R_0, V_2=V_0) # Initial conditions
my.atol <- c(1e-16,1e-16,1e-16,1e-16,1e-16,1e-16,1e-16,1e-16,1e-16,1e-16,1e-16,1e-16,1e-16,1e-16); # Abs. accuracy - remember to add a term for each equation
my.rtol <- 1e-12 # Rel. accuracy
out <- as.data.frame(lsoda(xstart, times,
                           sir, parms, my.rtol, my.atol)) # Solve the eqns.
#----- Plot the output -------
plot(out$time, out$I_1, col="black", type="l", lwd=5,
     xlab="Time", ylab="Number")
#ylim=c(0,5000), xlab="Time", ylab="Number")
#lines(out$time, out$I, col="red", lwd=5)
#lines(out$time, out$R, col="blue", lwd=5)
grid(NULL, NULL, lty=1,lwd=1)

#N_star <- m/b
#print(N_star) # Print out equilibria values
#print((r/a)*(1-m/(b*K)))

