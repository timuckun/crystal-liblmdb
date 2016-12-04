module Lmdb
  class Cursor < Base

    DUPE_OPS = [
      LibLmdb::CursorOp::MDB_FIRST_DUP,
      LibLmdb::CursorOp::MDB_LAST_DUP,
      LibLmdb::CursorOp::MDB_NEXT_DUP,
      LibLmdb::CursorOp::MDB_PREV_DUP,
      LibLmdb::CursorOp::MDB_GET_BOTH,
      LibLmdb::CursorOp::MDB_GET_BOTH_RANGE,
    ]
    # enum Ops : UInt32
    #   FIRST     # #/**< Position at first key/data item */
    #   FIRST_DUP # #/**< Position at first data item of current key.
    #   # Only for #MDB_DUPSORT */
    #   GET_BOTH       # #/**< Position at key/data pair. Only for #MDB_DUPSORT */
    #   GET_BOTH_RANGE # #/**< position at key nearest data. Only for #MDB_DUPSORT */
    #   GET_CURRENT    # #/**< Return key/data at current cursor position */
    #   GET_MULTIPLE   # #/**< Return key and up to a page of duplicate data items
    #   # from current cursor position. Move cursor to prepare
    #   # for #MDB_NEXT_MULTIPLE. Only for #MDB_DUPFIXED */
    #   LAST     # #/**< Position at last key/data item */
    #   LAST_DUP # #/**< Position at last data item of current key.
    #   #  Only for #MDB_DUPSORT */
    #   NEXT     # #/**< Position at next data item */
    #   NEXT_DUP # #/**< Position at next data item of current key.
    #   #  Only for #MDB_DUPSORT */
    #   NEXT_MULTIPLE # #/**< Return key and up to a page of duplicate data items
    #   #  from next cursor position. Move cursor to prepare
    #   #  for #MDB_NEXT_MULTIPLE. Only for #MDB_DUPFIXED */
    #   NEXT_NODUP # #/**< Position at first data item of next key */
    #   PREV       # #/**< Position at previous data item */
    #   PREV_DUP   # #/**< Position at previous data item of current key.
    #   # Only for #MDB_DUPSORT */
    #   PREV_NODUP # #/**< Position at last data item of previous key */
    #   SET        # #/**< Position at specified key */
    #   SET_KEY    # #/**< Position at specified key return key + data */
    #   SET_RANGE  # #/**< Position at first key greater than or equal to specified key. */
    # end

    getter database
    getter transaction
    @dupes_allowed : Bool
    @integer_keys : Bool

    # getter success? : Bool

    def initialize(@transaction : Lmdb::Transaction, @db : Lmdb::Database)
      check_result LibLmdb.mdb_cursor_open(@transaction.handle, @db.handle, out @handle)
      @state = State::Open
      @dupes_allowed = @db.dupes_allowed?
      @integer_keys = @db.flags.integer_key?
      @key_class = @integer_keys ? UInt64 : String
      @success = true
    end

    # ##/**@brief Close a cursor handle.
    #  *
    #  * The cursor handle will be freed and must not be used again after this call.
    #  * Its transaction must still be live if it is a write-transaction.
    def close
      if self.open?
        LibLmdb.mdb_cursor_close(@handle)
      end
    end

    # ##/**@brief Renew a cursor handle.
    #  * NOTE: Renewing transactions and cursors is not yet implemented be careful if you are using this call
    #  *
    #  * A cursor is associated with a specific transaction and database.
    #  * Cursors that are only used in read-only
    #  * transactions may be re-used, to avoid unnecessary malloc/free overhead.
    #  * The cursor may be associated with a new read-only transaction, and
    #  * referencing the same database handle as it was created with.
    #  * This may be done whether the previous transaction is live or dead.

    def renew(txn : Lmdb::Transaction)
      raise "Can't renew an open cursor" if self.open?
      result = check_result(LibLmmdb.mdb_cursor_renew(txn.handle, @handle))
      @transaction = txn
      @state = State::Open
      result
    end

    # private def check_key(key)
    #   return if key.nil?
    #     if key.is_a?(String)
    #       raise "This database only supports integer keys" if @integer_keys
    #     else
    #       raise "This database only support string keys" unless @integer_keys
    #     end
    #   end

    # ##/**@brief Retrieve by cursor.
    #  *
    #  * This function retrieves key/data pairs from the database. The address and length
    #  * of the key are returned in the object to which \b key refers (except for the
    #  * case of the #MDB_SET option, in which the \b key object is unchanged), and
    #  * the address and length of the data are returned in the object to which \b data
    #  * refers.
    #  *
    #  * NOTE:  the values of key and data are optional depending on the call you make
    #  *        Pass in nil for those calls
    #  *        The output will be a named tuple of MdbVal objects. You can call
    #  *        You can call to_s or to_i on them as needed (be careful!!)
    #  *

    def get_op(key : Lmdb::KeyTypes,
               data : Lmdb::ValTypes,
               operation = LibLmdb::CursorOp::None,
               val_class : Lmdb::ValClasses = String)


      if !@dupes_allowed && DUPE_OPS.includes?(operation)
        raise "This operation is only supported on databases which support duplicate keys"
      end

      key_val = MdbVal.new(key)
      data_val = MdbVal.new(data)
      key_ptr = key_val.to_ptr
      data_ptr = data_val.to_ptr

      result = LibLmdb.mdb_cursor_get(@handle, key_ptr, data_ptr, operation.to_u64)

      check_result result

      return_key = key_val.to(@key_class)

      return_val = if result == LibLmdb::MDB_NOTFOUND
                     nil
                   else
                     data_val.to(val_class)
                   end
      {@success, return_key, return_val}

      # {result, key_val.to(key_class), data_val.to(val_class)}
      # {result, nil, nil}
    end

    #  Move to the first key in the database Returns false result if database is empty
    def first( val_class : Lmdb::ValClasses = String)
      get_op nil, nil, LibLmdb::CursorOp::MDB_FIRST,  val_class
    end

    # Move to the last key in the database, returning True on success
    # or False if the database is empty.
    def last(val_class : Lmdb::ValClasses = String)
      get_op nil, nil, LibLmdb::CursorOp::MDB_LAST,  val_class
    end

    def next( val_class : Lmdb::ValClasses = String)
      get_op nil, nil, LibLmdb::CursorOp::MDB_NEXT,  val_class
    end

    def prev( val_class : Lmdb::ValClasses = String)
      get_op nil, nil, LibLmdb::CursorOp::MDB_PREV,  val_class
    end

    # Dup movement methods. These methods rely on the key in the current record

    def first_dup(val_class : Lmdb::ValClasses = String)
      get_op nil, nil, LibLmdb::CursorOp::MDB_FIRST_DUP,  val_class
    end

    def last_dup(val_class : Lmdb::ValClasses = String)
      get_op nil, nil, LibLmdb::CursorOp::MDB_LAST_DUP, val_class
    end

    def next_dup( val_class : Lmdb::ValClasses = String)
      get_op nil, nil, LibLmdb::CursorOp::MDB_NEXT_DUP,  val_class
    end

    def prev_dup( val_class : Lmdb::ValClasses = String)
      get_op nil, nil, LibLmdb::CursorOp::MDB_PREV_DUP,  val_class
    end

    # Move to the next highest key value
    def next_no_dup( val_class : Lmdb::ValClasses = String)
      get_op nil, nil, LibLmdb::CursorOp::MDB_NEXT_NODUP,  val_class
    end

    def prev_no_dup( val_class : Lmdb::ValClasses = String)
      get_op nil, nil, LibLmdb::CursorOp::MDB_PREV_NODUP, val_class
    end

    # GET_BOTH_RANGE # #/**< position at key nearest data. Only for #MDB_DUPSORT */
    # SET_RANGE      # #/**< Position at first key greater than or equal to specified key. */

    def find(key : Lmdb::KeyTypes,  val_class : Lmdb::ValClasses = String)
      get_op key, nil, LibLmdb::CursorOp::MDB_SET_KEY,val_class
    end

    def find(key : Lmdb::KeyTypes, val : Lmdb::ValTypes,  val_class : Lmdb::ValClasses = String)
      get_op key, val, LibLmdb::CursorOp::MDB_GET_BOTH,  val_class
    end

    # Position at first key greater than or equal to specified key.
    def find_ge(key : Lmdb::KeyTypes, val_class : Lmdb::ValClasses = String)
      get_op key, nil, LibLmdb::CursorOp::MDB_SET_RANGE, val_class
    end

    # This version of the call seeks the value that's greater or equal to the one given
    # FOR THE EXACT KEY.  It only looks for the records with the key specified.
    # Only for #MDB_DUPSORT */
    def find_ge(key : Lmdb::KeyTypes, val : Lmdb::ValTypes,  val_class : Lmdb::ValClasses = String)
      get_op key, val, LibLmdb::CursorOp::MDB_GET_BOTH_RANGE, val_class
    end

    def current( val_class : Lmdb::ValClasses = String)
      get_op nil, nil, LibLmdb::CursorOp::MDB_GET_CURRENT, val_class
    end

    def put(key : Lmdb::KeyTypes, val : Lmdb::ValTypes, put_flags = Lmdb::Flags::Put::None)

      key_val = MdbVal.new(key)
      data_val = MdbVal.new(val)
      key_ptr=key_val.to_ptr
      data_ptr=data_val.to_ptr
      check_result LibLmdb.mdb_cursor_put(@handle, key_ptr, data_ptr,put_flags.to_u64)
      @success ? : {@success, key, val} : {@success, nil, nil}
    end

   # Delete current key/data pair
   #  *
   #  * This function deletes the key/data pair to which the cursor refers.
   def del
     check_result LibLmdb.mdb_cursor_del(@handle, 0)
     @success
   end

   #  *   delete all of the data items for the current key.
   #  *		This flag may only be specified if the database was opened with #MDB_DUPSORT.
   def del_all
     if  !@dupes_allowed
       raise "Dupes are not allowed in this database use `del` instead"
     end

     check_result LibLmdb.mdb_cursor_del(@handle, LibLmdb::MDB_NODUPDATA)
     @success
   end

   def count
     check_result LibLmdb.mdb_cursor_count(@handle, out count)
     count
   end

  end
end
