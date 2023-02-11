rm(list=ls())
require(deSolve)
#----- The differential equations -----
sir <- function(t, x, p) {
  with(as.list(c(x,p)),{
    #dN <- r*N-a*N*P
    # Classic Lotka-Volterra with exponential growth
    
    # dN <- r*N*(1-N/K)-a*N*P
    # a*N*P - Holling Type I functional response
    
    #dN <- r*N*(1-N/K)- P*(a*N/(1+a*tau*N))
    # a*N/(1+a*tau*N) - Holling Type II 
    
    dN <- r*N*(1-N/K)- P*(a*N^2/(1+a*tau*N^2))
    # a*N^2/(1+a*tau*N^2) - Holling Type III 
    
    dP <- b*N*P - m*P
    list(c(dN, dP))
  })
}
#----- The main program -------
r <- 0.2 # prey growth rate
a <- 0.01 # prey consumption
b <- 0.001 # conversion to predator
m <- 0.05 # predator death rate
K <- 1000.0 # prey carrying capacity
tau <- 0.5

N0 <- 75.0 # Initial conditions
P0 <- 10.0
times <- seq(0.0, 1000.0, 0.1) # Time sequence
parms <- c(r=r, a=a, b=b, m=m, K=K, tau=tau) # Parameter vector
xstart <- c(N=N0, P=P0) # Initial conditions
my.atol <- c(1e-16,1e-16); # Abs. accuracy
my.rtol <- 1e-12 # Rel. accuracy
out <- as.data.frame(lsoda(xstart, times,
                           sir, parms, my.rtol, my.atol)) # Solve the eqns.
#----- Plot the output -------
plot(out$P, out$N, col="black", type="l", lwd=5,
     ylim=c(0,400), xlab="Predator", ylab="Prey")
#lines(out$time, out$P, col="red", lwd=5)
grid(NULL, NULL, lty=1,lwd=1)

plot(out$time, out$N, col="black", type="l", lwd=5,
     ylim=c(0,400), xlab="Time", ylab="Number")
lines(out$time, out$P, col="red", lwd=5)
grid(NULL, NULL, lty=1,lwd=1)

#N_star <- m/b
#print(N_star) # Print out equilibria values
#print((r/a)*(1-m/(b*K)))

