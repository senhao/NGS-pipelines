##########
#packages
library(fields)
library(gplots)
library(RColorBrewer)
library(ggplot2)

#library(reshape2)
#library(ggplot2)
#library(plyr)
#library(lattice)
#library(rgl)

# ##### Testing #####
# #read data
# datasmall=read.delim('Sample_WT_277_1.plus.exons_small.bed',head=F)
# #add individual exon variable
# datasmall$exon <- as.factor(paste(datasmall$V4, datasmall$V2, datasmall$V3, sep='_'))
# #sort into correct order
# datasmall <- datasmall[with(datasmall, order(exon, as.numeric(V11))), ]
# #transform counts: add 1 to allow for regions of transcript with no coverage 
# datasmall$tCounts <- datasmall$V12+1
# head(datasmall)
# pieces <- split(datasmall$tCounts, datasmall$V4)
# test.bins2 <- sapply(pieces, mRNA.stats.bin)

#Sample selection #####
#Sample <- print(commandArgs(trailingOnly=TRUE))
Sample <- c("alx8_277_7")
sPath <- paste0("exon_beds_subjunc/", "Sample_", Sample, "/")
outFolder <- paste0("mRNA_coverage_results/","Sample_", Sample)
dir.create(outFolder, showWarnings = F, recursive = T)
#####

data_plus=read.delim(paste0(sPath, "Sample_", Sample, ".plus.exons.bed.gz"),head=F)
data_minuus=read.delim(paste0(sPath, "Sample_", Sample, ".minus.exons.bed.gz"),head=F)
                     
#add individual exon variable
data_plus$exon <- as.factor(paste(data_plus$V4, data_plus$V2, data_plus$V3, sep='_'))
data_minuus$exon <- as.factor(paste(data_minuus$V4, data_minuus$V2, data_minuus$V3, sep='_'))
#sort into correct order
data_plus <- data_plus[with(data_plus, order(exon, as.numeric(V11))), ]
data_minuus <- data_minuus[with(data_minuus, 
                                order(exon, as.numeric(V11), decreasing = T)), ]
#transform counts: add 1 to allow for regions of transcript with no coverage 
data_plus$tCounts <- data_plus$V12+1
data_minuus$tCounts <- data_minuus$V12+1
data <- rbind(data_plus, data_minuus)
head(data)

#split data
bigpieces <- split(data$tCounts, data$V4)

### function
mRNA.stats.bin100 <- function(x){
  temp_bin <- stats.bin(c(1:length(x)), x, N=100, breaks=seq(1,length(x),length(x)/101))
  (temp_bin$stats["mean",])*(100/sum(temp_bin$stats["mean",])) 
}

mRNA.stats.bin10 <- function(x){
  temp_bin <- stats.bin(c(1:length(x)), x, N=10, breaks=seq(1,length(x),length(x)/11))
  (temp_bin$stats["mean",])*(10/sum(temp_bin$stats["mean",])) 
}

#Call function
#test.bins.massive <- sapply(bigpieces, mRNA.stats.bin)
#tail(test.bins.massive)

#filter input list
#transcripts > 300 nt
bigpiecesFilter <- bigpieces
#length filter
geneLengths <- sapply(bigpiecesFilter, length)
bigpiecesFilter <- bigpiecesFilter[which(geneLengths > 500)]
# abundance filter
geneMax <- sapply(bigpiecesFilter, max)
geneSums <- sapply(bigpiecesFilter, sum)
geneLengths <- sapply(bigpiecesFilter, length)
gene_rpkm <- sapply(bigpiecesFilter, function(x) sum(x)/length(x))
bigpiecesFilter <- bigpiecesFilter[which(gene_rpkm > 100)]
#length(which(gene_rpkm > 50))
#length(which(geneSums > 500))

#make the bins 
mRNA_coverage100 <- sapply(bigpiecesFilter, mRNA.stats.bin100)
mRNA_coverage10 <- sapply(bigpiecesFilter, mRNA.stats.bin10)

#genome average plot#####
bigpiecesFilterdf <- as.data.frame(log2(mRNA_coverage100))
meansCov <- rowMeans(bigpiecesFilterdf)
bins <- seq(1:100)
SD <- apply(bigpiecesFilterdf,1, sd, na.rm = TRUE)
SE <- apply(bigpiecesFilterdf, 1, function(x) sd(x/sqrt(length(x))))
#Quats <- apply(bigpiecesFilterdf,1, quantile, na.rm = TRUE)
plot.this <- data.frame(bins, meansCov, SD)
write.csv(plot.this, paste0(outFolder, "/", Sample, "_average_mRNA_density.csv"))

pdf(paste0(outFolder, "/", Sample,"_plot.pdf"))
ggplot(plot.this,aes(bins)) + 
  geom_line(aes(y=meansCov)) +
  geom_ribbon(aes(ymin= meansCov-SD, ymax= meansCov+SD), 
              #colour = c("blue"), 
              fill = c("lightblue"),
              #linetype = 2, 
              alpha= 0.1) +
  ylab("Log2 fold change relative to even distribution") +
  xlab("Transcript position 5'-3'") +
  theme_bw() +
  ggtitle(paste0("Average Relative distribution of reads over mRNAs in ", Sample))
dev.off()


#heatmap 100 #####
out <- mRNA_coverage100
#out <- out[1:100,1:5000]
out.transposed=t(out)
#colnames(out.transposed)=row.names(out.transposed)
#out.transposed=out.transposed[2:nrow(out.transposed),]
out.transposed.log2 <- log2(out.transposed)
#write.table(out.transposed,'mRNA_density_WT.txt',sep='\t',row.names=F,quote=F)
write.csv(out.transposed.log2, paste0(Sample, '_mRNA_densities.csv'))

#sapply(out.transposed.log2, mean)

#colBlueShades = c(seq(0,10,length=11))
paletteBlueShades <- colorRampPalette(c("blue", "white", "red"))(n = 100)
pdf(paste0(outFolder, "/", Sample,"_mRNA_density_heatmap_100bins.pdf"))
heatmap.2(out.transposed.log2,
          Colv=NA,
          labRow = F,
          col=paletteBlueShades,
          #breaks=colBlueShades,
          density.info="none", 
          trace="none",
          dendrogram=c("row"), 
          symm=F,
          symkey=F,
          key=T,
          #keysize=1,
          symbreaks=T, 
          scale="row",
          cexCol=0.25,
          cexRow=0.1
)
dev.off()

##########

#heatmap 100 #####
out <- mRNA_coverage10
#out <- out[1:100,1:5000]
out.transposed=t(out)
#colnames(out.transposed)=row.names(out.transposed)
#out.transposed=out.transposed[2:nrow(out.transposed),]
out.transposed.log2 <- log2(out.transposed)
#write.table(out.transposed,'mRNA_density_WT.txt',sep='\t',row.names=F,quote=F)
write.csv(out.transposed.log2, paste0(Sample, '_mRNA_densities.csv'))

#sapply(out.transposed.log2, mean)

#colBlueShades = c(seq(0,10,length=11))
paletteBlueShades <- colorRampPalette(c("blue", "white", "red"))(n = 100)
pdf(paste0(outFolder, "/", Sample,"_mRNA_density_heatmap_10bins.pdf"))
heatmap.2(out.transposed.log2,
          Colv=NA,
          col=paletteBlueShades,
          #breaks=colBlueShades,
          density.info="none", 
          trace="none",
          dendrogram=c("row"), 
          symm=F,
          symkey=F,
          key=T,
          #keysize=1,
          symbreaks=T, 
          scale="row",
          cexCol=0.25,
          cexRow=0.1
)
dev.off()

##########










