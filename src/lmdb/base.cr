module Lmdb
  abstract class Base
    getter? success : Bool | Nil
    enum State
      Uninitialized
      Open
      Closed
    end
    property state = State::Uninitialized

    # def check_result(result : LibC::Int) : LibC::Int
    def check_result(result : Int32) : Int32
      # anything other than this is potentially an exception
      @success = (result == LibLmdb::MDB_SUCCESS)

      if result != 0
        errmsg = String.new(LibLmdb.mdb_strerror(result))
      end

      case result
      when LibLmdb::MDB_SUCCESS, LibLmdb::MDB_NOTFOUND
        # do nothing these are not considered to be errors
      when LibLmdb::MDB_KEYEXIST
        raise KeyExistsException.new(errmsg)
      when LibLmdb::MDB_PAGE_NOTFOUND
        raise PageNotFoundException.new(errmsg)
      when LibLmdb::MDB_CORRUPTED
        raise CorruptedException.new(errmsg)
      when LibLmdb::MDB_PANIC
        raise PanicException.new(errmsg)
      when LibLmdb::MDB_VERSION_MISMATCH
        raise VersionMismatchException.new(errmsg)
      when LibLmdb::MDB_INVALID
        raise InvalidException.new(errmsg)
      when LibLmdb::MDB_MAP_FULL
        raise MapFullException.new(errmsg)
      when LibLmdb::MDB_DBS_FULL
        raise DbsFullException.new("#{errmsg} : Please use a larger Environment(max_dbs=) parameter")
      when LibLmdb::MDB_READERS_FULL
        raise ReadersFullException.new("#{errmsg} Please use a larger Environment(max_readers=) parameter")
      when LibLmdb::MDB_TLS_FULL
        raise TlsFullException.new(errmsg)
      when LibLmdb::MDB_TXN_FULL
        raise TxnFullException.new("#{errmsg} Please do less work within your transaction")
      when LibLmdb::MDB_CURSOR_FULL
        raise CursorFullException.new(errmsg)
      when LibLmdb::MDB_PAGE_FULL
        raise PageFullException.new(errmsg)
      when LibLmdb::MDB_MAP_RESIZED
        raise MapResizedException.new(errmsg)
      when LibLmdb::MDB_INCOMPATIBLE
        raise IncompatibleException.new(errmsg)
      when LibLmdb::MDB_BAD_RSLOT
        raise BadRslotException.new(errmsg)
      when LibLmdb::MDB_BAD_TXN
        raise BadTxnException.new(errmsg)
      when LibLmdb::MDB_BAD_VALSIZE
        raise BadValsizeException.new(errmsg)
      when LibLmdb::MDB_BAD_DBI
        raise BadDbiException.new(errmsg)
      else
        raise UnexpectedLibLmdbException.new("Unexpected LibLmdb error : #{result}, #{errmsg}: PLEASE FILE A BUG REPORT SO A PROPER EXCEPTION CAN BE CODED")
      end

      result
    end

    def closed?
      @state.closed?
    end

    def open?
      @state.open?
    end

    def close
      @state = State::Closed
    end

    def to_key(x)
      size = nil
      pointer = uninitialized Pointer(Void)
      case x # .class
      when String
        size = x.bytesize.to_u64
        pointer = x.to_unsafe.as(Void*)
      when Int32, UInt32, Float32
        size = 4_u64
        pointer = Pointer.malloc(4, x).as(Void*)
      when Int64, UInt64, Float64
        size = 8_u64
        pointer = Pointer.malloc(8, x).as(Void*)
      end
      if size.nil?
        retval = uninitialized LibLmdb::MdbVal
      else
        retval = LibLmdb::MDB_val.new(
          mv_size: size,
          mv_data: pointer
        )
      end
    end

    def make_val(x : Lmdb::ValTypes) : LibLmdb::MDB_val
      val = case x # .class
            when String
              size = x.bytesize.to_u64
              pointer = x.to_unsafe.as(Void*)
              make_val(pointer, size)
            when Int32, UInt32, Float32
              size = 4_u64
              pointer = Pointer.malloc(4, x).as(Void*)
              make_val(pointer, size)
            when Int64, UInt64, Float64
              size = 8_u64
              pointer = Pointer.malloc(8, x).as(Void*)
              make_val(pointer, size)
            when Nil
              xx = uninitialized LibLmdb::MDB_val
            else
              xx = uninitialized LibLmdb::MDB_val
            end
      val
    end

    def make_mdb_val(ptr : Pointer(Void), size : Int)
      LibLmdb::MDB_val.new(
        mv_size: size,
        mv_data: ptr
      )
    end

    def convert_val(val : LibLmdb::MDB_val, klass : Lmdb::ValClasses)
      pointer = val.mv_data
      size = val.mv_size

      case klass
      when String.class
        cptr = pointer.as(Pointer(UInt8))
        String.new(cptr, size)
      when Int32.class
        pointer.as(Pointer(Int32)).value
      when Int64.class
        pointer.as(Pointer(Int64)).value
      when UInt32.class
        pointer.as(Pointer(UInt32)).value
      when UInt64.class
        pointer.as(Pointer(UInt64)).value
      when Float32.class
        pointer.as(Pointer(Float32)).value
      when Float64.class
        pointer.as(Pointer(Float64)).value
      when Nil.class
        nil
      else
        raise "#{klass} is not a supported type"
      end
    end

    def finalize
      close if @state.open?
    end
  end
