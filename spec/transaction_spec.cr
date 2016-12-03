require "./spec_helper"

describe Lmdb::Transaction do
  it "puts and gets string indexed data" do
    env = Lmdb::Environment.new("dev/db", flags: Lmdb::Flags::Environment::NO_TLS)
    # open the default database
    db = env.open_database
    # clear the database
    db.empty
    txn = env.open_transaction

    # use different types of values
    txn.put(db, "String", "String")
    txn.get(db, "String").should eq "String"
    txn.put(db, "Int", 1)
    txn.get(db, "Int", Int32).should eq 1
    txn.put(db, "Float", 1.5)
    txn.get(db, "Float", Float64).should eq 1.5
    txn.get(db, "Non existent key").should be_nil
    txn.commit
    env.close
  end
  it "Transactions span databases" do
    env = Lmdb::Environment.new("dev/db", max_dbs: 10, flags: Lmdb::Flags::Environment::NO_TLS)
    # open up the default database for the data
    db = env.open_database
    db.empty
    # open up the index database for our data
    idx = env.open_database("transaction_test_index", Lmdb::Flags::Database.flags(CREATE, INTEGER_KEY, INTEGER_DUP))
    # integer keys are all u64 per the C lib
    env.with_transaction do |txn|
      txn.put(db, "id1", "score = 10")
      txn.put(idx, 10_u64, "id1")
      txn.put(db, "id2", "score = 10")
      txn.put(idx, 10_u64, "id2")
      txn.put(db, "id3", "score = 30")
      txn.put(idx, 30_u64, "id3")
      txn.put(db, "id4", "score = 40")
      txn.put(idx, 40_u64, "id4")
      txn.put(db, "id5", "score = 50")
      txn.put(idx, 50_u64, "id5")
      txn.put(db, "id6", "score = 60")
      txn.put(idx, 60_u64, "id6")
      txn.put(db, "id7", "score = 70")
      txn.put(idx, 70_u64, "id7")

      # let's re-index id2
      id2 = txn.get(db, "id2")
      id2.should eq "score = 10"
      pp txn.put(db, "id2", "score = 100")

      # since the index database can hold dupes we can't use get
      # because that would get the first record with the key
      # we have to open up a cursor to fetch the record with the right id.
      # See the cursor spec for how to use cursors
      txn.with_cursor(idx) do |cur|
        pp cur.find(10_u64, "id2")
        pp cur.del
        pp cur.put(100_u64, "id2")
      end
    end
    # # open a specific database with options
    # db = env.open_database("test_transactions_intkey", Lmdb::Flags::Database.flags(CREATE, INTEGER_KEY))
    # pp db.info
    # db.empty
    # txn = env.open_transaction
    # # s
    # # txn.put(db, 1_u64, 1)
    # # txn.put(db, 2_u64, 2)
    # # txn.put(db, 3_u64, 3)
    # #
    # # txn.get(db, 1_u64).to_i.should eq 1
    # # txn.get(db, 2_u64).to_i.should eq 2
    # # txn.get(db, 3_u64).to_i.should eq 3
    #
    # txn.commit
    # db.drop
    # env.close
  end
  it "deletes_data" do
    # env = Lmdb::Environment.new("dev/db", flags: Lmdb::Flags::Environment::NO_TLS)
    # # open the default database
    # db = env.open_database
    # # clear the database
    # db.empty
    # # txn = env.open_transaction
    # #
    # # txn.put(db, "1", "1")
    # # txn.del(db, "1")
    # # expect_raises(Lmdb::NotFoundException) do
    # #   txn.get(db, "1")
    # # end
    # # txn.commit
    # db.drop
    # env.close
  end
end