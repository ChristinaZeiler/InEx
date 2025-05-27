# load necessary packages
source("config_R.R")
subdir<-paste(dir, "/norm.counts_InEx", sep="")

#Step 8
# function for loading TSV files and renaming their count column to the sample name
read.in<-function(element){
  new.name<-str_replace(element,"\\.tsv$","")%>%
    str_replace("^7[abc]_","")
  read_tsv(element, col_names=c("gene",new.name),show_col_types = FALSE)
}

# function to list all TSV files for intronic, exonic or exonic (strictly) counts and make a raw count table each from them
raw.read<-function(suffix){
  raw.count.df<-list.files(pattern=suffix)%>%
    lapply(read.in)%>%
    purrr::reduce(full_join, by = "gene")%>%
    as.data.frame()%>%
    mutate(gene=str_replace(gene, "\\.[0-9]+$", ""))%>%
    filter(!grepl("^__", gene))%>%
    column_to_rownames("gene")
  return(raw.count.df)
}

# apply the functions to make your list of raw count dfs
setwd(paste(dir,"/counts",sep="")) #dir is defined in config file, 7_counts is the subdirectory with TSV files from counting in step 7

#suffixes that distinguish files for intronic, exonic and strictly exonic counts 
suffixes<-c("intron.tsv", "exon.tsv", "exon.strict.tsv") 

#create df list 
data.raw<-lapply(suffixes,raw.read)


#name list elements to intuitively access dfs 
names(data.raw)<-c("intron","exon","exon.strict") 


#Step 9a
#library size = intronic (union) plus exonic (intersection-strict) counts
lib.size<-colSums(data.raw[["exon.strict"]]) + colSums(data.raw[["intron"]])
#typeof(lib.size)

#Step 9b
# library size normalization
norm.CPM<- function(df){
  out.df<-sweep(df, 2, lib.size / 1e6, FUN = "/")
  return(out.df)
}
data.CPM <- lapply(data.raw, norm.CPM)

#manually check calculations
#lapply(data.raw, head)
#head(lib.size)
#lapply(data.CPM, head)


#Step 10
#importing exon intron length information 
exin.length<-read.csv(paste(dir, "/genome/6_intron_exon_length.csv", sep=""))%>% 
    #file from step 6; in case this is not in the same folder provide path!
  mutate(gene_id=str_replace(gene_id, "\\.[0-9]+$", ""))%>% 
  # removing version number from Ensembl gene IDs
  column_to_rownames("gene_id")%>%
  subset(in_length!=0) #removing single exon genes

# add the intron and exon length columns to the library size normalized count tables
data.CPM.lengths<-lapply(data.CPM, merge, y=exin.length, by="row.names")%>%
  lapply(as.data.frame)

# divide all sample columns (in this case all starting with PD or Input) by either intron or exon length 

# function for common operations: removing length columns and adding condition average columns
TPM.table.clean.up<-function(df){
  df<-df%>%
    select(-c(in_length,ex_length))%>%
    rowwise()%>%
    mutate(mean_PD=mean(c_across(contains("PD")), na.rm=T),
           mean_Input=mean(c_across(contains("Input")),
           na.rm=T))%>%
    ungroup()
  return(df)
}

data.TPM<-list()
data.TPM[["intron"]]<-data.CPM.lengths[["intron"]]%>%
  mutate(across(contains("PD_") | contains("Input_"), 
                .fns = ~ . / in_length * 1000))%>%
  TPM.table.clean.up()

data.TPM[["exon"]]<-data.CPM.lengths[["exon"]]%>%
  mutate(across(contains("PD_") | contains("Input_"), 
                .fns = ~ . / ex_length * 1000))%>% 
  TPM.table.clean.up()


#Step 11
# calculate mean overall TPM in PD as cutoff value
PD.mean<-mean(data.TPM[["intron"]]$mean_PD)

# remove genes where the mean exonic or intronic counts of PD samples is below cutoff
data.TPM.cutoff<-data.TPM%>%
  lapply(filter, mean_PD>PD.mean)%>% 
  lapply(column_to_rownames,"Row.names")


subdir<-paste(dir, "/norm.counts_InEx", sep="")
if (!dir.exists(subdir)) {dir.create(subdir)}
setwd(subdir)
write.csv(data.TPM.cutoff[["exon"]], file="11_TPM.exon.csv",row.names = T)
write.csv(data.TPM.cutoff[["intron"]], file="11_TPM.intron.csv",row.names = T)

message("Script ran successfully and saved output files in ", subdir)
