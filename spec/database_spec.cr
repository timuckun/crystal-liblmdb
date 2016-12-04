require "./spec_helper"

describe Lmdb::Database do
  # This is the simplest possible way to use this library.
  # For more complex usage see the transaction_spec and cursor_spec files
  it "should have simple hash like behavior do" do
    env = Lmdb::Environment.new("dev/db", flags: Lmdb::Flags::Environment::NO_TLS)
    db = env.open_database
    db["Float"] = 1.5
    db["String"] = "This is a string"
    db["Int32"] = 555
    # updates data
    db["Int32"] = 32
    db["UInt64"] = 64_u64
    db["Float"].should eq(1.5)
    db["String"].should eq("This is a string")
    db["Int32"].should eq(32)
    db["UInt64"].should eq(64_u64)
    db.del("String")
    db["String"].should be_nil
    env.close
  end
end
