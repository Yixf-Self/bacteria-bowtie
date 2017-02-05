#DONE
#these commands make id_to_gene, id_to_product and id_to_ec_number
#setwd("/Users/Scott/tophat-bacteria/scripts/R-interactive")
#system(command = "./cuffnorm-pathways.sh")
#DONE

library(reshape2)
library(tidyr)

setwd("/Users/Scott/Google Drive/Hurwitz Lab/combined-cuffnorm-out/")

#setup####
filtered_annotated <- read.csv("diff_exp_for_all_bact.csv")
filtered_annotated <- filtered_annotated[,2:9]
attach(filtered_annotated)

#don't need no hypothetical proteins
filtered_annotated <- filtered_annotated[grep(".*hypothetical protein.*",product_name,perl=T,invert=T),]
sum_by_product_name <- read.csv("sum_by_product_name.csv")
colnames(sum_by_product_name)[1]<-"product"
attach(sum_by_product_name)

#don't need no hypothetical proteins
sum_by_product_name <- sum_by_product_name[grep(".*hypothetical protein.*",product_name,perl=T,invert=T),]
sum_by_product_name<-sum_by_product_name[,1:5]
sum_by_product_name$product <- tolower(sum_by_product_name$product)
sum_by_gene_name <- read.csv("sum_by_gene_name.csv")
colnames(sum_by_gene_name)[1]<-"gene"
sum_by_gene_name<-sum_by_gene_name[,1:5]
sum_by_gene_name$gene <- tolower(sum_by_gene_name$gene)

#now we will attempt to add pathways####
#patric_annotation <- read.delim("all.PATRIC.cds.tab")
#that took over 5 minutes
#probably better to use 'cut' to trim down to the refseq_locus_tag and pathway columns and then load the tab file
# LIKE SO (already done) cut -f 7,21 all.PATRIC.cds.tab > refseq_tag_to_pathway.tab
# and just get lines where pathways are actually known
# grep "\S\t\S" refseq_tag_to_pathway.tab > temp.tab
# mv temp.tab refseq_tag_to_pathway.tab

# Above was for the 1944 set (1944 genomes, not from the year 1944)
# For the combined we have to match product name to pathway colums
# (Already done) cut -f 15,21 all.PATRIC.cds.tab > product_to_pathway.tab
# grep -P '\S\t\S' product_to_pathway.tab > temp.tab
# mv temp.tab product_to_pathway.tab

#patric_annotation <- read.delim("product_to_pathway.tab")
#patric_annotation$product <- tolower(patric_annotation$product)
#with_pathways<-merge(x=filtered_annotated,y=patric_annotation,by.x="product_name",by.y="product")
#This took up 144gb of mem on HPC
#and ended up being a 84gb tab-delimited file!

####Start here again####
with_pathways<-with_pathways[grep(".+",with_pathways$pathway),]
with_pathways<-separate_rows(with_pathways, pathway, sep = ";")
sum_by_kegg_pathway<-rowsum(with_pathways[,c("S1_FPM","S2_FPM","S3_FPM","S4_FPM")],group = with_pathways$pathway)
sum_by_kegg_pathway<-sum_by_kegg_pathway[!is.na(sum_by_kegg_pathway$S1_FPM),]
sum_by_kegg_pathway$sum<-rowSums(sum_by_kegg_pathway[,c("S1_FPM","S2_FPM","S3_FPM","S4_FPM")])

#formatting for stupid bubble plot, which i bet could be done in R
sum_by_kegg_pathway$Name<-row.names(sum_by_kegg_pathway)

shortened<-sum_by_kegg_pathway[sum_by_kegg_pathway$sum>mean(sum_by_kegg_pathway$sum),]
shortened<-shortened[order(shortened$sum , decreasing = T),]
shortened<-shortened[,c("Name","S3_FPM","S4_FPM","S1_FPM","S2_FPM")]
colnames(shortened)=c("Name","S+H- (Control)","S-H- (SMAD3 Knockout)","S+H+ (H. hepaticus only)","S-H+ (Combined)")

setwd("~/bacteria-bowtie/scripts/R-interactive/")
write.table(shortened,"combined_sum_by_kegg_pathway_above_mean.tab", sep = "\t", quote = T,row.names = F)

shortened<-read.table("combined_sum_by_kegg_pathway_above_mean.tab",header = T)
more_shortened<-shortened[1:30,]
colnames(more_shortened)=c("Name","S+H- (Control)","S-H- (SMAD3 Knockout)","S+H+ (H. hepaticus only)","S-H+ (Combined)")

setwd("~/bacteria-bowtie/scripts/R-interactive/")
write.table(more_shortened,"combined_sum_by_kegg_pathway_above_mean.tab", sep = "\t", quote = T,row.names = F)

#Have to run this in an external shell cuz ... perl... grumble
#system("./bubble.sh combined_sum_by_kegg_pathway_above_mean.tab CombinedBubble")

system("cp CombinedBubble.pdf '/Users/Scott/Google Drive/Hurwitz Lab/manuscripts/'")

more_shortened$combined_effect<-log(more_shortened$`S-H+ (Combined)`/more_shortened$`S+H- (Control)`)
more_shortened<-more_shortened[order(more_shortened$combined_effect , decreasing = T),]

#top_sixty_five<-sum_by_kegg_pathway[order(sum_by_kegg_pathway$sum,decreasing = T)[1:65],]
#top_sixty_five<-top_sixty_five[,c("Name","S1_FPM","S2_FPM","S3_FPM","S4_FPM")]

#write.table(top_sixty_five,"~/tophat-bacteria/scripts/R-interactive/sum_by_kegg_pathway_top_sixty_five.tab", sep = "\t", quote = T,row.names = F)
