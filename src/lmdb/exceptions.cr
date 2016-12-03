module Lmdb
  class UnexpectedLibLmdbException < Exception
  end

  class KeyExistsException < Exception
  end

  #   #Key/data pair already exists.#
  #  when LibLmdb::MDB_NAME = 'MDB_KEYEXIST'

  class NotFoundException < Exception
  end

  #   #No matching key/data pair found.
  #
  #   Normally py-lmdb indicates a missing key by returning ``None``, or a
  #   user-supplied default value, however LMDB may return this error where
  #   py-lmdb does not know to convert it into a non-exceptional return.
  #   #
  #  when LibLmdb::MDB_NAME = 'MDB_NOTFOUND'

  class PageNotFoundException < Exception
  end

  #   #Request page not found.#
  #  when LibLmdb::MDB_NAME = 'MDB_PAGE_NOTFOUND'

  class CorruptedException < Exception
  end

  #   #Located page was of the wrong type.#
  #  when LibLmdb::MDB_NAME = 'MDB_CORRUPTED'

  class PanicException < Exception
  end

  #   #Update of meta page failed.#
  #  when LibLmdb::MDB_NAME = 'MDB_PANIC'

  class VersionMismatchException < Exception
  end

  #   #Database environment version mismatch.#
  #  when LibLmdb::MDB_NAME = 'MDB_VERSION_MISMATCH'

  class InvalidException < Exception
  end

  #   #File is not anwhen LibLmdb::MDB file.#
  #  when LibLmdb::MDB_NAME = 'MDB_INVALID'

  class MapFullException < Exception
  end

  #   #Environment map_size= limit reached.#
  #  when LibLmdb::MDB_NAME = 'MDB_MAP_FULL'
  #  when LibLmdb::MDB_HINT = 'Please use a larger Environment(map_size=) parameter'

  class DbsFullException < Exception
  end

  #   #Environment max_dbs= limit reached.#
  #  when LibLmdb::MDB_NAME = 'MDB_DBS_FULL'
  #  when LibLmdb::MDB_HINT = 'Please use a larger Environment(max_dbs=) parameter'

  class ReadersFullException < Exception
  end

  #   #Environment max_readers= limit reached.#
  #  when LibLmdb::MDB_NAME = 'MDB_READERS_FULL'
  #  when LibLmdb::MDB_HINT = 'Please use a larger Environment(max_readers=) parameter'

  class TlsFullException < Exception
  end

  #   #Thread-local storage keys full - too many environments open.#
  #  when LibLmdb::MDB_NAME = 'MDB_TLS_FULL'

  class TxnFullException < Exception
  end

  #   #Transaciton has too many dirty pages - transaction too big.#
  #  when LibLmdb::MDB_NAME = 'MDB_TXN_FULL'
  #  when LibLmdb::MDB_HINT = 'Please do less work within your transaction'

  class CursorFullException < Exception
  end

  #   #Internal error - cursor stack limit reached.#
  #  when LibLmdb::MDB_NAME = 'MDB_CURSOR_FULL'

  class PageFullException < Exception
  end

  #   #Internal error - page has no more space.#
  #  when LibLmdb::MDB_NAME = 'MDB_PAGE_FULL'

  class MapResizedException < Exception
  end

  #   #Database contents grew beyond environment map_size=.#
  #  when LibLmdb::MDB_NAME = 'MDB_MAP_RESIZED'

  class IncompatibleException < Exception
  end

  #   #Operation and DB incompatible, or DB flags changed.#
  #  when LibLmdb::MDB_NAME = 'MDB_INCOMPATIBLE'

  class BadRslotException < Exception
  end

  #   #Invalid reuse of reader locktable slot.#
  #  when LibLmdb::MDB_NAME = 'MDB_BAD_RSLOT'

  class BadDbiException < Exception
  end

  #   #The specified DBI was changed unexpectedly.#
  #  when LibLmdb::MDB_NAME = 'MDB_BAD_DBI'

  class BadTxnException < Exception
  end

  #   #Transaction cannot recover - it must be aborted.#
  #  when LibLmdb::MDB_NAME = 'MDB_BAD_TXN'

  class BadValsizeException < Exception
  end

  #   #Too big key/data, key is empty, or wrong DUPFIXED size.#
  #  when LibLmdb::MDB_NAME = 'MDB_BAD_VALSIZE'

  class ReadonlyException < Exception
  end

  #   #An attempt was made to modify a read-only database.#
  #  when LibLmdb::MDB_NAME = 'EACCES'

  class InvalidParameterException < Exception
  end

  #   #An invalid parameter was specified.#
  #  when LibLmdb::MDB_NAME = 'EINVAL'

  class LockException < Exception
  end

  #   #The environment was locked by another process.#
  #  when LibLmdb::MDB_NAME = 'EAGAIN'

  class MemoryException < Exception
  end

  #   #Out of memory.#
  #  when LibLmdb::MDB_NAME = 'ENOMEM'

  class DiskException < Exception
  end

  #     #No more disk space.#
  #    when LibLmdb::MDB_NAME = 'ENOSPC'
  #
  #     case ENOENT:	/* 2, FILE_NOT_FOUND */
  # case EIO:		/* 5, ACCESS_DENIED */
  # case ENOMEM:	/* 12, INVALID_ACCESS */
  # case EACCES:	/* 13, INVALID_DATA */
  # case EBUSY:		/* 16, CURRENT_DIRECTORY */
  # case EINVAL:	/* 22, BAD_COMMAND */
  # case ENOSPC:	/* 28, OUT_OF_PAPER */

end
