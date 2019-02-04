#Get ceramic form info
#LB, 10.4.16
#updated 10/15/18 for South Wing

setwd("P:/Reports/South Pavilion and South Wing/R code")

require(RPostgreSQL)

source('credentials.R')

SWingcerm <-dbGetQuery(DRCcon,'
SELECT
"public"."tblContext"."ContextID",
"public"."tblContext"."QuadratID",
"public"."tblContext"."FeatureNumber",
"public"."tblCeramic"."Quantity",
"public"."tblCeramicVesselCategory"."CeramicVesselCategory",
"public"."tblCeramicForm"."CeramicForm"
FROM
"public"."tblContext"
INNER JOIN "public"."tblContextSample" ON "public"."tblContextSample"."ContextAutoID" = "public"."tblContext"."ContextAutoID"
INNER JOIN "public"."tblGenerateContextArtifactID" ON "public"."tblContextSample"."ContextSampleID" = "public"."tblGenerateContextArtifactID"."ContextSampleID"
INNER JOIN "public"."tblCeramic" ON "public"."tblCeramic"."GenerateContextArtifactID" = "public"."tblGenerateContextArtifactID"."GenerateContextArtifactID"
INNER JOIN "public"."tblCeramicVesselCategory" ON "public"."tblCeramic"."CeramicVesselCategoryID" = "public"."tblCeramicVesselCategory"."CeramicVesselCategoryID"
INNER JOIN "public"."tblCeramicForm" ON "public"."tblCeramicForm"."CeramicFormID" = "public"."tblCeramic"."CeramicFormID"
WHERE
"public"."tblContext"."ProjectID" = \'68\'
ORDER BY
"public"."tblContext"."ContextID" ASC
')


#Subsume some Forms into Form Categories: Table, Utilitarian, and Teawares
SWingcerm$CeramicForm[SWingcerm$CeramicForm =='Basket'] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm =='Bottle'] <- 'Utilitarian'
SWingcerm$CeramicForm[SWingcerm$CeramicForm =='Jar'] <- 'Utilitarian'
SWingcerm$CeramicForm[SWingcerm$CeramicForm =='Storage Jar'] <- 'Utilitarian'
SWingcerm$CeramicForm[SWingcerm$CeramicForm =='Tile, fireplace'] <- 'Utilitarian'
SWingcerm$CeramicForm[SWingcerm$CeramicForm =='Gaming Piece'] <- 'Utilitarian'
SWingcerm$CeramicForm[SWingcerm$CeramicForm =='Bottle, blacking'] <- 'Utilitarian'
SWingcerm$CeramicForm[SWingcerm$CeramicForm =='Bowl'] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm =='Bowl, punch'] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm =='Box'] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm =='Castor'] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm =='Chamberpot'] <- 'Utilitarian'
SWingcerm$CeramicForm[SWingcerm$CeramicForm =='Coffee Pot'] <- 'Tea'
SWingcerm$CeramicForm[SWingcerm$CeramicForm =='Colander'] <- 'Utilitarian'
SWingcerm$CeramicForm[SWingcerm$CeramicForm =='Cup'] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Drug Jar/Salve Pot']<- 'Utilitarian'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Flower Pot' ] <- 'Utilitarian'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Jug' ] <- 'Utilitarian'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Milk Pan' ] <- 'Utilitarian'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Mold, jelly' ] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Mug/Can' ] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Mustard Pot' ] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Pitcher/Ewer' ] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Plate' ] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Platter' ] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Porringer' ] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Salve Pot' ] <- 'Utilitarian'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Saucer' ] <- 'Tea'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Sea Kale Pot' ] <- 'Utilitarian'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Serving Dish, unid.' ] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Storage Vessel' ] <- 'Utilitarian'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Tankard' ] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Teabowl' ] <- 'Tea'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Teacup' ] <- 'Tea'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Teapot' ] <- 'Tea'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Tureen' ] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Unid: Tableware' ] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Unid: Teaware' ] <- 'Tea'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Unid: Utilitarian' ] <- 'Utilitarian'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Unidentifiable' ] <- 'Unidentifiable'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Vegetable Dish' ] <- 'Table'
SWingcerm$CeramicForm[SWingcerm$CeramicForm == 'Wash Basin' ] <- 'Utilitarian'

#Aggregate by Form Types
justform<-aggregate(SWingcerm$Quantity, by=list(SWingcerm$CeramicForm), FUN=sum)
colnames(justform)<- c("Form","Count")

####Hollow and Flat Tablewares

#Subset all ceramics to get only table wares
SWingtable <- subset(SWingcerm, SWingcerm$CeramicForm  %in%  c('Table'))

#Create new field that combines category and form
SWingtable$FormCat <- paste(SWingtable$CeramicVesselCategory, SWingtable$CeramicForm, sep="_")

#Summarize data by new field of Category and Form
justtable<-aggregate(SWingtable$Quantity, by=list(SWingtable$FormCat), FUN=sum)
colnames(justform)<- c("Form","Count")