end
#
# raise ReadonlyException.new(errmsg)
#
# #   #An attempt was made to modify a read-only database.#
# #  when LibLmdb::MDB_NAME = 'EACCES'
#
# raise InvalidParameterException.new(errmsg)
#
# #   #An invalid parameter was specified.#
# #  when LibLmdb::MDB_NAME = 'EINVAL'
#
# raise LockException.new(errmsg)
#
# #   #The environment was locked by another process.#
# #  when LibLmdb::MDB_NAME = 'EAGAIN'
#
# raise MemoryException.new(errmsg)
#
# #   #Out of memory.#
# #  when LibLmdb::MDB_NAME = 'ENOMEM'
#
# raise DiskException.new(errmsg)
#
# raise KeyExistsException.new(errmsg)
#
# #   #Key/data pair already exists.#
# #  when LibLmdb::MDB_NAME = 'MDB_KEYEXIST'
#
# raise NotFoundException.new(errmsg)
#
# #   #No matching key/data pair found.
# #
# #   Normally py-lmdb indicates a missing key by returning ``None``, or a
# #   user-supplied default value, however LMDB may return this error where
# #   py-lmdb does not know to convert it into a non-exceptional return.
# #   #
# #  when LibLmdb::MDB_NAME = 'MDB_NOTFOUND'
#
# raise PageNotFoundException.new(errmsg)
#
# #   #Request page not found.#
# #  when LibLmdb::MDB_NAME = 'MDB_PAGE_NOTFOUND'
#
# raise CorruptedException.new(errmsg)
#
# #   #Located page was of the wrong type.#
# #  when LibLmdb::MDB_NAME = 'MDB_CORRUPTED'
#
# raise PanicException.new(errmsg)
#
# #   #Update of meta page failed.#
# #  when LibLmdb::MDB_NAME = 'MDB_PANIC'
#
# raise VersionMismatchException.new(errmsg)
#
# #   #Database environment version mismatch.#
# #  when LibLmdb::MDB_NAME = 'MDB_VERSION_MISMATCH'
#
# raise InvalidException.new(errmsg)
#
# #   #File is not anwhen LibLmdb::MDB file.#
# #  when LibLmdb::MDB_NAME = 'MDB_INVALID'
#
# raise MapFullException.new(errmsg)
#
# #   #Environment map_size= limit reached.#
# #  when LibLmdb::MDB_NAME = 'MDB_MAP_FULL'
# #  when LibLmdb::MDB_HINT = 'Please use a larger Environment(map_size=) parameter'
#
# raise DbsFullException.new(errmsg)
#
# #   #Environment max_dbs= limit reached.#
# #  when LibLmdb::MDB_NAME = 'MDB_DBS_FULL'
# #  when LibLmdb::MDB_HINT = 'Please use a larger Environment(max_dbs=) parameter'
#
# raise ReadersFullException.new(errmsg)
#
# #   #Environment max_readers= limit reached.#
# #  when LibLmdb::MDB_NAME = 'MDB_READERS_FULL'
# #  when LibLmdb::MDB_HINT = 'Please use a larger Environment(max_readers=) parameter'
#
# raise TlsFullException.new(errmsg)
#
# #   #Thread-local storage keys full - too many environments open.#
# #  when LibLmdb::MDB_NAME = 'MDB_TLS_FULL'
#
# raise TxnFullException.new(errmsg)
#
# #   #Transaciton has too many dirty pages - transaction too big.#
# #  when LibLmdb::MDB_NAME = 'MDB_TXN_FULL'
# #  when LibLmdb::MDB_HINT = 'Please do less work within your transaction'
#
# raise CursorFullException.new(errmsg)
#
# #   #Internal error - cursor stack limit reached.#
# #  when LibLmdb::MDB_NAME = 'MDB_CURSOR_FULL'
#
# raise PageFullException.new(errmsg)
#
# #   #Internal error - page has no more space.#
# #  when LibLmdb::MDB_NAME = 'MDB_PAGE_FULL'
#
# raise MapResizedException.new(errmsg)
#
# #   #Database contents grew beyond environment map_size=.#
# #  when LibLmdb::MDB_NAME = 'MDB_MAP_RESIZED'
#
# raise IncompatibleException.new(errmsg)
#
# #   #Operation and DB incompatible, or DB flags changed.#
# #  when LibLmdb::MDB_NAME = 'MDB_INCOMPATIBLE'
#
# raise BadRslotException.new(errmsg)
#
# #   #Invalid reuse of reader locktable slot.#
# #  when LibLmdb::MDB_NAME = 'MDB_BAD_RSLOT'
#
# raise BadDbiException.new(errmsg)
#
# #   #The specified DBI was changed unexpectedly.#
# #  when LibLmdb::MDB_NAME = 'MDB_BAD_DBI'
#
# raise BadTxnException.new(errmsg)
#
# #   #Transaction cannot recover - it must be aborted.#
# #  when LibLmdb::MDB_NAME = 'MDB_BAD_TXN'
#
# raise BadValsizeException.new(errmsg)
#
# #   #Too big key/data, key is empty, or wrong DUPFIXED size.#
# #  when LibLmdb::MDB_NAME = 'MDB_BAD_VALSIZE'
#
# raise ReadonlyException.new(errmsg)
#
# #   #An attempt was made to modify a read-only database.#
# #  when LibLmdb::MDB_NAME = 'EACCES'
#
# raise InvalidParameterException.new(errmsg)
#
# #   #An invalid parameter was specified.#
# #  when LibLmdb::MDB_NAME = 'EINVAL'
#
# raise LockException.new(errmsg)
#
# #   #The environment was locked by another process.#
# #  when LibLmdb::MDB_NAME = 'EAGAIN'
#
# raise MemoryException.new(errmsg)
#
# #   #Out of memory.#
# #  when LibLmdb::MDB_NAME = 'ENOMEM'
#
# raise DiskException.new(errmsg)
#
# raise KeyExistsException.new(errmsg)
#
# #   #Key/data pair already exists.#
# #  when LibLmdb::MDB_NAME = 'MDB_KEYEXIST'
#
# raise NotFoundException.new(errmsg)
#
# #   #No matching key/data pair found.
# #
# #   Normally py-lmdb indicates a missing key by returning ``None``, or a
# #   user-supplied default value, however LMDB may return this error where
# #   py-lmdb does not know to convert it into a non-exceptional return.
# #   #
# #  when LibLmdb::MDB_NAME = 'MDB_NOTFOUND'
#
# raise PageNotFoundException.new(errmsg)
#
# #   #Request page not found.#
# #  when LibLmdb::MDB_NAME = 'MDB_PAGE_NOTFOUND'
#
# raise CorruptedException.new(errmsg)
#
# #   #Located page was of the wrong type.#
# #  when LibLmdb::MDB_NAME = 'MDB_CORRUPTED'
#
# raise PanicException.new(errmsg)
#
# #   #Update of meta page failed.#
# #  when LibLmdb::MDB_NAME = 'MDB_PANIC'
#
# raise VersionMismatchException.new(errmsg)
#
# #   #Database environment version mismatch.#
# #  when LibLmdb::MDB_NAME = 'MDB_VERSION_MISMATCH'
#
# raise InvalidException.new(errmsg)
#
# #   #File is not anwhen LibLmdb::MDB file.#
# #  when LibLmdb::MDB_NAME = 'MDB_INVALID'
#
# raise MapFullException.new(errmsg)
#
# #   #Environment map_size= limit reached.#
# #  when LibLmdb::MDB_NAME = 'MDB_MAP_FULL'
# #  when LibLmdb::MDB_HINT = 'Please use a larger Environment(map_size=) parameter'
#
# raise DbsFullException.new(errmsg)
#
# #   #Environment max_dbs= limit reached.#
# #  when LibLmdb::MDB_NAME = 'MDB_DBS_FULL'
# #  when LibLmdb::MDB_HINT = 'Please use a larger Environment(max_dbs=) parameter'
#
# raise ReadersFullException.new(errmsg)
#
# #   #Environment max_readers= limit reached.#
# #  when LibLmdb::MDB_NAME = 'MDB_READERS_FULL'
# #  when LibLmdb::MDB_HINT = 'Please use a larger Environment(max_readers=) parameter'
#
# raise TlsFullException.new(errmsg)
#
# #   #Thread-local storage keys full - too many environments open.#
# #  when LibLmdb::MDB_NAME = 'MDB_TLS_FULL'
#
# raise TxnFullException.new(errmsg)
#
# #   #Transaciton has too many dirty pages - transaction too big.#
# #  when LibLmdb::MDB_NAME = 'MDB_TXN_FULL'
# #  when LibLmdb::MDB_HINT = 'Please do less work within your transaction'
#
# raise CursorFullException.new(errmsg)
#
# #   #Internal error - cursor stack limit reached.#
# #  when LibLmdb::MDB_NAME = 'MDB_CURSOR_FULL'
#
# raise PageFullException.new(errmsg)
#
# #   #Internal error - page has no more space.#
# #  when LibLmdb::MDB_NAME = 'MDB_PAGE_FULL'
#
# raise MapResizedException.new(errmsg)
#
# #   #Database contents grew beyond environment map_size=.#
# #  when LibLmdb::MDB_NAME = 'MDB_MAP_RESIZED'
#
# raise IncompatibleException.new(errmsg)
#
# #   #Operation and DB incompatible, or DB flags changed.#
# #  when LibLmdb::MDB_NAME = 'MDB_INCOMPATIBLE'
#
# raise BadRslotException.new(errmsg)
#
# #   #Invalid reuse of reader locktable slot.#
# #  when LibLmdb::MDB_NAME = 'MDB_BAD_RSLOT'
#
# raise BadDbiException.new(errmsg)
#
# #   #The specified DBI was changed unexpectedly.#
# #  when LibLmdb::MDB_NAME = 'MDB_BAD_DBI'
#
# raise BadTxnException.new(errmsg)
#
# #   #Transaction cannot recover - it must be aborted.#
# #  when LibLmdb::MDB_NAME = 'MDB_BAD_TXN'
#
# raise BadValsizeException.new(errmsg)
#
# #   #Too big key/data, key is empty, or wrong DUPFIXED size.#
# #  when LibLmdb::MDB_NAME = 'MDB_BAD_VALSIZE'
#
# raise ReadonlyException.new(errmsg)
#
# #   #An attempt was made to modify a read-only database.#
# #  when LibLmdb::MDB_NAME = 'EACCES'
#
# raise InvalidParameterException.new(errmsg)
#
# #   #An invalid parameter was specified.#
# #  when LibLmdb::MDB_NAME = 'EINVAL'
#
# raise LockException.new(errmsg)
#
# #   #The environment was locked by another process.#
# #  when LibLmdb::MDB_NAME = 'EAGAIN'
#
# raise MemoryException.new(errmsg)
#
# #   #Out of memory.#
# #  when LibLmdb::MDB_NAME = 'ENOMEM'
#
# raise DiskException.new(errmsg)
