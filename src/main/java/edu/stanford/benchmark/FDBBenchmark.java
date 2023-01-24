package edu.stanford.benchmark;

import com.apple.foundationdb.Database;
import com.apple.foundationdb.FDB;
import org.apache.commons.cli.*;
import org.voltdb.client.Client;
import org.voltdb.client.ClientFactory;
import org.voltdb.client.ProcCallException;

import java.io.IOException;
import java.util.Collection;
import java.util.List;
import java.util.concurrent.*;
import java.util.stream.Collectors;

public class FDBBenchmark {

    public static final int numKeys = 100000;
    private static final int threadPoolSize = 256;

    private static final Collection<Long> readTimes = new ConcurrentLinkedQueue<>();
    private static final Collection<Long> writeTimes = new ConcurrentLinkedQueue<>();

    public static void main(String[] args) throws InterruptedException, ParseException, IOException, ProcCallException {
        Options options = new Options();
        options.addOption("b", true, "Benchmark");
        options.addOption("i", true, "Benchmark Interval (μs)");
        options.addOption("d", true, "Benchmark duration (s)");
        options.addOption("c", true, "Connection");
        options.addOption("r", true, "Read Percentage");
        options.addOption("o", true, "Number of ops/transaction");

        CommandLineParser parser = new DefaultParser();
        CommandLine cmd = parser.parse(options, args);

        long interval = 1000;
        if (cmd.hasOption("i")) {
            interval = Integer.parseInt(cmd.getOptionValue("i"));
        }
        long duration = 10;
        if (cmd.hasOption("d")) {
            duration = Integer.parseInt(cmd.getOptionValue("d"));
        }
        int numOps = 10;
        if (cmd.hasOption("o")) {
            numOps = Integer.parseInt(cmd.getOptionValue("o"));
        }

        String benchmark = "fdb";
        if (cmd.hasOption("b")) {
            benchmark = cmd.getOptionValue("b");
        }

        String connection = "localhost";
        if (cmd.hasOption("c")) {
            connection = cmd.getOptionValue("c");
        }

        int readPercentage = 100;
        if (cmd.hasOption("r")) {
            readPercentage = Integer.parseInt(cmd.getOptionValue("r"));
        }

        if (benchmark.equals("fdb")) {
            benchmarkFDB(interval, duration, numOps, readPercentage);
        } else if (benchmark.equals("volt")) {
            benchmarkVolt(interval, duration, numOps, connection, readPercentage);
        } else {
            System.out.printf("Invalid benchmark: %s", benchmark);
        }
    }

    public static void benchmarkFDB(long interval, long duration, int numOps, int readPercentage) throws InterruptedException {
        FDB fdb = FDB.selectAPIVersion(710);
        Database db = fdb.open();
        // Set keys
        db.run(tr -> {
            for (int key = 0; key < numKeys; key++) {
                tr.set(Utilities.toByteArray(key), Utilities.toByteArray(key));
            }
            return null;
        });

        // Measure read performance
        ExecutorService threadPool = Executors.newFixedThreadPool(threadPoolSize);
        long startTime = System.currentTimeMillis();
        long endTime = startTime + (duration * 1000);

        Runnable r = () -> {
            long t0 = System.nanoTime();
            int chooser = ThreadLocalRandom.current().nextInt(0, 100);
            if (chooser < readPercentage) {
                db.run(tr -> {
                    for (int op = 0; op < numOps; op++) {
                        int key = ThreadLocalRandom.current().nextInt(0, numKeys);
                        tr.get(Utilities.toByteArray(key)).join();
                    }
                    return null;
                });
                readTimes.add(System.nanoTime() - t0);
            } else {
                db.run(tr -> {
                    for (int op = 0; op < numOps; op++) {
                        int key = ThreadLocalRandom.current().nextInt(0, numKeys);
                        int value = ThreadLocalRandom.current().nextInt(0, numKeys);
                        tr.set(Utilities.toByteArray(key), Utilities.toByteArray(value));
                    }
                    return null;
                });
                writeTimes.add(System.nanoTime() - t0);
            }
        };

        while (System.currentTimeMillis() < endTime) {
            long t = System.nanoTime();
            threadPool.submit(r);
            while (System.nanoTime() - t < interval * 1000) {
                // Busy-spin
            }
        }

        long elapsedTime = System.currentTimeMillis() - startTime;

        List<Long> queryTimes = readTimes.stream().map(i -> i / 1000).sorted().collect(Collectors.toList());
        int numQueries = queryTimes.size();
        if (numQueries > 0) {
            long average = queryTimes.stream().mapToLong(i -> i).sum() / numQueries;
            double throughput = (double) numQueries * 1000.0 / elapsedTime;
            long p50 = queryTimes.get(numQueries / 2);
            long p99 = queryTimes.get((numQueries * 99) / 100);
            System.out.printf("Reads: Duration: %d Interval: %dμs Queries: %d TPS: %s Average: %dμs p50: %dμs p99:%dμs\n", elapsedTime, interval, numQueries, String.format("%.03f", throughput), average, p50, p99);
        } else {
            System.out.println("No reads");
        }

        queryTimes = writeTimes.stream().map(i -> i / 1000).sorted().collect(Collectors.toList());
        numQueries = queryTimes.size();
        if (numQueries > 0) {
            long average = queryTimes.stream().mapToLong(i -> i).sum() / numQueries;
            double throughput = (double) numQueries * 1000.0 / elapsedTime;
            long p50 = queryTimes.get(numQueries / 2);
            long p99 = queryTimes.get((numQueries * 99) / 100);
            System.out.printf("Writes: Duration: %d Interval: %dμs Queries: %d TPS: %s Average: %dμs p50: %dμs p99:%dμs\n", elapsedTime, interval, numQueries, String.format("%.03f", throughput), average, p50, p99);
        } else {
            System.out.println("No writes");
        }

        db.close();

        threadPool.shutdown();
        threadPool.awaitTermination(100000, TimeUnit.SECONDS);
        System.out.printf("All queries finished! %d\n", System.currentTimeMillis() - startTime);
    }

