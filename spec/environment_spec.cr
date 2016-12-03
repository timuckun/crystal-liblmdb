require "./spec_helper"

describe Lmdb::Environment do
  it "should do run the typical scenario" do
    env = Lmdb::Environment.new("dev/db", flags: Lmdb::Flags::Environment::NO_TLS)
    db = env.open_database
    txn = env.open_transaction
    txn.commit
    env.close
  end
end
