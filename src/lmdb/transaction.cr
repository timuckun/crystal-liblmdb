module Lmdb
  class Transaction < Base
    getter? read_only = false
    getter handle : LibLmdb::MDB_txn

    @transactions = [] of Lmdb::Transaction
    @cursors = [] of Lmdb::Cursor
    MAX_DATA_SIZE = 4294967295
    MAX_KEY_SIZE  =        511 # This is the default unless you compile it with special flags

    def initialize(@handle : LibLmdb::MDB_txn, @read_only = false)
      @state = State::Open
    end

    # ##/**@brief Return the transaction's ID.
    #  * NOTE: I am not sure how useful this method is.....
    #  * This returns the identifier associated with this transaction. For a
    #  * read-only transaction, this corresponds to the snapshot being read;
    #  * concurrent readers will frequently have the same transaction ID.
    def transaction_id
      LibLmdb.mdb_txn_id(@handle)
    end

    # ##/**@brief Abandon all the operations of the transaction instead of saving them.
    #  *
    #  * The transaction handle is freed. It and its cursors must not be used
    #  * again after this call, except with #mdb_cursor_renew().
    #  * Only write-transactions free cursors.
    def abort
      if open?
        LibLmdb.mdb_txn_abort(@handle)
        @state = State::Closed
      end
      return true
    end

    # ##/**@brief Commit all the operations of a transaction into the database.
    #  *
    #  * The transaction handle is freed. It and its cursors must not be used
    #  * again after this call, except with #mdb_cursor_renew().
    #  * Only write-transactions free cursors.
    def commit
      if open?
        retval = check_result(LibLmdb.mdb_txn_commit(@handle))
        @state = State::Closed
        return retval
      else
        return 0
      end
    end

    # ##/**@brief Reset a read-only transaction.
    #  *
    #  * Abort the transaction like #mdb_txn_abort(), but keep the transaction
    #  * handle. #mdb_txn_renew() may reuse the handle. This saves allocation
    #  * overhead if the process will start a new read-only transaction soon,
    #  * and also locking overhead if #MDB_NOTLS is in use. The reader table
    #  * lock is released, but the table slot stays tied to its thread or
    #  * #MDB_txn. Use mdb_txn_abort() to discard a reset handle, and to free
    #  * its lock table slot if MDB_NOTLS is in use.
    #  * Cursors opened within the transaction must not be used
    #  * again after this call, except with #mdb_cursor_renew().
    #  * Reader locks generally don't interfere with writers, but they keep old
    #  * versions of database pages allocated. Thus they prevent the old pages
    #  * from being reused when writers commit new data, and so under heavy load
    #  * the database size may grow much more rapidly than otherwise.
    #  * @param[in] txn A transaction handle returned by #mdb_txn_begin()
    #  */
    def reset
      if self.open?
        raise "You can only reset read only transactions" unless @read_only
        # TODO: Reset all the cursors?
        LibLmdb.mdb_txn_reset(@handle)
      end
    end

    # ##/**@brief Renew a read-only transaction.
    #  *
    #  * This acquires a new reader lock for a transaction handle that had been
    #  * released by #mdb_txn_reset(). It must be called before a reset transaction
    #  * may be used again.
    #  */
    def renew
      if self.closed?
        raise "you can only reopen read_only transactions" unless @read_only
        result = check_result(LibLmdb.mdb_txn_renew(@handle))
        @state = State::Closed
      end
      # check result will raise exception unless 0 anyway so ...
      return 0
    end

    def close
      # for now I am not going to make distinctions between read only and read write
      # cursors or transactions. Maybe we'll deal with with top level read only transactions
      # at the env level
      if !self.closed?
        @cursors.each { |c| c.close }
        @transactions.each { |t| t.close }
        if self.open?
          commit
        end
        @state = State::Closed
      end
    end

    # ##/**@brief Get items from a database.
    #  *
    #  * This function retrieves key/data pairs from the database. The address
    #  * and length of the data associated with the specified \b key are returned
    #  * in the structure to which \b data refers.
    #  * If the database supports duplicate keys (#MDB_DUPSORT) then the
    #  * first data item for the key will be returned. Retrieval of other
    #  * items requires the use of #mdb_cursor_get().
    #  *
    #  * @note The memory pointed to by the returned values is owned by the
    #  * database. The caller need not dispose of the memory, and may not
    #  * modify it in any way. For values returned in a read-only transaction
    #  * any modification attempts will cause a SIGSEGV.
    #  * @note Values returned from the database are valid only until a
    #  * subsequent update operation, or the end of the transaction.
    def get(db : Lmdb::Database, key : Lmdb::KeyTypes) : Lmdb::ValTypes
      key_val = key_to_mdb_val(key) # MdbVal.new(key)
      key_ptr = pointerof(key_val)
      result = LibLmdb.mdb_get(@handle, db.handle, key_ptr, out data)
      check_result result
      # data_val = MdbVal.new(data)

      val = if @success
              # data_val.to(val_class)
              mdb_val_to_data(data)
            else
              nil
            end
    end

    # ##/**@brief Store items into a database.
    #  *
    #  * This function stores key/data pairs in the database. The default behavior
    #  * is to enter the new key/data pair, replacing any previously existing key
    #  * if duplicates are disallowed, or adding a duplicate data item if
    #  * duplicates are allowed (#MDB_DUPSORT).
    def put(db : Lmdb::Database, key : Lmdb::KeyTypes, data : Lmdb::ValTypes, flags = Lmdb::Flags::Put::None)
      key_val = key_to_mdb_val(key)    # MdbVal.new(key)
      data_val = data_to_mdb_val(data) # MdbVal.new(data)
      flags_val = flags.to_u32
      check_result LibLmdb.mdb_put(@handle, db.handle, pointerof(key_val), pointerof(data_val), flags_val) # key_val.to_ptr, data_val.to_ptr, flags_val)
      @success
    end

    # ##/**@brief Delete items from a database.
    #  *
    #  * This function removes key/data pairs from the database.
    #  * If the database does not support sorted duplicate data items
    #  * (#MDB_DUPSORT) the data parameter is ignored.
    #  * If the database supports sorted duplicates and the data parameter
    #  * is NULL, all of the duplicate data items for the key will be
    #  * deleted. Otherwise, if the data parameter is non-NULL
    #  * only the matching data item will be deleted.
    #  * This function will return false if the specified key/data
    #  * pair is not in the database.
    #  */
    def del(db : Lmdb::Database, key : String | Int, data : String | Nil = nil)
      key_val = key_to_mdb_val(key) # MdbVal.new(key)
      key_ptr = pointerof(key_val)
      data_val = data_to_mdb_val(data) # MdbVal.new(key)
      data_ptr = pointerof(data_val)
      check_result LibLmdb.mdb_del(@handle, db.handle, key_ptr, data_ptr)
      @success
    end

    # ##/**@brief Create a cursor handle.
    #  *
    #  * A cursor is associated with a specific transaction and database.
    #  * A cursor cannot be used when its database handle is closed.  Nor
    #  * when its transaction has ended, except with #mdb_cursor_renew().
    #  * It can be discarded with #mdb_cursor_close().
    #  * A cursor in a write-transaction can be closed before its transaction
    #  * ends, and will otherwise be closed when its transaction ends.
    #  * A cursor in a read-only transaction must be closed explicitly, before
    #  * or after its transaction ends. It can be reused with
    #  * #mdb_cursor_renew() before finally closing it.
    def open_cursor(db : Lmdb::Database)
      cursor = Lmdb::Cursor.new(self, db)
      @cursors << cursor
      cursor
    end

    def with_cursor(db : Lmdb::Database)
      cur = open_cursor(db)
      yield cur
      cur.close
    end

    def open_transaction
      raise "Child transactions are not supported yet"
    end
  end
end