    public static void benchmarkVolt(long interval, long duration, int numOps, String connection, int readPercentage) throws InterruptedException, IOException, ProcCallException {
        Client client = ClientFactory.createClient();
        client.createConnection(connection);
        // Set keys
        client.callProcedure("PointWrite", 0, 0, numKeys, 0);

        // Measure read performance
        ExecutorService threadPool = Executors.newFixedThreadPool(threadPoolSize);
        long startTime = System.currentTimeMillis();
        long endTime = startTime + (duration * 1000);

        Runnable r = () -> {
            long t0 = System.nanoTime();
            int chooser = ThreadLocalRandom.current().nextInt(0, 100);
            if (chooser < readPercentage) {
                int key = ThreadLocalRandom.current().nextInt(0, numKeys);
                try {
                    client.callProcedure("PointRead", key, numOps, numKeys);
                } catch (IOException | ProcCallException e) {
                    e.printStackTrace();
                }
                readTimes.add(System.nanoTime() - t0);
            } else {
                int key = ThreadLocalRandom.current().nextInt(0, numKeys);
                int value = ThreadLocalRandom.current().nextInt(0, numKeys);
                try {
                    client.callProcedure("PointWrite", key, value, numOps, numKeys);
                } catch (IOException | ProcCallException e) {
                    e.printStackTrace();
                }
                writeTimes.add(System.nanoTime() - t0);
            }
        };

        while (System.currentTimeMillis() < endTime) {
            long t = System.nanoTime();
            threadPool.submit(r);
            while (System.nanoTime() - t < interval * 1000) {
                // Busy-spin
            }
        }

        long elapsedTime = System.currentTimeMillis() - startTime;

        List<Long> queryTimes = readTimes.stream().map(i -> i / 1000).sorted().collect(Collectors.toList());
        int numQueries = queryTimes.size();
        if (numQueries > 0) {
            long average = queryTimes.stream().mapToLong(i -> i).sum() / numQueries;
            double throughput = (double) numQueries * 1000.0 / elapsedTime;
            long p50 = queryTimes.get(numQueries / 2);
            long p99 = queryTimes.get((numQueries * 99) / 100);
            System.out.printf("Reads: Duration: %d Interval: %dμs Queries: %d TPS: %s Average: %dμs p50: %dμs p99:%dμs\n", elapsedTime, interval, numQueries, String.format("%.03f", throughput), average, p50, p99);
        } else {
            System.out.println("No reads");
        }

        queryTimes = writeTimes.stream().map(i -> i / 1000).sorted().collect(Collectors.toList());
        numQueries = queryTimes.size();
        if (numQueries > 0) {
            long average = queryTimes.stream().mapToLong(i -> i).sum() / numQueries;
            double throughput = (double) numQueries * 1000.0 / elapsedTime;
            long p50 = queryTimes.get(numQueries / 2);
            long p99 = queryTimes.get((numQueries * 99) / 100);
            System.out.printf("Writes: Duration: %d Interval: %dμs Queries: %d TPS: %s Average: %dμs p50: %dμs p99:%dμs\n", elapsedTime, interval, numQueries, String.format("%.03f", throughput), average, p50, p99);
        } else {
            System.out.println("No writes");
        }
        threadPool.shutdown();
        threadPool.awaitTermination(100000, TimeUnit.SECONDS);
        System.out.printf("All queries finished! %d\n", System.currentTimeMillis() - startTime);
    }
}
