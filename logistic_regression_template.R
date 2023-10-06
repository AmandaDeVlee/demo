####Logistic regression with mining

library(ggplot2)
library(MuMIn)
require(plyr)
require(stats)
require(scales)
require(dplyr)
require(grDevices)


#formula is glm(data=, dependent variable ~ independent variables)
#use + to separate independent variables, or * to also calculate interactions

Full.Logistic <- glm(data = completeData, Leech..1.0. ~ Length..cm. + Latitude.Sections
                     + YEAR + Season
                     + (Latitude.Sections * YEAR) + (YEAR * Length..cm.) +
                       (Length..cm. * Latitude.Sections)+
                       (YEAR *Season) + (Season*Latitude.Sections) + (Length..cm. * Season), family = binomial)

options(na.action="na.fail")

Models = dredge(Full.Logistic, rank="AIC", trace = 1)
options(na.action = "na.omit")

OR.summary <- function(x){
  # get the summary
  xs <- summary(x)
  # and the confidence intervals for the coefficients 
  ci = confint(x)
  # the table from the summary object
  coefTable <- coefficients(xs)
  # replace the Standard error / test statistic columns with the CI
  coefTable[,2:3] <- ci
  # rename appropriatly
  colnames(coefTable)[2:3] <- colnames(ci)
  # exponentiate the appropriate columns
  coefTable[,1:3] <- exp(coefTable[,1:3])
  # return the whole table....
  coefTable
  
}

Best.Logistic <- glm(data = completeData, Leech..1.0. ~ Length..cm. + YEAR, family = binomial)
coefTable(Dredged)[2]
OR.summary(Best.Logistic)
levels(completeData$YEAR)