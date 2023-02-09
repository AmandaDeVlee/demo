rm(list=ls())
require(deSolve)
#----- The differential equations -----
pop <- function(t, x, p) {
  with(as.list(c(x,p)),{
    
    dN <- r*N
  
    list(c(dN))
  })
}
r = 1/(75*365)

N_0 <- 500.0 # Initial conditions

times <- seq(0.0, 100000.0, 0.1) # Time sequence
parms <- c(r=r)

xstart <- c(N=N_0) # Initial conditions
my.atol <- c(1e-16); # Abs. accuracy - remember to add a term for each equation
my.rtol <- 1e-12 # Rel. accuracy
out <- as.data.frame(lsoda(xstart, times,
                           pop, parms, my.rtol, my.atol)) # Solve the eqns.
#----- Plot the output -------
plot(out$time, out$N, col="black", type="l", lwd=5,
     xlab="Time", ylab="Number")

grid(NULL, NULL, lty=1,lwd=1)

