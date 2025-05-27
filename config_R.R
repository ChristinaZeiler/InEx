# config file that gets loaded in each of the R scripts of this analysis

#packages: 
#in case tidyverse is not installed, install it: 
if (!requireNamespace("tidyverse", quietly = TRUE)) {
  install.packages("tidyverse", dependencies = TRUE)
}

suppressPackageStartupMessages(library(tidyverse))


#variables: 
#path to your directory
dir<-"<your directory>" 
#for windows users: when copying path from windows explorer make sure to exchange \ in paths for /  

