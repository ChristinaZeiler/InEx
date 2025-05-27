#load necessary packages
source("config_R.R")
subdir<-paste(dir, "/norm.counts_InEx", sep="")

#import intermediate files
setwd(paste(dir, "/norm.counts_InEx", sep=""))
data.TPM.cutoff<-list(read.csv("11_TPM.exon.csv",row.names = 1),
                      read.csv("11_TPM.intron.csv",row.names = 1))
names(data.TPM.cutoff)<-c("exon","intron")
enriched.genes<-read.csv(file="15_enriched.genes.list.csv")$x


#Step 20
# calculate the InEx for enriched genes
InEx<-merge(data.TPM.cutoff[["intron"]], 
                    data.TPM.cutoff[["exon"]],
                    by="row.names", suffixes=c("_intron","_exon"))%>%
   subset(Row.names %in% enriched.genes)%>% #filtering for enriched genes
   select(-c(starts_with("mean")))%>%
   pivot_longer(-Row.names, names_to = "sample", values_to = "TPM")%>%
  mutate( # this could be substituted by separate() if sample naming follows a pattern such as Input/PD_replicate_intron/exon
    "condition"=case_when( #extracting Input/PD
      grepl("Input",sample)~"Input",
      grepl("PD",sample)~"PD",
      T~"inconsistent Input/PD naming!"),
    "intron.exon"=case_when( #extracting intron/exon
      grepl("intron",sample)~"intron",
      grepl("exon",sample)~"exon",
      T~"inconsistent intron/exon naming!"),
    "replicate"=str_remove(sample, "^(Input|PD)_")%>%str_remove("_(intron|exon)$") 
    #extracting replicate (rest when removing Input/PD and intron/exon)
    )%>%
  pivot_wider(id_cols = c(Row.names, condition, replicate),names_from = intron.exon,values_from = TPM,names_glue = "TPM_{intron.exon}")%>%
  mutate("InEx"=TPM_intron/TPM_exon)%>%
  select(-c(TPM_intron,TPM_exon))%>%
  pivot_wider(id_cols = c(Row.names, condition),names_from = replicate,values_from = InEx,names_glue = "InEx_{replicate}")%>%
  rowwise()%>%
  mutate(mean_InEx=mean(c_across(starts_with("InEx"))))%>%
  ungroup()

write.csv(InEx, row.names = F, file="16_InEx.csv")  
  
#check: for 5 random genes, display the TPM values and the InEx, manually calculate and check InEx
#get 5 random genes:
# genestocheck<-sample(InEx$Row.names, min(5, length(InEx$Row.names)))
# InEx%>%filter(Row.names %in% genestocheck)
# data.TPM.cutoff%>%lapply(function(df){
#   df<-df%>%as.data.frame()%>%rownames_to_column("Row.names")%>%
#     filter(Row.names %in% genestocheck)
#   return(df)
# })

  

#Step 17: suggestions of how to plot InEx: 
#boxplot
boxpl<-ggplot(InEx, aes(x = condition, y = mean_InEx)) +
  geom_boxplot(outlier.shape = NA,color="black") + #outlier.shape = NA prevents points from being drawn for outliers
  geom_jitter(width = 0.25, height = 0, aes(color=condition),size=1) +  # jitter = points spread apart to not overlap, only use width for horizontal spreading 
  scale_color_manual(values=c("darkgrey","blue") )+ #colors for Input and PD
  scale_y_continuous(trans = "log10", limits = c(0.01, 10), breaks = c(0.01,0.1, 1))+ #y axis is logarithmic and define the limits & breaks
  labs(x = "", y = "InEx")+ #Axis labels 
  theme_minimal() #design
#save plot as file
ggsave("17_InEx_boxplot.png", boxpl, width = 7, height =7 , units = "cm", dpi = 300)


#histogram
hist<-ggplot(InEx%>% # data= InEx df but with two separate columns for Input and PD
               pivot_wider(id_cols= Row.names,names_from = condition,
                           values_from = -c(Row.names, condition),
                           names_glue = "{condition}_{.value}")) +
  geom_histogram(aes(x = PD_mean_InEx), binwidth = 0.05, color = "black", fill=alpha("blue", alpha = 0.9)) + #histogram for PD
  geom_histogram(aes(x = Input_mean_InEx), binwidth = 0.05, color = "black", fill=alpha("darkgrey", alpha = 0.7)) + #histogram for Input
  labs(x = "InEx", y = "number of genes") +
  scale_x_continuous(breaks = seq(0,2, by = 0.5),limits = c(0, 2)) +
  theme_minimal()
#save plot as file
ggsave("17_InEx_histogram.png", hist, width = 7, height =7 , units = "cm", dpi = 300)

message("Script ran successfully and saved output files in ", subdir)
