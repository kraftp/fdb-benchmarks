Get storage server bytes:

    fdbcli --exec "status json" | grep "stored_bytes"

Addresses:

    fdbcli --exec "status json" | grep "\"address\""