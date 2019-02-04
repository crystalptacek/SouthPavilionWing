# Filename:    prepForHarrisMatrixViaArchEd2_14.R
# Purpose:     Pulls Stratigraphic Information from the Context tables and 
# gets them into a form that works for ArchEd. There are several data integrity
# checks. There is an option to replace individual
# contexts with their SG.
#   																							
#By:          FDN 11.26.2013
#Updated for South Pavilion: 9.6.2017
#Last Update: FDN 01.14.2018



#set the working directory
setwd("P:/Projects/2016/South Wing and Pavilion/South Pavilion/R code")


library(DBI)
library(RPostgreSQL)

# tell DBI which driver to use
source('credentials.R')

# get the contexts, SGs, features and their realted contexts
# use the "WHERE" clause to choose the Project and contexts
# FYI: correlation names do NOT need to be double quoted
csr <- dbGetQuery(DRCcon,' 
SELECT  
  		a."ProjectID",
			a."Context" as "context",
      a."DAACSStratigraphicGroup" as "SG",
			a."FeatureNumber",
			c."StratRelType" as "relationship",
			b."Context" as "relatedContext"
FROM  "tblContext"                    a 
      join "tblContextStratRel"	      b         
				on a."ContextAutoID"=b."ContextAutoID"
			join "tblContextStratRelType" 	c  				
				on b."StratRelTypeID"=c."StratRelTypeID"
WHERE ( a."ProjectID" = \'67\') 
	ORDER BY a."Context"
')


## 1.Recode the relationships to Arch-Ed .lst format ########
# Note that the recoding takes into account the differences between conventions used 
# in the DAACS backend vs. Arch-ED .lst files. In DAACS When A has a relationsip of "Seals" to B, 
# it implies that A is "above" B. In the Arch-ED .lst file format this is represented as
# "A Below:B", which causes Arch-ED to draw B below A. So to get Arch-Ed to draw DAACS
# relationships correctly, we have to "reverse" the DAACS relationship 

csr$archEdRel[csr$relationship=="Sealed By"]<-"above"
csr$archEdRel[csr$relationship=="Seals"]<-"below"
csr$archEdRel[csr$relationship=="Intruded By"]<-"above"
csr$archEdRel[csr$relationship=="Intrudes"]<-"below"
csr$archEdRel[csr$relationship=="Contained By"]<-"above"
csr$archEdRel[csr$relationship=="Within"]<-"below"
csr$archEdRel[csr$relationship=="Correlates With"]<-"equal to"
csr$archEdRel[csr$relationship=="Contains"]<-"above"
csr$archEdRel[csr$relationship=="Contemporary W"]<-"equal to"


## 1.1  Do a bit more recoding  so we do not get tripped up later by mixtures of NAs and '' in the
# SG and FeatureNumber fields
# When a Context lacks an SG or Feature Number, sometimes those fields are NULL, sometimes they have 
# blanks. In the former case, an NA is returned in R. So we make sure all the NAs are set to blanks
csr$SG[is.na(csr$SG)]    <-''
sum(is.na(csr$SG))
csr$FeatureNumber[is.na(csr$FeatureNumber)]    <-''
sum(is.na(csr$FeatureNumber))

# 1.2 Write out an Excel file with the DAACS data. Useful for trouble shooting
# The file is written to the current working directory.
write.csv (csr, file="contextStratigraphicRelationhips.csv")


## 2.This section does some data consistency checks. #####
## 2.1 Check for context values that appear in the context field but not the related context field and v.v.#####
# These need to fixed in the database BEFORE going further.
uniqueCxt<-unique(csr$context)
uniqueRelCxt<-unique(csr$relatedContext)
cxtOrphans<-uniqueCxt[!(uniqueCxt %in% uniqueRelCxt)]
paste("the following contexts do not appear as relatedContexts:",cxtOrphans)
relCxtOrphans<-uniqueRelCxt[!(uniqueRelCxt %in% uniqueCxt)]
paste("the following relatedContexts do not appear as contexts:",relCxtOrphans)

# 2.2  The cxtNoSG file may contain contexts that you REALLY do not want in the analysis,
# for example, if you are only analyzing a subset of contexts for a given project.
# To get rid of them, run the following line 
csr <-subset(csr, !(csr$relatedContext   %in% relCxtOrphans))

# 2.3 Find "equal to" context pairs that have no SG assignments.
# If there are any, fix them BEFORE going further. ALL "correlated with" contexts
# need to belong to the same SG. 
cxtNoSG<-csr$context[(csr$archEdRel=="equal to") & (csr$SG == "")]
paste("the following Contexts have 'equal to' relationships but have no SG assigned:"
      ,cxtNoSG)

## 2.4 Find any "equal to" pairs of contexts and related contexts that have DIFFERENT SG assignments.######
# If there are any, these need to be fixed (e.g. by making the SGs the same) BEFORE going further.
# First we have to assign SGs to related contexts...
#   get a list of unique contexts and their SGs and put them in a new dataframe 
relatedCxtSG<- unique(data.frame(csr$context,csr$SG,stringsAsFactors=F))
#   rename the SG variable and the Context variable in the new dataframe   
names(relatedCxtSG)[names(relatedCxtSG)=="csr.SG"] <- "relatedSG"
names(relatedCxtSG)[names(relatedCxtSG)=="csr.context"] <- "relatedContext"
# merge the new related context and related SG data frame with the orignal context and SG dataframe 
# we match merge records on the common RelatedContext field and keep everything in the orginal context table 
csr1<-merge(csr,relatedCxtSG, by="relatedContext",all.x=T)  
#   sort the result on SG, relatedSG, archEdRel 
sortedCsr1 <- csr1[order(csr1$SG, csr1$relatedSG, csr1$archEdRel),] 
#   reorder the cols for convenience
sortedCsr1 <- sortedCsr1[c(2,3,4,5,6,7,1,8)]  

# Now we look for contexts and related contexts that are "equal to" each other by have different SGs 
diffSGVec<-(sortedCsr1$archEdRel=="equal to") & (sortedCsr1$SG != sortedCsr1$relatedSG)
differentSGs <- sortedCsr1[diffSGVec,]
paste("the following Contexts have 'equal to' relationships but have Different SG assignments:")
differentSGs


## 2.5 Context/RelatedContext and SG/RelatedSG stratigraphic consistency check ########
# Check to make sure the above and below relationships among contexts that 
# belong to different SGs are consistent: contexts that belong to the
# a given SG should all have the same relationships to related contexts that all 
# belong to a second SG. This code chunk finds non-matching relationships. The steps are:
#   - Loop through the sorted data to find the cases where relationships do not match.   
#   - Note that we exclude contexts that have been assigned to the same SG
#     on the assumption that SG assignment is correct. We checked that inthe previous step. 
badRelationTF<- rep(F,nrow(sortedCsr1))
for (i in 1:(nrow(sortedCsr1)-1)) {
  # only worry about this if BOTH context and related cxt have SG assignments
  # orginal code had a bug here:' ', not  ''
  if ((sortedCsr1$SG[i] != '') & (sortedCsr1$relatedSG[i] !='')) {
    #  are the SGs at row (i) and row (i+1) the same?
      badRelationTF[i] <- (sortedCsr1$SG[i] ==  sortedCsr1$SG[i+1]) & 
      # are the related SGs the same?
        (sortedCsr1$relatedSG[i] == sortedCsr1$relatedSG[i+1]) &
      # are the archEd relations different?
       (sortedCsr1$archEdRel[i] != sortedCsr1$archEdRel[i+1]) &
        # this is the bit that excludes contexts assigned to the same SG      
       (sortedCsr1$SG[i] !=  sortedCsr1$relatedSG[i])
  }
}
badRelationTF[(which(badRelationTF == T)+1)]<-T
paste(table(badRelationTF)[2], 
"There are contradictory relationhips among contexts belonging to different SGs. Check the exported file 'badRelations.csv' for details")      
badRelation <- sortedCsr1[badRelationTF,]
badRelation

write.csv(badRelation, file="badRelation.csv")


## 3. This section preps the data in the format required by ArchEd  ########
## 3.1  Set up a Df to store the results. Its rows are all possible combinations of Contexts and relatedContexts 
allCxt <- unique(c(uniqueCxt,uniqueRelCxt))
HMData <- expand.grid(allCxt,allCxt,stringsAsFactors=F)
colnames(HMData)<-c("cxt","relCxt")
HMData$archEdRel<-"NA"


## 3.2 Assign the reciprocal relationships (e.g. A>B, B<A) 
for (i  in 1: nrow(csr)) {
    # identify the context and its related context in the data from DAACS
    thisCxt<-csr$context[i]
    thisRelCxt<-csr$relatedContext[i]
    # find the two locations in HMData
    loc1 <- which(HMData$cxt==thisCxt &  HMData$relCxt== thisRelCxt)
    loc2 <- which(HMData$cxt==thisRelCxt & HMData$relCxt== thisCxt)
     
    #assign the relationships
    HMData$archEdRel[loc1]<-csr$archEdRel[i]
    if (csr$archEdRel[i]=="above") {HMData$archEdRel[loc2]<-"below"}
    if (csr$archEdRel[i]=="below") {HMData$archEdRel[loc2]<-"above"}
    if (csr$archEdRel[i]=="equal to") {HMData$archEdRel[loc2]<-"equal to"}
    }    


# check on the results
table(HMData$archEdRel)


## 3.3 If you want to set the Contexts that belong to the same SG as "equal to" run this bit
allSG<- unique(csr$SG)
allSG<- allSG[!allSG==""]
allCxtSG <- unique(data.frame(csr$context, csr$SG, stringsAsFactors=F))
for (i  in 1: length(allSG)){
    thisSG<-allSG[i]
    cxtForThisSG <- allCxtSG$csr.context[which(allCxtSG$csr.SG==thisSG)]
    equalToIndex <- (HMData$cxt %in% cxtForThisSG) & (HMData$relCxt %in% cxtForThisSG)
    HMData$archEdRel[equalToIndex]<-"equal to"                 
}

# check on the results
table(HMData$archEdRel)


## 3.4 get rid of context pairs in the HM data file without relationships  #########
HMData<-HMData[!(HMData$archEdRel=="NA"),]
# get rid of context pairs that are the same -- keeping them cause Arch Ed to blow up.
HMData<-HMData[!(HMData$cxt==HMData$relCxt),]


# merge the SGs into the HM data file by Cxt
HMData<-merge(HMData,allCxtSG, by.x="cxt",by.y="csr.context",all.x=T)  
# sort the HM data on the SG, contexts, and relationship. Needed to write the output. 
sortedHMData<-with(HMData,
                     HMData[order(csr.SG,cxt,archEdRel,relCxt),])  



## 3.5 Run this next block _IF_ you want to to replace the contexts with their SGs #########
HMData1<-merge(HMData,relatedCxtSG, by.x="relCxt", by.y="relatedContext", all.x=T)  
 for (i in 1:nrow(HMData1)){
   if (HMData1$csr.SG[i] != "") {
     HMData1$cxt[i]<-HMData1$csr.SG[i]
   }
   if (HMData1$relatedSG[i] != "") {
     HMData1$relCxt[i]<-HMData1$relatedSG[i]
   }
 }


HMData1 <- subset(HMData1, select=c(cxt,relCxt,archEdRel))
# get rid of redundant records
HMData1 <- HMData1[HMData1$cxt != HMData1$relCxt,]
HMData1<-unique(HMData1)
sortedHMData<-HMData1[order(HMData1$cxt, HMData1$relCxt, HMData1$archEdRel),] 



# 5. This section defines functions and then uses them to write to wrote the data out in ArchEd .lst format ######
# define functions that will help with writing the output file
#setwd("P:/Projects/2016/South Wing and Pavilion/South Pavilion/R code")
first.case<-function(myVec){
# locates the first occurences of each value in a sorted vector
#
# Args:
#   myVec: the sorted vector
# Returns: a logical vector with T at the first occurrences
  result<-rep(F,length(myVec))
  for (i in (1:length(myVec))){
      if (i==1) {result[1]<-T}
      else {result[i]<- (myVec[i] != myVec[i-1])}
  }
  return(result)
}

last.case<-function(myVec){
# locates the last occurences of each value in a sorted vector
#
# Args:
#   myVec: the sorted vector
# Returns: a logical vector with T at the last occurrences
  result<-rep(F,length(myVec))
  for (i in (1:length(myVec))){
    if (i==length(myVec)) {result[length(myVec)]<-T}
    else {result[i]<- (myVec[i] != myVec[i+1])}
  }
  return(result)
}



firstSG<-first.case(sortedHMData$csr.SG)
firstCxt<-first.case(sortedHMData$cxt)
firstArchEdRel<-first.case(sortedHMData$archEdRel)
lastArchEdRel<-last.case(sortedHMData$archEdRel)
lastCxt<-last.case(sortedHMData$cxt)


##  write the output file to the currrent working directory

file.create("output.lst")
for (i in 1:nrow(sortedHMData)) {
  if (firstCxt[i] == T) {
    cat(paste(sortedHMData$cxt[i]),"\n", file="output.lst",append=TRUE)
  }
  if ((firstCxt[i] == T) | (firstArchEdRel[i]==T))  { 
    cat (paste("            ", sortedHMData$archEdRel[i]), ": ", sep="", 
         file="output.lst", append=TRUE)
  }
  cat(paste(sortedHMData$relCxt[i]), sep="", file="output.lst", append=TRUE)
  if  ((lastArchEdRel[i] == F)  & (lastCxt[i]==F)) {
    cat(", ", sep="", file="output.lst", append=TRUE)
  }
  if ((lastArchEdRel[i] == T) | (lastCxt[i]==T)) {
    cat("\n", file="output.lst",append=TRUE)
  }              
}    


if  (lastCxt[i]==F) {
  cat(" ,", file="output.lst",append=TRUE)
}


write.csv(HMData1,"HMData1.csv")
