### Pick Random Name ###

# This is some code to randomly pick a name from a list of names
# to draw a prize. 

library(tidyverse)
library(readxl)

# Create a list of names
# names <- c("Alice", "Bob", "Charlie", "Diana", "Eve")

survey <- read_excel("C:/Users/jeff.matheson/Downloads/Data Science Tools(1-27).xlsx")

# Randomly pick a name from the list

Winner <- survey |> 
  filter(!is.na(Name)) |> 
  group_by(Group) |> 
  slice_sample(n = 1) |> 
  select(Name)

view(Winner)
