module Lmdb
  # NOTE: See the lmdb.h file for detailed descriptions of how these functions work
  class Environment < Base
    getter handle
    property databases = {} of String => Lmdb::Database
    getter? read_only : Bool

    # ##   Initializer
    #             db_path
    #              Location of directory (if `subdir=true`) or file prefix to store
    #             the database.

    #             max_db_size`:
    #             Maximum size database may grow to; used to size the memory mapping.
    #             If database grows larger than ``max_db_size``, an exception will be
    #             raised and the user must close and reopen Environment.
    #             On 64-bit there is no penalty for making this huge (say 1TB). Must
    #             be <2GB on 32-bit.

    #              flags
    #              by default Forcing the locks to go with the transactions.
    #              Pass in an empty array to have the default locks in threads

    #              File permissions:
    #                 The database will be created with these permissions default 755
    #
    #         `max_readers`:
    #             Maximum number of simultaneous read transactions. Can only be set
    #             by the first process to open an environment, as it affects the size
    #             of the lock file and shared memory area. Attempts to simultaneously
    #             start more than this many *read* transactions will fail.
    def initialize(db_path : String,
                   max_db_size = 10485760,
                   @flags = Lmdb::Flags::Environment::NO_TLS,
                   file_permissions = 0o755,
                   max_readers = 126, #
                   max_dbs = 0                   )
      @read_only = @flags.read_only?

      create_subdir_if_not_exists(db_path, file_permissions)
      # get the handle
      check_result LibLmdb.mdb_env_create(out @handle)
      # The following has to be set before the environment can be opened
      set_max_readers(max_readers)
      set_max_dbs(max_dbs)
      set_map_size(max_db_size)
      check_result LibLmdb.mdb_env_open(@handle, db_path, @flags, file_permissions)
      @state = State::Open
    end

    def close
      LibLmdb.mdb_env_close(@handle)
      @state = State::Closed
    end

    # ##/**@brief Set environment @flags.
    #  *
    #  * This may be used to set some @flags in addition to those from
    #  * #mdb_env_open(), or to unset these @flags.  If several threads
    #  * change the @flags at the same time, the result is undefined.
    def set_flags(@flags : Lmdb::Flags::Environment, on_or_off = 1)
      check_result LibLmdb.mdb_env_set_flags(@handle, @flags, on_or_off)
    end

    # ##/**Copy an LMDB environment to the specified path, with options.
    #  *
    #  * This function may be used to make a backup of an existing environment.
    #  * No lockfile is created, since it gets recreated at need.
    def copy_to(destination_path : String, compact = false)
      options = compact ? 0 : LibLmdb::MDB_CP_COMPACT
      check_result LibLmdb.mdb_env_copy2(@handle, destination_path, options)
    end

    #  * This defines the number of slots in the lock table that is used to track readers in the
    #  * the environment. The default is 126.
    def set_max_readers(max_readers : LibC::UInt | Int32)
      check_result LibLmdb.mdb_env_set_maxreaders(@handle, max_readers)
    end

    #  * This function is only needed if multiple databases will be used in the
    #  * environment. Simpler applications that use the environment as a single
    #  * unnamed database can ignore this option.
    #  * This function may only be called after #mdb_env_create() and before #mdb_env_open().
    def set_max_dbs(max_dbs = 0.as(LibLmdb::MDB_dbi))
      check_result LibLmdb.mdb_env_set_maxdbs(@handle, max_dbs)
    end

    #  * This gathers all information about the environment and gives it in a struct.
    #  * It is not cached to reflect the latest true state of the env
    def info
      version_ptr = LibLmdb.mdb_version(out major, out minor, out patch)
      version = String.new(version_ptr)
      LibLmdb.mdb_env_get_maxreaders(@handle, out max_readers)
      check_result LibLmdb.mdb_env_stat(@handle, out stats)
      check_result LibLmdb.mdb_env_info(@handle, out env_info)
      check_result LibLmdb.mdb_env_get_flags(@handle, out flags_int)
      check_result LibLmdb.mdb_env_get_path(@handle, out path)
      return {
        version:             version,
        max_readers:         max_readers,
        page_size:           stats.ms_psize,
        depth:               stats.ms_depth,
        branch_pages:        stats.ms_branch_pages,
        leaf_pages:          stats.ms_leaf_pages,
        overflow_pages:      stats.ms_overflow_pages,
        entries:             stats.ms_entries,
        map_size:            env_info.me_mapsize,
        last_page_no:        env_info.me_last_pgno,
        last_transaction_id: env_info.me_last_txnid,
        number_of_readers:   env_info.me_numreaders,
        flags:               Lmdb::Flags::Environment.new(flags_int).to_s,
        path:                String.new(path),
        max_key_size:        LibLmdb.mdb_env_get_maxkeysize(@handle),
      }
    end

    # ##/**@brief Flush the data buffers to disk.
    #  *
    #  * Data is always written to disk when #mdb_txn_commit() is called,
    #  * This function is not needed under normal circumstances.
    #  * It's here just in case.
    def flush(force = true)
      force_flag = force ? 1 : 0
      check_result LibLmdb.mdb_env_sync(@handle, force_flag)
    end

    # ##/**@brief Set the size of the memory map to use for this environment.
    #  *
    #  * The size should be a multiple of the OS page size. The default is
    #  * 10485760 bytes. The size of the memory map is also the maximum size
    #  * of the database. The value should be chosen as large as possible,
    #  * to accommodate future growth of the database.
    def set_map_size(size : LibLmdb::SizeT | Int32)
      check_result LibLmdb.mdb_env_set_mapsize(@handle, size)
    end

    def read_only?
      @read_only
    end

    def create_subdir_if_not_exists(path : String, file_permissions)
      # Note I am not implementing this right now, I think it's better to raise
      # an error if the database path does not exist
    end

    def open_database(database_name : (String | Nil) = nil, flags = Lmdb::Flags::Database::None)
      # TODO: This should be in a mutex because the call to open
      #      database can't be shared between threads. Crytal doesn't have threads yet
      #      so not an issue at this time. The mutex api might change

      Database.new(self, database_name, flags)
    end

    def open_transaction(parent_transaction : Lmdb::Transaction | Nil = nil, read_only = @read_only)
      read_write_flag = read_only ? LibLmdb::MDB_RDONLY : 0
      parent_transaction_handle = parent_transaction.try(&.handle)
      check_result LibLmdb.mdb_txn_begin(@handle, parent_transaction_handle, read_write_flag, out txn)
      Lmdb::Transaction.new(txn, read_only)
    end

    # yield a child transaction
    def with_transaction(parent_transaction : Lmdb::Transaction | Nil = nil, read_only = @read_only)
      txn = open_transaction(parent_transaction, read_only)
      begin
        yield txn
        txn.commit
      rescue ex
        txn.abort
        raise ex
      end
    end

    # this opens a top level transaction and yields the handle. Use for low level operations
    def with_transaction_handle(read_only = @read_only)
      read_write_flag = read_only ? LibLmdb::MDB_RDONLY : 0
      check_result LibLmdb.mdb_txn_begin(@handle, nil, read_write_flag, out txn_handle)
      begin
        yield txn_handle
        check_result LibLmdb.mdb_txn_commit(txn_handle)
      rescue ex
        LibLmdb.mdb_txn_abort(txn_handle)
        raise ex
      end
    end
  end
end
