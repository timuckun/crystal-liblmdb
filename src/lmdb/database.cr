module Lmdb
  class Database < Base
    getter handle
    getter flags

    # ##/**@brief Open a database in the environment.
    #  *
    #  * A database handle denotes the name and parameters of a database,
    #  * independently of whether such a database exists.
    #  NOTE: There are numerous warnings in the h file against closing database handles
    #        Therefore I have not implented that call.
    # def initialize(@handle : LibLmdb::MDB_dbi, @name : String, @env : Lmdb::Environment)
    #   @flags = nil
    # end
    def initialize(@env : Lmdb::Environment, @name : String | Nil = nil, @flags = Lmdb::Flags::Database::None)
      # TODO: This should be in a mutex because the call to open
      #      database can't be shared between threads. Crytal doesn't have threads yet
      #      so not an issue at this time. The mutex api might change
      @handle = uninitialized LibLmdb::MDB_dbi
      db_name = @name.try(&.to_unsafe) || nil
      flags_value = flags.to_u32

      # txn = @env.open_transaction
      # db_handle = uninitialized LibLmdb::MDB_dbi
      # with_transaction_handle do |txn_handle|

      @env.with_transaction_handle do |txn|
        check_result = LibLmdb.mdb_dbi_open(txn, db_name, flags_value, out @handle)
      end
      # end

    end

    # Returns information about the database
    def info
      stats = uninitialized LibLmdb::MDB_stat
      flags = uninitialized LibLmdb::UInt

      @env.with_transaction do |txn|
        check_result LibLmdb.mdb_stat(txn.handle, @handle, pointerof(stats))
        check_result LibLmdb.mdb_dbi_flags(txn.handle, @handle, pointerof(flags))
      end
      @flags = Lmdb::Flags::Database.new(flags)
      return {
        name:           @name,
        page_size:      stats.ms_psize,          # /**< Depth (height) of the B-tree */
        depth:          stats.ms_depth,          # /**< Number of internal (non-leaf) pages */
        leaf_pages:     stats.ms_leaf_pages,     # /**< Number of leaf pages */
        overflow_pages: stats.ms_overflow_pages, # /**< Number of overflow pages */
        entries:        stats.ms_entries,        # /**< Number of data items */
        flags:          @flags.to_s,
      }
    end

    def dupes_allowed?
      @flags.dup_sort? || @flags.dup_fixed? || @flags.integer_dup? || @flags.reverse_dup?
    end

    # ##/**@brief Empty or delete+close a database.
    #  * @delete_mode:  0 to empty the DB, 1 to delete it from the
    #  * environment and close the DB handle.

    def drop(delete_mode = 1_i32)
      # raise "can't drop the default database" if @name.nil?
      txn = @env.open_transaction
      check_result LibLmdb.mdb_drop(txn.handle, @handle, delete_mode)
      txn.commit
    end

    # This empties the database but keeps it in the environment and doesn't close the handle
    def empty
      drop(0_i32)
    end

    def [](key)
      x = nil
      @env.with_transaction(read_only: true) do |t|
        x = t.get(self, key)
      end
      x
    end

    def []=(key, data)
      retval = false
      @env.with_transaction() do |t|
        retval = t.put(self, key, data)
      end
      retval
    end

    def del(key)
      retval = false
      @env.with_transaction() do |t|
        retval = t.del(self, key)
      end
      retval
    end
  end
end
