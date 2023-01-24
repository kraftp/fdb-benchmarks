package dbos.procedures;

import org.voltdb.*;
import java.util.concurrent.*;

public class PointRead extends VoltProcedure {

    public final SQLStmt getValue = new SQLStmt (
            "SELECT TValue FROM KeyValue WHERE TKey=?;"
    );

    public long run(int key, int count, int topRange) throws VoltAbortException {
        for (int i = 0; i < count; i++) {
            key = ThreadLocalRandom.current().nextInt(0, topRange);
            voltQueueSQL(getValue, key);
        }
        VoltTable results = voltExecuteSQL()[0];
        return 0;
    }
}
