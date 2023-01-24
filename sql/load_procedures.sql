load classes target/DBOSProcedures.jar;

DROP PROCEDURE PointRead IF EXISTS;
CREATE PROCEDURE PARTITION ON TABLE KeyValue COLUMN TKey PARAMETER 0 FROM CLASS dbos.procedures.PointRead;

DROP PROCEDURE PointWrite IF EXISTS;
CREATE PROCEDURE PARTITION ON TABLE KeyValue COLUMN TKey PARAMETER 0 FROM CLASS dbos.procedures.PointWrite;
