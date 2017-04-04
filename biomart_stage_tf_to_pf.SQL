--------------------------------------------------------------------------
-- Play this script in BIOMART_STAGE@EC2-54-93-196-236.EU-CENTRAL-1.COMPUTE.AMAZONAWS.COM:1522/ORCL to make it look like BIOMART_STAGE@EC2-54-93-196-236.EU-CENTRAL-1.COMPUTE.AMAZONAWS.COM:1523/ORCL
--
-- Please review the script before using it to make sure it won't
-- cause any unacceptable data loss.
--
-- BIOMART_STAGE@EC2-54-93-196-236.EU-CENTRAL-1.COMPUTE.AMAZONAWS.COM:1522/ORCL Schema Extracted by User SYSTEM 
-- BIOMART_STAGE@EC2-54-93-196-236.EU-CENTRAL-1.COMPUTE.AMAZONAWS.COM:1523/ORCL Schema Extracted by User SYSTEM 

ALTER TABLE BIOMART_STAGE.BIO_ASSAY_ANALYSIS_GWAS
 ADD (P_VALUE_CHAR  VARCHAR2(100 BYTE));
-- we have pvalue_char varchar2(100)


ALTER TABLE BIOMART_STAGE.BIO_ASSAY_ANALYSIS_GWAS
 ADD (LOG10_PVAL_CHAR  VARCHAR2(100 BYTE));