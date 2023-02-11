
#normal temp
 normal <- c(310, 240,260,220, 160, 170, 300, 180, 210, 80, 190, 270, 130, 190, 190, 120,180,315,260,285,250,150,150,290,120,210,120,240,275,160,210,200,160,160)
 elevated <- c(110,120,160,80,150,110,260,240,190,130,150,300,160,300,280,190,100,60,140,160,120,170,90,120,220, 210,150,160,330,100,235,190,170,95)
 
 #create a data frame
 
 my_data <- data.frame(
   group = rep(c("normal","elevated"), each = 34),
   temp = c(normal,elevated)
   
 )
 
 # Print all data
 print(my_data)
 
 library("dplyr")
 group_by(my_data, group) %>%
   summarise(
     count = n(),
     mean = mean(temp, na.rm = TRUE),
     sd = sd(temp, na.rm = TRUE)
     
   )
 

 

 # Subset weight data before treatment
 normal <- subset(my_data,  group == "normal", temp,
                  drop = TRUE)
 # subset weight data after treatment
 elevated <- subset(my_data,  group == "elevated", temp,
                 drop = TRUE)
 # Plot paired data
 library(PairedData)
 pd <- paired(normal, elevated)
 plot(pd, type = "profile") + theme_bw()
 ylab= "Number of Beetles Hatched"
 
 
 # Compute t-test
 res <- t.test(normal, elevated, paired = TRUE)
 res