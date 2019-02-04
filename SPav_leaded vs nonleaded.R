#Get ceramic decoration info
#LB, 10.4.16
#clp, updated 10/15/18 for South Pavilion

setwd("P:/Reports/South Pavilion and South Wing/R code")

require(RPostgreSQL)

source('credentials.R')


SPavGlass <-dbGetQuery(DRCcon,'
SELECT
"public"."tblContext"."ContextID",
"public"."tblContext"."QuadratID",
"public"."tblContext"."FeatureNumber",
"public"."tblGlass"."Quantity",
"public"."tblGlassForm"."GlassForm",
"public"."tblGlassMaterial"."GlassMaterial"
FROM
"public"."tblContext"
INNER JOIN "public"."tblContextSample" ON "public"."tblContextSample"."ContextAutoID" = "public"."tblContext"."ContextAutoID"
INNER JOIN "public"."tblGenerateContextArtifactID" ON "public"."tblContextSample"."ContextSampleID" = "public"."tblGenerateContextArtifactID"."ContextSampleID"
INNER JOIN "public"."tblGlass" ON "public"."tblGenerateContextArtifactID"."ArtifactID" = "public"."tblGlass"."ArtifactID"
INNER JOIN "public"."tblGlassForm" ON "public"."tblGlass"."GlassFormID" = "public"."tblGlassForm"."GlassFormID"
INNER JOIN "public"."tblGlassMaterial" ON "public"."tblGlass"."GlassMaterialID" = "public"."tblGlassMaterial"."GlassMaterialID"
WHERE
"public"."tblContext"."ProjectID" = \'67\'
ORDER BY
"public"."tblContext"."ContextID" ASC
')

#Aggregate by material type
Materialsum<-aggregate(SPavGlass$Quantity, by=list(SPavGlass$GlassMaterial), FUN=sum)
colnames(Materialsum)<- c("Material","Count")
                       