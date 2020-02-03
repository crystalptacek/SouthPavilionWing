#Get ceramic form info
#LB, 10.4.16
#clp, updated 10/15/18 for South Pavilion

setwd("P:/Reports/South Pavilion and South Wing/R code")

require(RPostgreSQL)

source('credentials.R')


SPavcerm <-dbGetQuery(DRCcon,'
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
"public"."tblContext"."ProjectID" = \'67\'
ORDER BY
"public"."tblContext"."ContextID" ASC
')


#Subsume some Forms into Form Categories: Table, Utilitarian, and Teawares
SPavcerm$CeramicForm[SPavcerm$CeramicForm =='Basket'] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm =='Bottle'] <- 'Utilitarian'
SPavcerm$CeramicForm[SPavcerm$CeramicForm =='Jar'] <- 'Utilitarian'
SPavcerm$CeramicForm[SPavcerm$CeramicForm =='Storage Jar'] <- 'Utilitarian'
SPavcerm$CeramicForm[SPavcerm$CeramicForm =='Tile, fireplace'] <- 'Utilitarian'
SPavcerm$CeramicForm[SPavcerm$CeramicForm =='Gaming Piece'] <- 'Utilitarian'
SPavcerm$CeramicForm[SPavcerm$CeramicForm =='Bottle, blacking'] <- 'Utilitarian'
SPavcerm$CeramicForm[SPavcerm$CeramicForm =='Bowl'] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm =='Bowl, punch'] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm =='Box'] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm =='Castor'] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm =='Chamberpot'] <- 'Utilitarian'
SPavcerm$CeramicForm[SPavcerm$CeramicForm =='Coffee Pot'] <- 'Tea'
SPavcerm$CeramicForm[SPavcerm$CeramicForm =='Colander'] <- 'Utilitarian'
SPavcerm$CeramicForm[SPavcerm$CeramicForm =='Cup'] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Drug Jar/Salve Pot']<- 'Utilitarian'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Flower Pot' ] <- 'Utilitarian'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Jug' ] <- 'Utilitarian'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Milk Pan' ] <- 'Utilitarian'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Mold, jelly' ] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Mug/Can' ] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Mustard Pot' ] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Pitcher/Ewer' ] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Plate' ] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Platter' ] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Porringer' ] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Salve Pot' ] <- 'Utilitarian'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Saucer' ] <- 'Tea'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Sea Kale Pot' ] <- 'Utilitarian'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Serving Dish, unid.' ] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Storage Vessel' ] <- 'Utilitarian'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Tankard' ] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Teabowl' ] <- 'Tea'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Teacup' ] <- 'Tea'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Teapot' ] <- 'Tea'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Tureen' ] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Unid: Tableware' ] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Unid: Teaware' ] <- 'Tea'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Unid: Utilitarian' ] <- 'Utilitarian'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Unidentifiable' ] <- 'Unidentifiable'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Vegetable Dish' ] <- 'Table'
SPavcerm$CeramicForm[SPavcerm$CeramicForm == 'Wash Basin' ] <- 'Utilitarian'

#Aggregate by Form Types
justform<-aggregate(SPavcerm$Quantity, by=list(SPavcerm$CeramicForm), FUN=sum)
colnames(justform)<- c("Form","Count")

####Hollow and Flat Tablewares

#Subset all ceramics to get only table wares
SPavtable <- subset(SPavcerm, SPavcerm$CeramicForm  %in%  c('Table'))

#Create new field that combines category and form
SPavtable$FormCat <- paste(SPavtable$CeramicVesselCategory, SPavtable$CeramicForm, sep="_")

#Summarize data by new field of Category and Form
justtable<-aggregate(SPavtable$Quantity, by=list(SPavtable$FormCat), FUN=sum)
colnames(justform)<- c("Form","Count")

#Now let's see the specific Forms
SPavForms <-dbGetQuery(DRCcon,'
SELECT
"public"."tblCeramicForm"."CeramicForm",
Sum("public"."tblCeramic"."Quantity")
FROM
"public"."tblCeramic"
INNER JOIN "public"."tblCeramicForm" ON "public"."tblCeramic"."CeramicFormID" = "public"."tblCeramicForm"."CeramicFormID"
WHERE
"public"."tblCeramic"."ArtifactID" LIKE \'67%\'
GROUP BY
"public"."tblCeramicForm"."CeramicForm"
ORDER BY
"public"."tblCeramicForm"."CeramicForm" ASC
')
