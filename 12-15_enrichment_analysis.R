# load necessary packages
source("config_R.R")
subdir<-paste(dir, "/norm.counts_InEx", sep="")

#import intermediate files
setwd(subdir)
data.TPM.cutoff<-list(read.csv("11_TPM.exon.csv",row.names = 1),
               read.csv("11_TPM.intron.csv",row.names = 1))
names(data.TPM.cutoff)<-c("exon","intron")


#Step 12
# function for removal of genes with nonfinite values (-Inf)
all.is.finite<-function(df){
  df<-df%>%
    filter_all(all_vars(is.finite(.)))
  return(df)
}

# log-transformation
data.log<-lapply(data.TPM.cutoff, log)%>%
  lapply(all.is.finite) #removing rows where log-transf. gave -Inf 
names(data.log)<-c("intron","exon")



#Step 13
# function for t-test and correction per df
t.test.per.df<-function(df){
  df<-df%>%
    rownames_to_column("gene")%>%
    rowwise() %>% #important to run t.test per gene! 
    mutate(p_val = t.test(c_across(contains("PD_")),    
                          c_across(contains("Input_")), 
                          alternative = "two.sided")$p.value) %>% 
    #alternatively: use Mann-Whitney test instead of t.test using wilcox.test()
    ungroup() %>% #important to run correction across all tests!
    mutate(p_adj = p.adjust(p_val, method = "BH"))%>% 
    column_to_rownames("gene")
  return(df)
}
# run t-test and p-value correction
data.ttest<-lapply(data.log, t.test.per.df)

#check that t.test was performed per row (expect different p-values in each row) 
#and correction was done for all tests (not per row which would only be one test, 
#expect p_adj to be higher than p_val, if it is the same as p_val it would be per row)
#lapply(data.ttest, head)


#Step 14
# calculate a logFC: 
data.DE<-lapply(data.ttest, function(df){
      df<-df%>% mutate(logFC=mean_PD-mean_Input)
      return(df)
      })%>%
  lapply(function(df){
      df<-df%>%mutate("enriched"=case_when(
                      p_adj <= 0.05 & logFC > 0 ~ "enriched genes",
                      T ~ "not enriched genes"))
      return(df)
  })


#Step 15 
# individual lists for enriched genes in intronic or exonic counts
enriched.genes.lists<-lapply(data.DE, function(df){
                         df<-df%>%filter(p_adj <= 0.05 & logFC > 0) 
                         return(df)
                      })%>%
                      lapply(rownames)

# combined list
enriched.genes<-union(enriched.genes.lists$intron, 
                      enriched.genes.lists$exon) 
message("Number of enriched genes: ",length(enriched.genes)[1])

#output file
write.csv(enriched.genes, file="15_enriched.genes.list.csv", row.names = F)


message("Script ran successfully and saved output files in ",subdir)
