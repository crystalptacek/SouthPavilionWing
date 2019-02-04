#Get ceramic decoration (Genre) info
#LB, 10.4.16
#clp, updated 10/15/18 for South Pavilion

setwd("P:/Projects/2016/South Wing and Pavilion/South Pavilion/R Code")

require(RPostgreSQL)

source('credentials.R')


SPavCerm <-dbGetQuery(DRCcon,'
SELECT
"public"."tblContext"."ContextID",
"public"."tblContext"."QuadratID",
"public"."tblContext"."FeatureNumber",
"public"."tblCeramic"."Quantity",
"public"."tblYesNo"."YesNo",
"public"."tblCeramicWare"."Ware",
"public"."tblCeramicGenre"."CeramicGenre"
FROM
"public"."tblContext"
INNER JOIN "public"."tblContextSample" ON "public"."tblContextSample"."ContextAutoID" = "public"."tblContext"."ContextAutoID"
INNER JOIN "public"."tblGenerateContextArtifactID" ON "public"."tblContextSample"."ContextSampleID" = "public"."tblGenerateContextArtifactID"."ContextSampleID"
INNER JOIN "public"."tblCeramic" ON "public"."tblCeramic"."GenerateContextArtifactID" = "public"."tblGenerateContextArtifactID"."GenerateContextArtifactID"
INNER JOIN "public"."tblYesNo" ON "public"."tblCeramic"."DecorationYN" = "public"."tblYesNo"."YesNoID"
INNER JOIN "public"."tblCeramicWare" ON "public"."tblCeramic"."WareID" = "public"."tblCeramicWare"."WareID"
LEFT JOIN "public"."tblCeramicGenre" ON "public"."tblCeramic"."CeramicGenreID" = "public"."tblCeramicGenre"."CeramicGenreID"
WHERE
"public"."tblContext"."ProjectID" = \'67\'
ORDER BY
"public"."tblContext"."ContextID" ASC
')



#Reassign YN field to Dec and Undec
SPavCerm$YesNo[SPavCerm$YesNo == 'Yes'] <- 'Dec'
SPavCerm$YesNo[SPavCerm$YesNo == 'No'] <- 'Undec'

###Result #1: Decoration Yes/No
#Summarize Decoration YN
justYN<-aggregate(SPavCerm$Quantity, by=list(SPavCerm$YesNo), FUN=sum)
colnames(justYN)<- c("DecoratedYN","Count")

###Result #2: Decoration Yes/No and Ware Type
#Create new field that combines decorationYN and ware type
SPavCerm$WareDec <- paste(SPavCerm$Ware, SPavCerm$YesNo, sep="_")

#Summarize by decorated and undecorated Ware Types
wareYN<-aggregate(SPavCerm$Quantity, by=list(SPavCerm$WareDec), FUN=sum)
colnames(wareYN)<- c("WareDec","Count")

###Result #3: Genre
justgenre<-aggregate(SPavCerm$Quantity, by=list(SPavCerm$CeramicGenre), FUN=sum)

#Summarize by Genre and Ware Types
waregenre<-aggregate(SPavCerm$Quantity, by=list(SPavCerm$WareGenre), FUN=sum)
