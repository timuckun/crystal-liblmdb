module Lmdb
  # this class is a way to manage the pointers to the MDB_val struct

  class MdbVal
    getter ptr : Pointer(LibLmdb::MDB_val)

    # I am not sure if this needs to be kept for the duration of the life of this object
    # I am keeping it alive just in case
    # @vptr = uninitialized VoidPointer
    def initialize(ptr : Pointer(Void), size : Int32 | Int64 | UInt32 | UInt64)
      @val = LibLmdb::MDB_val.new(
        mv_size: size.to_u64,
        mv_data: ptr
      )

      @ptr = pointerof(@val)
    end

    # def initialize(vptr : Lmdb::VoidPointer)
    #   initialize(vptr.pointer, vptr.size)
    # end

    def initialize(x : String)
      initialize x.to_unsafe.as(Void*), x.bytesize.to_u64
    end

    def initialize(x : Nil)
      @val = uninitialized LibLmdb::MDB_val
      @ptr = pointerof(@val)
    end

    def initialize(x : Lmdb::ValTypes)
      case x # .class
      when String
        @size = x.bytesize.to_u64
        @pointer = x.to_unsafe.as(Void*)
        # I don't think this is supposed to be freed.
        @free = false
      when Int32, UInt32, Float32
        @size = 4_u64
        @pointer = Pointer.malloc(4, x).as(Void*)
      when Int64, UInt64, Float64
        @size = 8_u64
        @pointer = Pointer.malloc(8, x).as(Void*)
      else
        @size = 0
        @pointer = uninitialized Pointer(Void)
      end
    end

    # def initialize(x : VoidPointer::Types)
    #   vptr = VoidPointer.new(x)
    #   initialize(vptr.pointer, vptr.size)
    # end

    def initialize(@val : LibLmdb::MDB_val)
      @ptr = pointerof(@val)
      # initialize(val.mv_data, val.mv_size)
    end

    def size
      @val.mv_size
    end

    def to_ptr
      @ptr
    end

    # convenience methods
    def to_s
      to(String)
    end

    def to_i
      to(Int32)
    end

    def to_f
      to(Float64)
    end

    # def to(klass : VoidPointer::Classes)
    #   v = VoidPointer.new(@val.mv_data, @val.mv_size)
    #   v.to(klass)
    # end

    # def to(klass : String.class)
    #   cptr = @pointer.as(Pointer(UInt8))
    #   String.new(cptr, @size)
    # end
    #
    # def to(klass : Nil.class)
    #   nil
    # end
    #
    # def to(klass : T.class) forall T # pp klass
    # # pp typeof(klass)
    #
    #
    #   @pointer.as(Pointer(T)).value
    # end

    # NOTE: WARNING:  The code is for when you wanto to cast a void pointer
    #     the code doesn't know what kind of pointer was stored in the struct
    #     When you call this function you need to know what's in there
    def to(klass : Lmdb::ValClasses)
      pointer = @val.mv_data
      size = @val.mv_size
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
      LibC.free(@ptr)
    end
  end
end

# def to_s
#   # I guess anything can be a represented as string
#   cptr = @val.mv_data.as(Pointer(UInt8))
#   String.new(cptr, @val.mv_size)
# end
#
# def to_i
#   # NOTE: We are coercing a point to be uint64. this is potentially dangerous
#   #      The caller should know what they are doing
#   #  raise "not an integer" unless @klass == :int
#   @val.mv_data.as(Pointer(UInt64)).value
# end
#
# def to_f
#   #  raise "not a float" unless @klass == :float
#   @val.mv_data.as(Float64*).value
# end

# def initialize(s : String)
#   #  @klass = :string
#   #  @item = s
#   @item = s
#   size = s.bytesize.to_u64
#   ptr = s.to_unsafe.as(Void*)
#   @val = make_struct(size, ptr)
# end

# def initialize(i : Int)
#   @item = i
#   size = 8_u64
#   #  @item = i.to_u64
#   #  @klass = :int
#   # this pointer has to be freed so we put it in an instance variable
#   @ptr = Pointer.malloc(8, i.to_u64).as(Void*)
#   # @ptr = pointerof(@item).as(Void*)
#   @val = make_struct(size, @ptr)
# end
#
# def initialize(f : Float)
#   @item = f
#   size = 8_u64
#   # @klass = :float
#   # this pointer has to be freed so we put it in an instance variable
#   # @item = f.to_f64
#   # @ptr = pointerof(@item).as(Void*)
#   @ptr = Pointer.malloc(8, f.to_f64).as(Void*)
#   @val = make_struct(size, @ptr)
# end
#
# def initialize(x : Nil)
#   @item = nil
#   # in some calls the the Clib does in-out params this will make it easier to
#   # deal with those calls and keep the api consistent.
#   #  @item = nil
#   @val = uninitialized LibLmdb::MDB_val
#
#   #  @klass = klass_to_sym(data_type)
# end
