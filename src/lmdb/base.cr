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

    # for keys this is just a no brainer
    def key_to_mdb_val(x : Lmdb::KeyTypes)
      make_mdb_val x
    end

    def data_to_mdb_val(x : Lmdb::ValTypes)
      # we don't encode type information into uninitialized pointers
      unless x.nil?
        class_id = get_class_id(x.class)
        val = make_mdb_val(x, extra_bytes: 1)
        # let's put the class id in the pointer data (last byte)
        val.mv_data.as(Pointer(UInt8))[val.mv_size] = class_id
        val.mv_size = val.mv_size + 1
        val
      else
        make_mdb_val(x)
      end
    end

    def make_mdb_val(x : Lmdb::ValTypes, extra_bytes = 0)
      # The extra byte is for type information metadata.
      # Can't be used for keys because they can integers
      # and they all have to be uniform size

      case x # .class
      when String
        size = x.bytesize.to_u64
        ptr = Pointer(UInt8).malloc(size + extra_bytes)
        # the extra byte is left empty
        ptr.copy_from(x.to_unsafe, size)
        pointer = ptr.as(Void*)
      when Bytes
        size = x.bytesize.to_u64
        ptr = Pointer(UInt8).malloc(size+extra_bytes)
        x.copy_to(ptr,x.size)
        pointer = ptr.as(Void*)
      when Int32, UInt32, Float32, Int64, UInt64, Float64
        size = sizeof(typeof(x))
        pointer = Pointer.malloc(size + extra_bytes, x).as(Void*)
      when Nil
        size = 0
        # ptr = Pointer(UInt8).malloc(size + extra_bytes).as(Void*)
        pointer = uninitialized Pointer(Void)
      else
        raise "#{x} is not a valid type"
      end

      make_mdb_val(pointer, size)
    end

    def make_mdb_val(ptr : Pointer(Void), size : Int)
      LibLmdb::MDB_val.new(
        mv_size: size.to_u64,
        mv_data: ptr
      )
    end

    def get_class_id(klass : Lmdb::ValClasses) : UInt8
      case klass
      when String.class
        0_u8
      when Int32.class
        1_u8
      when Int64.class
        2_u8
      when UInt32.class
        3_u8
      when UInt64.class
        4_u8
      when Float32.class
        5_u8
      when Float64.class
        6_u8
      when Nil.class
        7_u8
      when Bytes.class
        8_u8
      else
        raise "#{klass} is not a supported type"
      end
    end

    def lookup_class(id : Int)
      case id
      when 0
        String
      when 1
        Int32
      when 2
        Int64
      when 3
        UInt32
      when 4
        UInt64
      when 5
        Float32
      when 6
        Float64
      when 7
        Nil
      when 8
        Bytes
      else
        puts "#{id} is not a supported type"
      end
    end

    # basically just an alias but keeps the api consistent
    def mdb_val_to_key(val : LibLmdb::MDB_val, klass)
      mdb_val_to_data(val, klass)
    end

    def mdb_val_to_data(val : LibLmdb::MDB_val)
      return nil if val.mv_size == 0 && val.mv_data.value.nil?
      class_id = val.mv_data.as(Pointer(UInt8))[val.mv_size - 1]
      klass = lookup_class(class_id)
      val.mv_size = val.mv_size - 1
      mdb_val_to_data(val, klass)

      # pp klass = lookup_class(class_id)
    end

    def mdb_val_to_data(val : LibLmdb::MDB_val, klass)
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
