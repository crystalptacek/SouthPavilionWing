#Get mortar data
#clp, 10/25/16
#updated 10/10/18 for South Pavilion

setwd("P:/Reports/South Pavilion and South Wing/R code")

require(RPostgreSQL)

source('credentials.R')

SPavmortar <-dbGetQuery(DRCcon,'
SELECT
"public"."tblContext"."ContextID",
"public"."tblContext"."QuadratID",
"public"."tblContext"."FeatureNumber",
"public"."tblGenArtifact"."Quantity",
"public"."tblGenArtifact"."Weight"
FROM
"public"."tblContext"
INNER JOIN "public"."tblContextSample" ON "public"."tblContextSample"."ContextAutoID" = "public"."tblContext"."ContextAutoID"
INNER JOIN "public"."tblGenerateContextArtifactID" ON "public"."tblContextSample"."ContextSampleID" = "public"."tblGenerateContextArtifactID"."ContextSampleID"
INNER JOIN "public"."tblGenArtifact" ON "public"."tblGenerateContextArtifactID"."ArtifactID" = "public"."tblGenArtifact"."ArtifactID"
INNER JOIN "public"."tblGenArtifactForm" ON "public"."tblGenArtifact"."GenArtifactFormID" = "public"."tblGenArtifactForm"."GenArtifactFormID"
WHERE
"public"."tblContext"."ProjectID" = \'67\' AND
"public"."tblGenArtifactForm"."GenArtifactForm" LIKE \'Mortar%\'
ORDER BY
"public"."tblContext"."ContextID" ASC
')

sum(SPavmortar$Quantity)
sum(SPavmortar$Weight)
