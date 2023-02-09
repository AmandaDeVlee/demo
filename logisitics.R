
 
 
 rm(list=ls())
 require(deSolve)
 #----- The differential equations -----
 sir <- function(t, x, p) {
   with(as.list(c(x,p)),{
     
     dS <- birth-beta1*S*Z-delta1*S
     dZ <- beta1*S*Z + zeta1*R -alpha1*S*Z
     dR <- delta1*S + alpha1*S*Z -zeta1*R
     
     list(c(dS, dZ, dR))
   })
 }
 
 beta1 = .0095
 zeta1 = .0001
 alpha1 = .005
 delta1 = .0001
 birth = 0
 
 S_0 <- 500 # Initial conditions
 Z_0 <- 0 # initial conditions
 R_0 <- 0 # initial conditions
 
 times <- seq(0.0, 5.0, 0.01) # Time sequence
 parms <- c(zeta1=zeta1, beta1=beta1, alpha1=alpha1, delta1=delta1, birth=birth)
 
 xstart <- c(S=S_0, Z=Z_0, R= R_0) # Initial conditions
 my.atol <- c(1e-16,1e-16,1e-16); # Abs. accuracy - remember to add a term for each equation
 my.rtol <- 1e-12 # Rel. accuracy
 out <- as.data.frame(lsoda(xstart, times,
                            sir, parms, my.rtol, my.atol)) # Solve the eqns.
 #----- Plot the output -------
 plot(out$time, out$S, col="black", type="l", lwd=5,
      ylim=c(0,500), xlab="Time", ylab="Number")
 lines(out$time, out$Z, col="red", lwd=5)
 #lines(out$time, out$R, col="blue", lwd=5)
 grid(NULL, NULL, lty=1,lwd=1)