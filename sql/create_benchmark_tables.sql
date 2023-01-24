CREATE TABLE KeyValue (
                               TKey INTEGER NOT NULL,
                               TValue INTEGER NOT NULL,
                               PRIMARY KEY(TKey)
);
PARTITION TABLE KeyValue ON COLUMN TKey;
CREATE INDEX KeyValueIndex ON KeyValue (TKey);