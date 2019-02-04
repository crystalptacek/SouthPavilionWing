#Get glass vessel form data from the South Pavilion
#clp, 10/25/16
#updated 10/15/18 for South Wing

setwd("P:/Reports/South Pavilion and South Wing/R code")

require(RPostgreSQL)

source('credentials.R')

SPavGlass <-dbGetQuery(DRCcon,'
SELECT
"public"."tblContext"."ContextID",
"public"."tblContext"."QuadratID",
"public"."tblContext"."FeatureNumber",
"public"."tblGlass"."Quantity",
"public"."tblGlassForm"."GlassForm"
FROM
"public"."tblContext"
INNER JOIN "public"."tblContextSample" ON "public"."tblContextSample"."ContextAutoID" = "public"."tblContext"."ContextAutoID"
INNER JOIN "public"."tblGenerateContextArtifactID" ON "public"."tblContextSample"."ContextSampleID" = "public"."tblGenerateContextArtifactID"."ContextSampleID"
INNER JOIN "public"."tblGlass" ON "public"."tblGenerateContextArtifactID"."ArtifactID" = "public"."tblGlass"."ArtifactID"
INNER JOIN "public"."tblGlassForm" ON "public"."tblGlass"."GlassFormID" = "public"."tblGlassForm"."GlassFormID"
WHERE
"public"."tblContext"."ProjectID" = \'68\'
ORDER BY
"public"."tblContext"."ContextID" ASC
')

#Aggregate by Form Types
justform<-aggregate(SPavGlass$Quantity, by=list(SPavGlass$GlassForm), FUN=sum)
colnames(justform)<- c("Form","Count")
