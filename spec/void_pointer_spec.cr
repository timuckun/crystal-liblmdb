require "./spec_helper"

# def make_val(i : Int)
#   make_val_int(i)
# end
#
# def make_val_int(i : T) forall T
#   sizeof(typeof(i))
# end

describe "Round Trip" do
  context "convinience methods" do
    str = Lmdb::VoidPointer.new("string")

    str.to_s.should eq "string"
    i32 = Lmdb::VoidPointer.new(111)
    i32.to_i.should eq 111
    f32 = Lmdb::VoidPointer.new(1.5)
    f32.to_f.should eq 1.5
  end
  context "Custom methods" do
    u64 = Lmdb::VoidPointer.new(123_u64)
    u64.to(UInt64).should eq 123_u64
  end
  context "Unknown vals coming from db" do
    v = Lmdb::VoidPointer.new(1.23_f32)
    # the database would give us this data struct
    v2 = Lmdb::VoidPointer.new(v.pointer, v.size)
    v2.to(Float32).should eq 1.23_f32
  end
end
