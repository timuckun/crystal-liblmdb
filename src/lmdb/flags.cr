module Lmdb
  module Flags
    # These are all from the lmdb.h file

    @[Flags]
    enum Environment : UInt32
      # ##/**@defgroup	mdb_env	Environment Flags
      # *	@{
      # */
      # ##/**mmap at a fixed address (experimental) */
      FIXED_MAP = 0x01
      # #/**no environment directory */
      NO_SUBDIR = 0x4000
      # #/**don't fsync after commit */
      NO_SYNC = 0x10000
      # #/**read only */
      READ_ONLY = 0x20000
      # #/**don't fsync metapage after commit */
      NO_MET_ASYNC = 0x40000
      # #/**use writable mmap */
      WRITE_MAP = 0x80000
      # #/**use asynchronous msync when #MDB_WRITEMAP is used */
      MAP_ASYNC = 0x100000
      # #/**tie reader locktable slots to #MDB_txn objects instead of to threads */
      NO_TLS = 0x200000
      # #/**don't do any locking, caller must manage their own locks */
      NO_LOCK = 0x400000
      # #/**don't do readahead (no effect on Windows) */
      NO_READ_AHEAD = 0x800000
      # #/**don't initialize malloc'd memory before writing to datafile */
      NO_MEM_INIT = 0x1000000
      # #/**@} */
    end

    @[Flags]
    enum Database : UInt32
      # #  *		Keys are strings to be compared in reverse order, from the end
      #  *		of the strings to the beginning. By default, Keys are treated as strings and
      #  *		compared from beginning to end.
      REVERSE_KEY = 0x02
      #  *		Duplicate keys may be used in the database. (Or, from another perspective,
      #  *		keys may have multiple data items, stored in sorted order.) By default
      #  *		keys must be unique and may have only a single data item.
      DUP_SORT = 0x04
      #  *		Keys are binary integers in native byte order, either unsigned int
      #  *		or size_t, and will be sorted as such.
      #  *		The keys must all be of the same size.
      INTEGER_KEY = 0x08
      #  *		This flag may only be used in combination with #MDB_DUPSORT. This option
      #  *		tells the library that the data items for this database are all the same
      #  *		size, which allows further optimizations in storage and retrieval. When
      #  *		all data items are the same size, the #MDB_GET_MULTIPLE and #MDB_NEXT_MULTIPLE
      #  *		cursor operations may be used to retrieve multiple items at once.
      DUP_FIXED = 0x10
      #  *		This option specifies that duplicate data items are binary integers,
      #  *		similar to #MDB_INTEGERKEY keys.
      INTEGER_DUP = 0x20
      #  *		This option specifies that duplicate data items should be compared as
      #  *		strings in reverse order.
      REVERSE_DUP = 0x40
      #  *		Create the named database if it doesn't exist. This option is not
      #  *		allowed in a read-only transaction or a read-only environment.
      CREATE = 0x40000
      # #/**@} */
    end

    @[Flags]
    enum Put : UInt32
      #  *	<li>#MDB_CURRENT - replace the item at the current cursor position.
      #  *		The \b key parameter must still be provided, and must match it.
      #  *		If using sorted duplicates (#MDB_DUPSORT) the data item must still
      #  *		sort into the same place. This is intended to be used when the
      #  *		new data is the same size as the old. Otherwise it will simply
      #  *		perform a delete of the old record followed by an insert.
      #  *	<li>#MDB_NODUPDATA - enter the new key/data pair only if it does not
      #  *		already appear in the database. This flag may only be specified
      #  *		if the database was opened with #MDB_DUPSORT. The function will
      #  *		return #MDB_KEYEXIST if the key/data pair already appears in the
      #  *		database.
      #  *	<li>#MDB_NOOVERWRITE - enter the new key/data pair only if the key
      #  *		does not already appear in the database. The function will return
      #  *		#MDB_KEYEXIST if the key already appears in the database, even if
      #  *		the database supports duplicates (#MDB_DUPSORT).
      #  *	<li>#MDB_RESERVE - reserve space for data of the given size, but
      #  *		don't copy the given data. Instead, return a pointer to the
      #  *		reserved space, which the caller can fill in later - before
      #  *		the next update operation or the transaction ends. This saves
      #  *		an extra memcpy if the data is being generated later. This flag
      #  *		must not be specified if the database was opened with #MDB_DUPSORT.
      #  *	<li>#MDB_APPEND - append the given key/data pair to the end of the
      #  *		database. No key comparisons are performed. This option allows
      #  *		fast bulk loading when keys are already known to be in the
      #  *		correct order. Loading unsorted keys with this flag will cause
      #  *		a #MDB_KEYEXIST error.
      #  *	<li>#MDB_APPENDDUP - as above, but for sorted dup data.
      #  *	<li>#MDB_MULTIPLE - store multiple contiguous data elements in a
      #  *		single request. This flag may only be specified if the database
      #  *		was opened with #MDB_DUPFIXED. The \b data argument must be an
      #  *		array of two MDB_vals. The mv_size of the first MDB_val must be
      #  *		the size of a single data element. The mv_data of the first MDB_val
      #  *		must point to the beginning of the array of contiguous data elements.
      #  *		The mv_size of the second MDB_val must be the count of the number
      #  *		of data elements to store. On return this field will be set to
      #  *		the count of the number of elements actually written. The mv_data
      #  *		of the second MDB_val is unused.

      NO_OVERWRITE = LibLmdb::MDB_NOOVERWRITE
      NO_DUP_DATA  = LibLmdb::MDB_NODUPDATA
      CURRENT      = LibLmdb::MDB_CURRENT
      RESERVE      = LibLmdb::MDB_RESERVE
      APPEND       = LibLmdb::MDB_APPEND
      APPEND_DUP   = LibLmdb::MDB_APPENDDUP
      MULTIPLE     = LibLmdb::MDB_MULTIPLE
    end

    # #/**	@defgroup mdb_copy	Copy Flags
    # *	@{
    # */
    # #/**Compacting copy: Omit free space from copy, and renumber all
    # * pages sequentially.
    # */
    enum Copy
      COMPACT = 0x01
    end
  end
end
