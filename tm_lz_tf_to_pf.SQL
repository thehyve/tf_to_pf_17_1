--------------------------------------------------------------------------
-- Play this script in TM_LZ@EC2-54-93-196-236.EU-CENTRAL-1.COMPUTE.AMAZONAWS.COM:1522/ORCL to make it look like TM_LZ@EC2-54-93-196-236.EU-CENTRAL-1.COMPUTE.AMAZONAWS.COM:1523/ORCL
--
-- Please review the script before using it to make sure it won't
-- cause any unacceptable data loss.
--
-- TM_LZ@EC2-54-93-196-236.EU-CENTRAL-1.COMPUTE.AMAZONAWS.COM:1522/ORCL Schema Extracted by User SYSTEM 
-- TM_LZ@EC2-54-93-196-236.EU-CENTRAL-1.COMPUTE.AMAZONAWS.COM:1523/ORCL Schema Extracted by User SYSTEM 

ALTER TABLE TM_LZ.LT_SRC_ACGH_DATA
 ADD (PROBHOMLOSS  VARCHAR2(50 BYTE));