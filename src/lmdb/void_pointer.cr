module Lmdb
  class VoidPointer
    alias Classes = String.class | Int32.class | Int64.class | UInt32.class | UInt64.class | Float32.class | Float64.class | Nil.class
    alias Types = String | Int32 | Int64 | UInt32 | UInt64 | Float32 | Float64 | Nil

    getter item : Types
    getter size = 0
    getter pointer : Pointer(Void)
    @free = true

    def initialize(x : Types)
      @item = x
      @free = true
      case x # .class
      when String
        @size = x.bytesize.to_u64
        @pointer = x.to_unsafe.as(Void*)
        # I don't think this is supposed to be freed.
        @free = false
      when Int32, UInt32, Float32, Int64, UInt64, Float64
        @size = sizeof(typeof(x))
        @pointer = Pointer.malloc(@size, x).as(Void*)
        # when Int32, UInt32, Float32
        #   @size = 4_u64
        #
        #   @pointer = Pointer.malloc(4, x).as(Void*)
        # when Int64, UInt64, Float64
        #   @size = 8_u64
        #   @pointer = Pointer.malloc(8, x).as(Void*)
      when Nil
        @size = 0
        @pointer = uninitialized Pointer(Void)
      else
        raise "#{x} is not a valid type"
      end
    end

    def initialize
      # in some calls the the Clib does in-out params this will make it easier to
      # deal with those calls and keep the api consistent.
      @size = 0
      @pointer = uninitialized Pointer(Void)
      # Do we need to free an uninitialized pointer? Probably not
      @free = false
    end

    def initialize(@pointer : Pointer(Void), @size : Int32 | Int64 | UInt32 | UInt64)
      @free = false
    end

    def finalize
      LibC.free(@pointer) if @free
    end

    def to_ptr
      @pointer
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

    # NOTE: WARNING:  The code is for when you wanto to cast a void pointer
    #     the code doesn't know what kind of pointer was stored in the struct
    #     When you call this function you need to know what's in there
    def to(klass : Classes)
      case klass
      when String.class
        cptr = @pointer.as(Pointer(UInt8))
        String.new(cptr, @size)
      when Int32.class
        @pointer.as(Pointer(Int32)).value
      when Int64.class
        @pointer.as(Pointer(Int64)).value
      when UInt32.class
        @pointer.as(Pointer(UInt32)).value
      when UInt64.class
        @pointer.as(Pointer(UInt64)).value
      when Float32.class
        @pointer.as(Pointer(Float32)).value
      when Float64.class
        @pointer.as(Pointer(Float64)).value
      when Nil.class
        nil
      else
        raise "#{klass} is not a supported type"
      end
    end
  end
end
