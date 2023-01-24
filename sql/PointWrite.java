package dbos.procedures;

import org.voltdb.*;
import java.util.concurrent.*;

public class PointWrite extends VoltProcedure {

    public final SQLStmt addValue = new SQLStmt (
            "UPSERT INTO KeyValue VALUES(?, ?);"
    );

    public long run(int key, int value, int count, int topRange) throws VoltAbortException {
        if (topRange == 0) {
            for (int i = 0; i < count; i++) {
                voltQueueSQL(addValue, key + i, value + i);
            }
            voltExecuteSQL();
        } else {
            for (int i = 0; i < count; i++) {
                int Rkey = ThreadLocalRandom.current().nextInt(0, topRange);
                int Rvalue = ThreadLocalRandom.current().nextInt(0, topRange);
                voltQueueSQL(addValue, Rkey, Rvalue);
            }
            voltExecuteSQL();
        }
        return 0;
    }
}
