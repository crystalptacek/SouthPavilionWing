#Get nail (wrought, cut, wire) data
#clp, 10/25/16
#updated 10/10/18 for South Wing

setwd("P:/Reports/South Pavilion and South Wing/R code")

require(RPostgreSQL)

source('credentials.R')

#----get wrought nail data--------------------------

SPavWroughtNails <-dbGetQuery(DRCcon,'
SELECT
"public"."tblContext"."ContextID",
"public"."tblContext"."QuadratID",
"public"."tblContext"."FeatureNumber",
"public"."tblGenArtifact"."Quantity"
FROM
"public"."tblContext"
INNER JOIN "public"."tblContextSample" ON "public"."tblContextSample"."ContextAutoID" = "public"."tblContext"."ContextAutoID"
INNER JOIN "public"."tblGenerateContextArtifactID" ON "public"."tblContextSample"."ContextSampleID" = "public"."tblGenerateContextArtifactID"."ContextSampleID"
INNER JOIN "public"."tblGenArtifact" ON "public"."tblGenerateContextArtifactID"."ArtifactID" = "public"."tblGenArtifact"."ArtifactID"
INNER JOIN "public"."tblGenArtifactForm" ON "public"."tblGenArtifact"."GenArtifactFormID" = "public"."tblGenArtifactForm"."GenArtifactFormID"
INNER JOIN "public"."tblGenArtifactMaterial" ON "public"."tblGenArtifactMaterial"."GenerateContextArtifactID" = "public"."tblGenArtifact"."GenerateContextArtifactID"
INNER JOIN "public"."tblGenArtifactManuTech" ON "public"."tblGenArtifactMaterial"."GenArtifactManuTechID" = "public"."tblGenArtifactManuTech"."GenArtifactManuTechID"
WHERE
"public"."tblContext"."ProjectID" = \'68\' AND
"public"."tblGenArtifactForm"."GenArtifactForm" = \'Nail\'
AND
"public"."tblGenArtifactManuTech"."GenArtifactManuTech" = \'Wrought/Forged\'
ORDER BY
"public"."tblContext"."ContextID" ASC
')

sum(SPavWroughtNails$Quantity)

#-----get cut nail data---------------------------

SPavCutNails <-dbGetQuery(DRCcon,'
SELECT
"public"."tblContext"."ContextID",
"public"."tblContext"."QuadratID",
"public"."tblContext"."FeatureNumber",
"public"."tblGenArtifact"."Quantity"
FROM
"public"."tblContext"
INNER JOIN "public"."tblContextSample" ON "public"."tblContextSample"."ContextAutoID" = "public"."tblContext"."ContextAutoID"
INNER JOIN "public"."tblGenerateContextArtifactID" ON "public"."tblContextSample"."ContextSampleID" = "public"."tblGenerateContextArtifactID"."ContextSampleID"
INNER JOIN "public"."tblGenArtifact" ON "public"."tblGenerateContextArtifactID"."ArtifactID" = "public"."tblGenArtifact"."ArtifactID"
INNER JOIN "public"."tblGenArtifactForm" ON "public"."tblGenArtifact"."GenArtifactFormID" = "public"."tblGenArtifactForm"."GenArtifactFormID"
INNER JOIN "public"."tblGenArtifactMaterial" ON "public"."tblGenArtifactMaterial"."GenerateContextArtifactID" = "public"."tblGenArtifact"."GenerateContextArtifactID"
INNER JOIN "public"."tblGenArtifactManuTech" ON "public"."tblGenArtifactMaterial"."GenArtifactManuTechID" = "public"."tblGenArtifactManuTech"."GenArtifactManuTechID"
WHERE
"public"."tblContext"."ProjectID" = \'68\' AND
"public"."tblGenArtifactForm"."GenArtifactForm" = \'Nail\' AND
"public"."tblGenArtifactManuTech"."GenArtifactManuTech" = \'Machine Cut\'
ORDER BY
"public"."tblContext"."ContextID" ASC
')

sum(SPavCutNails$Quantity)

#----get wire nail data---------------------------
SPavWireNails <-dbGetQuery(DRCcon,'

        SELECT
        "public"."tblContext"."ContextID",
        "public"."tblContext"."QuadratID",
        "public"."tblContext"."FeatureNumber",
        "public"."tblGenArtifact"."Quantity"
        FROM
        "public"."tblContext"
        INNER JOIN "public"."tblContextSample" ON "public"."tblContextSample"."ContextAutoID" = "public"."tblContext"."ContextAutoID"
        INNER JOIN "public"."tblGenerateContextArtifactID" ON "public"."tblContextSample"."ContextSampleID" = "public"."tblGenerateContextArtifactID"."ContextSampleID"
        INNER JOIN "public"."tblGenArtifact" ON "public"."tblGenerateContextArtifactID"."ArtifactID" = "public"."tblGenArtifact"."ArtifactID"
        INNER JOIN "public"."tblGenArtifactForm" ON "public"."tblGenArtifact"."GenArtifactFormID" = "public"."tblGenArtifactForm"."GenArtifactFormID"
        INNER JOIN "public"."tblGenArtifactMaterial" ON "public"."tblGenArtifactMaterial"."GenerateContextArtifactID" = "public"."tblGenArtifact"."GenerateContextArtifactID"
        INNER JOIN "public"."tblGenArtifactManuTech" ON "public"."tblGenArtifactMaterial"."GenArtifactManuTechID" = "public"."tblGenArtifactManuTech"."GenArtifactManuTechID"
        WHERE
        "public"."tblContext"."ProjectID" = \'68\' AND
        "public"."tblGenArtifactForm"."GenArtifactForm" = \'Nail\'
       AND
        "public"."tblGenArtifactManuTech"."GenArtifactManuTech" = \'Drawn/Wire\'
         ORDER BY
        "public"."tblContext"."ContextID" ASC
      ')

sum(SPavWireNails$Quantity)
