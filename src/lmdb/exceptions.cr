module Lmdb
  class UnexpectedLibLmdbException < Exception
  end

  #   #Key/data pair already exists.#
  #  when LibLmdb::MDB_NAME = 'MDB_KEYEXIST'
  class KeyExistsException < Exception
  end

  #   #No matching key/data pair found.
  #
  #   Normally py-lmdb indicates a missing key by returning ``None``, or a
  #   user-supplied default value, however LMDB may return this error where
  #   py-lmdb does not know to convert it into a non-exceptional return.
  #   #
  #  when LibLmdb::MDB_NAME = 'MDB_NOTFOUND'
  class NotFoundException < Exception
  end

  #   #Request page not found.#
  #  when LibLmdb::MDB_NAME = 'MDB_PAGE_NOTFOUND'
  class PageNotFoundException < Exception
  end

  #   #Located page was of the wrong type.#
  #  when LibLmdb::MDB_NAME = 'MDB_CORRUPTED'
  class CorruptedException < Exception
  end

  #   #Update of meta page failed.#
  #  when LibLmdb::MDB_NAME = 'MDB_PANIC'
  class PanicException < Exception
  end

  #   #Database environment version mismatch.#
  #  when LibLmdb::MDB_NAME = 'MDB_VERSION_MISMATCH'
  class VersionMismatchException < Exception
  end

  #   #File is not anwhen LibLmdb::MDB file.#
  #  when LibLmdb::MDB_NAME = 'MDB_INVALID'
  class InvalidException < Exception
  end

  #   #Environment map_size= limit reached.#
  #  when LibLmdb::MDB_NAME = 'MDB_MAP_FULL'
  #  when LibLmdb::MDB_HINT = 'Please use a larger Environment(map_size=) parameter'
  class MapFullException < Exception
  end

  #   #Environment max_dbs= limit reached.#
  #  when LibLmdb::MDB_NAME = 'MDB_DBS_FULL'
  #  when LibLmdb::MDB_HINT = 'Please use a larger Environment(max_dbs=) parameter'
  class DbsFullException < Exception
  end

  #   #Environment max_readers= limit reached.#
  #  when LibLmdb::MDB_NAME = 'MDB_READERS_FULL'
  #  when LibLmdb::MDB_HINT = 'Please use a larger Environment(max_readers=) parameter'
  class ReadersFullException < Exception
  end

  #   #Thread-local storage keys full - too many environments open.#
  #  when LibLmdb::MDB_NAME = 'MDB_TLS_FULL'
  class TlsFullException < Exception
  end

  #   #Transaciton has too many dirty pages - transaction too big.#
  #  when LibLmdb::MDB_NAME = 'MDB_TXN_FULL'
  #  when LibLmdb::MDB_HINT = 'Please do less work within your transaction'
  class TxnFullException < Exception
  end

  #   #Internal error - cursor stack limit reached.#
  #  when LibLmdb::MDB_NAME = 'MDB_CURSOR_FULL'
  class CursorFullException < Exception
  end

  #   #Internal error - page has no more space.#
  #  when LibLmdb::MDB_NAME = 'MDB_PAGE_FULL'
  class PageFullException < Exception
  end

  #   #Database contents grew beyond environment map_size=.#
  #  when LibLmdb::MDB_NAME = 'MDB_MAP_RESIZED'
  class MapResizedException < Exception
  end

  #   #Operation and DB incompatible, or DB flags changed.#
  #  when LibLmdb::MDB_NAME = 'MDB_INCOMPATIBLE'
  class IncompatibleException < Exception
  end

  #   #Invalid reuse of reader locktable slot.#
  #  when LibLmdb::MDB_NAME = 'MDB_BAD_RSLOT'
  class BadRslotException < Exception
  end

  #   #The specified DBI was changed unexpectedly.#
  #  when LibLmdb::MDB_NAME = 'MDB_BAD_DBI'
  class BadDbiException < Exception
  end

  #   #Transaction cannot recover - it must be aborted.#
  #  when LibLmdb::MDB_NAME = 'MDB_BAD_TXN'
  class BadTxnException < Exception
  end

  #   #Too big key/data, key is empty, or wrong DUPFIXED size.#
  #  when LibLmdb::MDB_NAME = 'MDB_BAD_VALSIZE'
  class BadValsizeException < Exception
  end

  #   #An attempt was made to modify a read-only database.#
  #  when LibLmdb::MDB_NAME = 'EACCES'
  class ReadonlyException < Exception
  end

  #   #An invalid parameter was specified.#
  #  when LibLmdb::MDB_NAME = 'EINVAL'
  class InvalidParameterException < Exception
  end

  #   #The environment was locked by another process.#
  #  when LibLmdb::MDB_NAME = 'EAGAIN'
  class LockException < Exception
  end

  #   #Out of memory.#
  #  when LibLmdb::MDB_NAME = 'ENOMEM'
  class MemoryException < Exception
  end

  #     #No more disk space.#
  #    when LibLmdb::MDB_NAME = 'ENOSPC'
  class DiskException < Exception
  end

  #     case ENOENT:	/* 2, FILE_NOT_FOUND */
  # case EIO:		/* 5, ACCESS_DENIED */
  # case ENOMEM:	/* 12, INVALID_ACCESS */
  # case EACCES:	/* 13, INVALID_DATA */
  # case EBUSY:		/* 16, CURRENT_DIRECTORY */
  # case EINVAL:	/* 22, BAD_COMMAND */
  # case ENOSPC:	/* 28, OUT_OF_PAPER */

end
