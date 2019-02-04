#Get Glass ManuTech info
#clp, 10/24/16
#updated 10/10/18 for South Pavilion

setwd("P:/Reports/South Pavilion and South Wing/R code")

require(RPostgreSQL)

source('credentials.R')


SPavGlassManuTech <-dbGetQuery(DRCcon,'
SELECT
"public"."tblContext"."ContextID",
"public"."tblContext"."QuadratID",
"public"."tblContext"."FeatureNumber",
"public"."tblGlass"."Quantity",
"public"."tblGlassManuTech"."GlassManuTech"
FROM
"public"."tblContext"
INNER JOIN "public"."tblContextSample" ON "public"."tblContextSample"."ContextAutoID" = "public"."tblContext"."ContextAutoID"
INNER JOIN "public"."tblGenerateContextArtifactID" ON "public"."tblContextSample"."ContextSampleID" = "public"."tblGenerateContextArtifactID"."ContextSampleID"
INNER JOIN "public"."tblGlass" ON "public"."tblGenerateContextArtifactID"."ArtifactID" = "public"."tblGlass"."ArtifactID"
INNER JOIN "public"."tblGlassManuTech" ON "public"."tblGlass"."GlassManuTechID" = "public"."tblGlassManuTech"."GlassManuTechID"
WHERE
"public"."tblContext"."ProjectID" = \'67\'
ORDER BY
"public"."tblContext"."ContextID" ASC
')

#Aggregate by ManuTech Types
justform<-aggregate(SPavGlassManuTech$Quantity, by=list(SPavGlassManuTech$GlassManuTech), FUN=sum)
colnames(justform)<- c("ManuTech","Count")
