# wareTypeCAandMCD.R
# Establish a DBI connection to DAACS PostgreSQL database and submnit SQL queries
# Created by:  FDN  8.5.2014
# Previous update: EAB 3.24.2015 To add MCDs and TPQs by Phase  
# Last update: LAB 9.5.2017 to add List of Contexts with Phase Assignments for database updates
# Updated to South Pavilion CLP 10.15.2018

setwd("P:/Reports/South Pavilion and South Wing/R Code")

#load the library
require(RPostgreSQL)
library(plyr)
library(dplyr)

source('credentials.R')

# get the table with the ware type date ranges
MCDTypeTable<- dbGetQuery(DRCcon,'
                          SELECT * 
                          FROM "tblCeramicWare"
                          ')


# submit a SQL query: note the use of \ as an escape sequence
# note the LEFT JOIN on the Feature table retains non-feature contexts
# Fill in your appropriate projectID


wareTypeData<-dbGetQuery(DRCcon,'
SELECT
"public"."tblCeramic"."Quantity",
"public"."tblCeramicWare"."Ware",
"public"."tblCeramicWare"."BeginDate",
"public"."tblCeramicWare"."EndDate",
"public"."tblContextFeatureType"."FeatureType",
"public"."tblCeramicGenre"."CeramicGenre",
"public"."tblContext"."QuadratID",
"public"."tblContext"."ProjectID",
"public"."tblContext"."Context",
"public"."tblContextDepositType"."DepositType",
"public"."tblContext"."DAACSStratigraphicGroup",
"public"."tblContext"."FeatureNumber"
FROM
"public"."tblContext"
INNER JOIN "public"."tblContextSample" ON "public"."tblContextSample"."ContextAutoID" = "public"."tblContext"."ContextAutoID"
INNER JOIN "public"."tblGenerateContextArtifactID" ON "public"."tblContextSample"."ContextSampleID" = "public"."tblGenerateContextArtifactID"."ContextSampleID"
LEFT JOIN "public"."tblContextDepositType" ON "public"."tblContext"."DepositTypeID" = "public"."tblContextDepositType"."DepositTypeID"
INNER JOIN "public"."tblCeramic" ON "public"."tblCeramic"."GenerateContextArtifactID" = "public"."tblGenerateContextArtifactID"."GenerateContextArtifactID"
INNER JOIN "public"."tblCeramicWare" ON "public"."tblCeramic"."WareID" = "public"."tblCeramicWare"."WareID"
LEFT JOIN "public"."tblContextFeatureType" ON "public"."tblContext"."FeatureTypeID" = "public"."tblContextFeatureType"."FeatureTypeID" 
LEFT JOIN "public"."tblCeramicGenre" ON "public"."tblCeramic"."CeramicGenreID" = "public"."tblCeramicGenre"."CeramicGenreID"
WHERE
"public"."tblContext"."ProjectID" = \'67\'
')

#Remove contexts with deposit type cleanup and surface collection
#wareTypeData <- subset(csr1410, ! csr1410$DepositType  %in%  c('Clean-Up/Out-of-Stratigraphic Context',
#                                                               'Surface Collection'))



# Section 2:Create the UNIT Variable ######################
# This is the level at which assemblages are aggregated
# in the analysis

# compute new numeric variables from original ones, which we will need to compute the MCDs
MCDTypeTable<-within(MCDTypeTable, {     # Notice that multiple vars can be changed
  midPoint <- (EndDate+BeginDate)/2
  span <- EndDate - BeginDate
  inverseVar <- 1/(span/6)^2 
  
})


# let's see what we have for ware types and counts
#help(aggregate)
require(plyr)
summary2<-ddply(wareTypeData, .(Ware), summarise, Count=sum(Quantity))
summary2

# Now we do some ware type recoding if necessary
# For example if "American Stoneware" is William Rogers, we might recode it as "Fulham Type"
# wareTypeData$Ware[wareTypeData$Ware =='American Stoneware'] <- 'Fulham Type'


# get rid of types with no dates
typesWithNoDates <- MCDTypeTable$Ware[(is.na(MCDTypeTable$midPoint))]
wareTypeDataY<- wareTypeData[!wareTypeData$Ware %in%  typesWithNoDates,]



# Take out anamolous contexts. Can do here or in line 156. 
# wareTypeData<- subset(wareTypeData, ! wareTypeData$ContextID   %in% 
#                        c('67-2589B'))

#wareTypeData1<- subset(wareTypeData, ! wareTypeData$FeatureNumber   %in% 
#                         c('F01', 'F03'))

#Take out utility lines

# wareTypeData<- subset(wareTypeData, ! wareTypeData$FeatureType   %in% 
#                 c('Trench, utility'))


#Replace blanks in SG and Feature Number to NA
wareTypeData1 <-
  mutate(wareTypeDataY, unit=ifelse((FeatureNumber == '' & DAACSStratigraphicGroup == ''),
        paste(Context),
        ifelse((FeatureNumber != '' & DAACSStratigraphicGroup == ''),
        paste(Context, FeatureNumber),
        ifelse((FeatureNumber == '' & DAACSStratigraphicGroup != ''),
        paste(DAACSStratigraphicGroup),
        ifelse((FeatureNumber != '' & DAACSStratigraphicGroup != ''),
        paste(FeatureNumber, DAACSStratigraphicGroup),
        paste(Context)
        )))))

#Removing ware types with less than 5 sherds total. Will also do below in line 153. 
#Can do it here or down further.
#wareTypeData2<- subset(wareTypeData1, ! wareTypeData1$Ware  %in%  c('Astbury Type',
#                                                                    'Black Basalt',
#                                                                    'Bristol Glaze Stoneware'))
#                                                           'Buckley-type',
#                                                           'Canary Ware'))

## Section 3:Transpose the Data ######################


# lets get a data frame with contexts as rows and type as cols, with the
# entries as counts
WareByUnit <- ddply(wareTypeData1, .(unit, Ware), summarise, Count=sum(Quantity))

# now we transpose the data so that we end up with a context (rows) x type 
# (cols) data matrix; unit ~ ware formula syntax, left side = row, right side = column, to fill in
# body of table with the counts, fill rest with zeros
require(reshape2)
WareByUnitT <- dcast(WareByUnit, unit ~ Ware, value.var='Count', fill=0 )



# lets compute the totals for each context i.e. row
# Note the use of column numbers as index values to get the type counts, which are
# assumed to start iin col 2.
WareByUnitTTotals<- rowSums(WareByUnitT[,2:ncol(WareByUnitT)])

# OK now let's get rid of all the rows where totals are <= 5
WareByUnitT0 <-WareByUnitT[WareByUnitTTotals>5,]

#delete any outliers
WareByUnitT1 <-subset(WareByUnitT0, !WareByUnitT0$unit %in% c('F11 SG18'))

#Ok now let's get rid of all the columns (ware types) where totals < 0
#WareByUnitT2<-WareByUnitT0[, colSums(WareByUnitT1 != 0) > 0]
WareByUnitT2<-WareByUnitT1[, colSums(WareByUnitT1 != 0) > 0]



##Section 4: Define an MCD function and Function to Remove Types w/o Dates ######################

# now we build a function that computes MCDs
# two arguments: 1. unitData: a dataframe with the counts of ware types in units. We assume
# the left variable IDs the units, while the rest of the varaibles are types
# 2. typeData: a dataframe with at least two variables named 'midPoint' and 'inversevar'
# containing the manufacturing midpoints and inverse variances for the types.
# retruns a list comprise of two dataframes: 
#     MCDs has units and the vanilla and BLUE MCDs
#     midPoints has the types and manufacturing midpoints, in the order they appeaed in the input
#     unitData dataframe.  

EstimateMCD<- function(unitData,typeData){
  #for debugging
  #unitData<- WareByUnitT1
  #typeData <-mcdTypes
  countMatrix<- as.matrix(unitData[,2:ncol(unitData)])
  unitNames <- (unitData[,1])
  nUnits <- nrow(unitData)   
  nTypes<- nrow(typeData)
  nTypesFnd <-ncol(countMatrix)
  typeNames<- colnames(countMatrix)
  # create two col vectors to hold inverse variances and midpoints
  # _in the order in which the type variables occur in the data_.
  invVar<-matrix(data=0,nrow=nTypesFnd, ncol=1)
  mPoint <- matrix(data=0,nrow=nTypesFnd, ncol=1)
  for (i in (1:nTypes)){
    for (j in (1:nTypesFnd)){
      if (typeData$Ware[i]==typeNames[j]) {
        invVar[j,]<-typeData$inverseVar[i] 
        mPoint[j,] <-typeData$midPoint[i]
      }
    }
  }
  
  # replace NAs for types with no dates with 0s -- so they do not count
  # compute the blue MCDs
  # get a unit by type matrix of inverse variances
  invVarMat<-matrix(t(invVar),nUnits,nTypesFnd, byrow=T)
  # a matrix of weights
  blueWtMat<- countMatrix * invVarMat
  # sums of the weight
  sumBlueWts <- rowSums(blueWtMat)
  # the BLUE MCDs
  blueMCD<-(blueWtMat %*% mPoint) / sumBlueWts
  # compute the vanilla MCDs
  sumWts <- rowSums(countMatrix)
  # the vanilla MCDs
  MCD<-(countMatrix %*% mPoint) / sumWts
  # now for the TPQs
  meltedUnitData<- melt(unitData, id.vars='unit',  variable.name = 'Ware', value.name='count')
  meltedUnitData <- subset(meltedUnitData, count > 0) 
  mergedUnitData <- merge(x = meltedUnitData, y = typeData,  by.x='Ware', by.y='Ware')
  # the trick is that to figure out the tpq it's best to have each record (row) represent an individual sherd
  # but in its current state, each record has a count that is likely more than 1 so it's necessary to break them up
  # use rep and rownames - rowname is a unique number for each row, kind of link an index
  # rep goes through dataframe mergedUnitData and replicates based on the count column, i.e. if count is
  # 5 it will create 5 records or rows and only replicates columns 2 and 6 (2 is unit name and 6 is begin date)
  repUnitData <- mergedUnitData[rep(rownames(mergedUnitData),mergedUnitData$count),c(2,6)]
  #once all the rows have a count of one, then can run the quantile function
  TPQ <- tapply(repUnitData$BeginDate,repUnitData$unit, 
                function(x) quantile(x, probs =1.0, type=3 ))              
  TPQp95 <- tapply(repUnitData$BeginDate,repUnitData$unit, 
                   function(x) quantile(x, probs = .95 , type=3 ))                 
  TPQp90 <- tapply(repUnitData$BeginDate,repUnitData$unit, 
                   function(x) quantile(x, probs = .90, , type=3 ))   
  # Finally we assemble the results in to a list
  MCDs<-data.frame(unitNames,MCD,blueMCD, TPQ, TPQp95, TPQp90, sumWts )
  colnames(MCDs)<- c('unit','MCD','blueMCD', 'TPQ', 'TPQp95', 'TPQp90', 'Count')
  midPoints <- data.frame(typeNames,mPoint)
  MCDs <- list('MCDs'=MCDs,'midPoints'=midPoints)
  return(MCDs)
} 
#end of function EstimateMCD


# apply the function
MCDByUnit<-EstimateMCD(WareByUnitT2,MCDTypeTable)
MCDByUnit

# a function to sort the rows and cols of a matrix based on the
# orders from two arguments (e.g. MCDs and midpoints)
# arguments:  the name of the variable that contains the unit scores (e.g. MCDs)
#             the name of the variable that contains the type score (e.g. the midpoints)
#             the name of the dataframe that contains the counts of ware types in units
# returns:    the sorted dataframe 
sortData<- function(unitScores,typeScores,unitData){
  #unitScores<-U3MCDByUnit$MCDs$blueMCD
  #typeScores<-U3MCDByUnit$midPoints$mPoint
  #unitData<- U3WareByUnitT1
  sortedData<-unitData[order(unitScores),]
  sortedData<-sortedData[,c(1,order(typeScores)+1)]
  return(sortedData)
}

# apply the function
WareByUnitT2Sorted<-sortData(MCDByUnit$MCDs$blueMCD,
                             MCDByUnit$midPoints$mPoint,
                             WareByUnitT2)
WareByUnitT2Sorted

# now we prep the sorted dataframe to make a Bertin plot
# convert to a matrix, whose cols are the counts
# make the unit name a 'rowname" of the matrix
Mat<-as.matrix(WareByUnitT2Sorted[,2:ncol(WareByUnitT2Sorted)])
rownames(Mat)<-WareByUnitT2Sorted$unit
rSums<- matrix (rowSums(Mat),nrow(Mat),ncol(Mat), byrow=F)
MatProp<-Mat/rSums


# do the plot
#(package for seriation)
library(plotrix) 
battleship.plot(MatProp,
                mar=c(2,5,10,5),
                #main = 'Seriation',
                #xlab='ManuTech',
                ylab= 'Context',
                col='grey')

# now let's try some Correspondence Analysis
Matx<-as.matrix(WareByUnitT2[,2:ncol(WareByUnitT2)]) 
rownames(Matx)<-WareByUnitT2$unit

require(ca)
ca3<-ca(Matx)


#summary(ca3)

# put the result in dataframes
# create dataframe of unit/context dimension 1 and 2 scores for ggplot
inertia <- data.frame('Inertia' = prop.table(ca3$sv^2))
rowScores <- data.frame(ca3$rowcoord, rownames=ca3$rownames)
colScores <- data.frame(ca3$colcoord, rownames=ca3$colnames)


# Compute the broken stick model inertia
broken.stick <- function(p)
  # Compute the expected values of the broken-stick distribution for 'p' pieces.
  # Example: broken.stick.out.20 = broken.stick(20)
  #             Pierre Legendre, April 2007
{
  result = matrix(0,p,2)
  colnames(result) = c("Dim","Expected.Inertia")
  for(j in 1:p) {
    E = 0
    for(x in j:p) E = E+(1/x)
    result[j,1] = j
    result[j,2] = E/p
  }
  result <- result
  return(data.frame(result))
}

bs <- broken.stick(nrow(inertia))


# plot the proportion of inertia
theme_set(theme_classic(base_size = 20))

p <- ggplot(data=inertia , aes(x= 1:length(Inertia), y=Inertia)) +
  # geom_bar(stat="identity", fill="grey") +
  geom_line(col= "cornflower blue", size=1) +
  geom_point(shape=21, size=5, colour="black", fill="cornflower blue") +
  xlab ('Dimension') + 
  ylab( "Proportion of Inertia") +
  ggtitle('CA Scree Plot') +
  geom_line(aes(y = bs[,2], x= bs[,1]), color = "black", linetype = "dashed", 
            size=1)
p


# ggplot version of row scores dim 1 and dim 2
library(ggrepel)
set.seed(42)
p1 <- ggplot(rowScores, aes(x = Dim1,y = Dim2))+
  geom_point(shape=21, size=5, colour="black", fill="cornflower blue")+
  #geom_text(aes(label= rownames(rowscores)),vjust=-.6, cex=5) +
  theme_classic()+
  theme(plot.title = element_text(hjust = 0.5))+
  xlab (paste('Dimension 1',':   ', format(inertia[1,]*100, digits=2), '%')) + 
  ylab (paste('Dimension 2',':   ', format(inertia[2,]*100, digits=2), '%')) +
  geom_text_repel(aes(label=rownames(rowScores)), cex = 4) +
  labs(title="South Pavilion")

p1

#save the plot for website chronology page/presentations
ggsave("SouthPavilion_CADim1Dim2.png", p1, width=10, height=7.5, dpi=300)



#create dataframe of unit/context dimension 1 and 2 scores for ggplot
rowscores <- data.frame(ca3$rowcoord[,1], ca3$rowcoord[,2])
colnames(rowscores) <- c("Dim1", "Dim2")

#create dataframe of ware type dimension 1 and 2 scores for ggplot
colscores <- data.frame(ca3$colcoord[,1], ca3$colcoord[,2])
colnames(colscores) <- c("Dim1", "Dim2")


#########################

#create dataframe of unit/context dimension 1 and 3 scores for ggplot
rowscores <- data.frame(ca3$rowcoord[,1], ca3$rowcoord[,3])
colnames(rowscores) <- c("Dim1", "Dim3")

#create dataframe of ware type dimension 1 and 3 scores for ggplot
colscores <- data.frame(ca3$colcoord[,1], ca3$colcoord[,3])
colnames(colscores) <- c("Dim1", "Dim3")

#ggplot version of row scores dim 1 and dim 3
p1a <- ggplot(rowscores, aes(x=Dim1,y=Dim3))+
  geom_point(shape=21, size=5, colour="black", fill="cornflower blue")+
#  #geom_text(aes(label=CA_MCD_Phase1$unit),vjust=-.6, cex=5)+
  theme_classic()+
  theme(plot.title = element_text(hjust = 0.5))+
  geom_text_repel(aes(label=rownames(rowscores)), cex=4) +
  xlab (paste('Dimension 1',':   ', format(inertia[1,]*100, digits=2), '%')) + 
  ylab (paste('Dimension 3',':   ', format(inertia[3,]*100, digits=2), '%')) +
  labs(title="South Pavilion", x="Dimension 1", y="Dimension 3")
p1a
#save the plot for website chronology page/presentations
#ggsave("SouthPavilion_Figure1Dim1Dim3_2018.png", p1a, width=10, height=7.5, dpi=300)




# plot the col scores on dim1 and dim3, which types are important in which regions of the plot
#plot(ca3$colcoord[,1],ca3$colcoord[,3],pch=21, bg="cornflower blue",cex=1.25,
#  xlab="Dimension 1", ylab="Dimension 3", asp=1, cex.lab=1.25, cex.axis=1.25)
#text(ca3$colcoord[,1],ca3$colcoord[,3],rownames(ca3$colcoord),
#    pos=4 ,cex=1.25, col="black")

#p1b <- ggplot(colscores, aes(x=colscores$Dim1,y=colscores$Dim3))+
#  geom_point(shape=21, size=5, colour="black", fill="cornflower blue")+
#  #geom_text(aes(label=CA_MCD_Phase1$unit),vjust=-.6, cex=5)+
#  geom_text_repel(aes(label=rownames(colscores)), cex=4) +
#  theme_classic()+
#  labs(title="South Pavilion", x="Dimension 1", y="Dimension 3")+
#  theme(plot.title=element_text(size=rel(2.25), hjust=0.5),axis.title=element_text(size=rel(1.75)),
#        axis.text=element_text(size=rel(1.5)))
#p1b


################

#ggplot version of col scores dim 1 and dim 2
p2 <- ggplot(colScores, aes(x = Dim1,y = Dim2))+
  geom_point(shape=21, size=5, colour="black", fill="cornflower blue")+
  #geom_text(aes(label=CA_MCD_Phase1$unit),vjust=-.6, cex=5)+
  theme(plot.title = element_text(hjust = 0.5))+
  xlab (paste('Dimension 1',':   ', format(inertia[1,]*100, digits=2), '%')) + 
  ylab (paste('Dimension 2',':   ', format(inertia[2,]*100, digits=2), '%')) +
  geom_text_repel(aes(label=rownames(colScores)), cex= 3) +
  labs(title="South Pavilion") 

p2



#save the plot for website chronology page/presentations
ggsave("SouthPavilion_Figure2WareTypes_2018.png", p2, width=10, height=7.5, dpi=300)



#ggplot version of col scores dim 1 and dim 2


# finally let's see what the relationship is between MCDs and CA scores

# CA Dim 1 vs. MCDs
#plot(ca3$rowcoord[,1], MCDByUnit$MCDs$blueMCD, pch=21, bg="black",cex=1.25,
#    xlab="Dimension 1", ylab="BLUE MCD",cex.lab=1.5, cex.axis=1.5)
#text(ca3$rowcoord[,1],MCDByUnit$MCDs$blueMCD,rownames(ca3$rowcoord),
#     pos=4, cex=1.25, col="black")

#ggplot version of CA Dim 1 vs. MCDs
p3 <- ggplot(rowscores, aes(x=rowscores$Dim1,y=MCDByUnit$MCDs$blueMCD))+
  geom_point(shape=21, size=5, colour="black", fill="cornflower blue")+
  #geom_text(aes(label=CA_MCD_Phase1$unit),vjust=-.6, cex=5)+
  #geom_text_repel(aes(label=rownames(rowscores)), cex=6) +
  theme_classic()+
  labs(title="South Pavilion", x="Dimension 1", y="BLUE MCD")+
  theme(plot.title=element_text(size=rel(2.25), hjust=0.5),axis.title=element_text(size=rel(1.75)),
        axis.text=element_text(size=rel(1.5)))
p3 + geom_vline(xintercept=c(-1.6))
cor.test(ca3$rowcoord[,1],MCDByUnit$MCDs$blueMCD, method="kendall")

#save the plot for website chronology page/presentations
ggsave("SouthPavilion_Dim1BLUEMCD_2018.png", p3, width=10, height=7.5, dpi=300)

# CA Dim 2 vs. MCD
#plot(ca3$rowcoord[,2], MCDByUnit$MCDs$blueMCD, pch=21, bg="black", cex=1.25,
#    xlab="Dimension 2", ylab="BLUE MCD", cex.lab=1.5, cex.axis=1.5)
#text(ca3$rowcoord[,2],MCDByUnit$MCDs$blueMCD,rownames(ca3$rowcoord),
#   pos=4, cex=1.25, col="black")

p4 <- ggplot(rowscores, aes(x=rowscores$Dim2,y=MCDByUnit$MCDs$blueMCD))+
  geom_point(shape=21, size=5, colour="black", fill="cornflower blue")+
  #geom_text(aes(label=CA_MCD_Phase1$unit),vjust=-.6, cex=5)+
  # geom_text_repel(aes(label=rownames(rowscores)), cex=6) +
  theme_classic()+
  labs(title="South Pavilion", x="Dimension 2", y="BLUE MCD")+
  theme(plot.title=element_text(size=rel(2.25), hjust=0.5),axis.title=element_text(size=rel(1.75)),
        axis.text=element_text(size=rel(1.5)))
p4 
cor.test(ca3$rowcoord[,2],MCDByUnit$MCDs$blueMCD, method="kendall")
#ggsave("SouthPavilion_Dim2BLUEMCD.png", p4, width=10, height=7.5, dpi=300)

#create table of contexts, counts, and mcds
unit <- MCDByUnit$MCDs$unit
dim1Scores <- ca3$rowcoord[,1]
dim2Scores <- ca3$rowcoord[,2]
MCD<- MCDByUnit$MCDs$MCD
blueMCD <-MCDByUnit$MCDs$blueMCD
count<- MCDByUnit$MCDs$Count

CA_MCD<-data.frame(unit, dim1Scores,dim2Scores,MCD,blueMCD, count) 

#Create weighted histogram for phasing
library(plotrix)

#Compares counts of sherds in all units with BLUE MCDs that fall within bin
#You may need to change sequence dates
weighted.hist(CA_MCD$blueMCD, CA_MCD$count, breaks=seq(1760,1870,10), col='lightblue')

#Dim 1 Scores Weighted Histogram, you may need to change scale
#Currently creates different plot than hist!!!!!!
p5 <- ggplot(CA_MCD, aes(x=CA_MCD$dim1Scores, weight=CA_MCD$count/sum(CA_MCD$count)))+
  geom_histogram(aes(y=..density..), colour="gray", fill="tan", binwidth=0.1, boundary=0.5)+
  #xlim(-4,3)+
  #stat_function(fun = dnorm, colour = "blue")+
  # scale_x_continuous(breaks=seq(-4, 2, 0.5), limits=c(-3.5,3))+
  theme_classic()+
  labs(title="South Pavilion", x="Dimension 1", y="Density")+
  theme(plot.title=element_text(size=rel(2.25), hjust=0.5),axis.title=element_text(size=rel(1.75)),
        axis.text=element_text(size=rel(1.5)))+
  geom_density(fill=NA)
p5
p5a <- p5 + geom_vline(xintercept=c(-1.6))
p5a
ggsave("SouthPavilion_Histogram_2018.png", p5a, width=10, height=7.5, dpi=300)

#Add lines for phase breaks
#p5 + geom_vline(xintercept = 75, size = 1, colour = "gray", linetype = "dashed")
#save the plot for website chronology page/presentations
# ggsave("FirstHerm_Histogram.png", p5, width=10, height=7.5, dpi=300)
# 
# #Dim 1 Scores Weighted Histogram, you may need to change scale
# #Lines step adds density curve to weighted histogram
# hist(rep(ca3$rowcoord[,1], MCDByUnit$MCDs$Count),col='tan',border='grey', breaks=seq(-6,2,.1),
#      main='West Cabin',
#      xlab="Dimension 1 Scores",
#      freq=F, cex.lab=1.5, cex.axis=1.5, cex.main=1.5)
# lines(density(ca3$rowcoord[,1], weights=MCDByUnit$MCDs$Count/sum(MCDByUnit$MCDs$Count)), 
#       lwd=2)
# #Add line breaks to the plot for phases
# abline(v=-2, lty=1, col="grey")
# abline(v=0, lty=1, col="grey")

# create a vector for the phases with as many entries as assemblages
Phase <- rep(NA, length(ca3$rowcoord[,1])) 
# do the phase assigments
Phase[(ca3$rowcoord[,1] <= -1.6)] <- 'P01'  
#Phase[(ca3$rowcoord[,1] > -2.2) & (ca3$rowcoord[,1]) <= -1.2] <- 'P02'
Phase[(ca3$rowcoord[,1] > -1.6) ] <- 'P02'

Phase

#create df of contexts, counts, mcds and phases
unit <- MCDByUnit$MCDs$unit
dim1Scores <- ca3$rowcoord[,1]
dim2Scores <- ca3$rowcoord[,2]
MCD<- MCDByUnit$MCDs$MCD
blueMCD <-MCDByUnit$MCDs$blueMCD
count<- MCDByUnit$MCDs$Count

CA_MCD_Phase<-data.frame(unit, dim1Scores,dim2Scores,MCD,blueMCD, Phase, count) 

#Order by dim1 score
CA_MCD_Phase1 <- CA_MCD_Phase[order(CA_MCD_Phase$dim1Scores),]

CA_MCD_Phase1

#weighted mean
#tapply function = applies whatever function you give it, x is object on which you calculate the function
#W is numerical weighted vector
tapply(CA_MCD_Phase1$blueMCD, CA_MCD_Phase1$Phase, weighted.mean)

#Export data
#write.csv(CA_MCD_Phase, file='CA_MCD_Phase_SouthPavilion.csv')

#BlueMCDByDim1 plot 
#black border with unit labels can comment out geom_point and geom_text lines to add, situate, and remove labels
require(ggplot2)
library(ggrepel)
p6 <- ggplot(CA_MCD_Phase1,aes(x=CA_MCD_Phase1$dim1Scores,y=CA_MCD_Phase1$blueMCD))+
  #  scale_y_continuous(limits=c(1760, 1920))+
  geom_point(aes(colour=CA_MCD_Phase1$Phase),size=5)+
  geom_text_repel(aes(label=CA_MCD_Phase1$unit), cex=4) +
  theme_classic()+
  labs(title="South Pavilion", x="Dimension 1", y="BLUE MCD")+
  theme(plot.title=element_text(size=rel(2), hjust=0.5),axis.title=element_text(size=rel(1.75)),
        axis.text=element_text(size=rel(1.5)), legend.text=element_text(size=rel(1.75)),
        legend.title=element_text(size=rel(1.5)), legend.position="bottom")+
  scale_colour_manual(name="DAACS Phase",
                      labels=c("P01", "P02"),
                      values=c("skyblue", "blue", "darkblue"))
p6
#save the plot for website chronology page/presentations
ggsave("SouthPavilion_Dim1MCDcolor_2018.png", p6, width=10, height=7.5, dpi=300)
