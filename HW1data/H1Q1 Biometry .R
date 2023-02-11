 Monogamous <- c(11400, 9500, 9900, 9100, 9200, 11900, 10100, 8900, 12800)
 Promiscuous <- c(5200, 9400, 8400, 8100, 10200, 7000, 9100, 10600, 8700)
# Create a data frame
 my_data <- data.frame( 
      group = rep(c("Monogamous", "Promiscuous"), each = 9),
     White_Blood_Cell = c(Monogamous,  Promiscuous)
    )
   
     print(my_data)

   
     group_by(my_data, group) %>%
         summarise(
               count = n(),
               mean = mean( White_Blood_Cell, na.rm = TRUE),
               sd = sd( White_Blood_Cell, na.rm = TRUE)
           )


   
   # Plot weight by group and color by group
   ggboxplot(my_data, x = "group", y = "White_Blood_Cell", 
                           color = "group", palette = c("#00AFBB", "#E7B800"),
                       ylab = "White Blood Cell Count (cells/liter)", xlab = "Groups")
   
   
   # Compute t-test
   res <- t.test(Monogamous, Promiscuous, var.equal = TRUE)
   res
   