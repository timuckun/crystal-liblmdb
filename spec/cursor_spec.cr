require "./spec_helper"

def with_cursor
  env = Lmdb::Environment.new("dev/db", max_dbs: 10, flags: Lmdb::Flags::Environment::NO_TLS)
  # pp env.info
  # # this database supports duplicate keys
  db = env.open_database("test_cursors", Lmdb::Flags::Database.flags(CREATE, DUP_SORT))
  # empty the database
  db.empty
  pp db.info
  # Transactions can span operations on different
  # databases but we are only going to use one for this test

  txn = env.open_transaction

  # let's populate some data
  txn.put(db, "1", "1")
  txn.put(db, "1", "1.1")
  txn.put(db, "1", "1.2")
  txn.put(db, "1", "1.3")
  txn.put(db, "2", "2")
  txn.put(db, "2.1", "2.1")
  txn.put(db, "2.2", "2.2")
  # txn.put(db, "data:string", "string")
  txn.put(db, "data:Integer", 1)
  txn.put(db, "data:Float", 1.5)
  # now open a cursor. A cursor is always attached to a database,
  # can't span databases
  #
  cur = txn.open_cursor(db)

  yield cur

  cur.close
  txn.commit
  db.drop
  env.close
end

describe Lmdb::Cursor do
  it "deals with empty database" do
    # # if you are going to be using named databases you have to specify max dbs which defaults to 0
    # env = Lmdb::Environment.new("dev/db", max_dbs: 10, flags: Lmdb::Flags::Environment::NO_TLS)
    # pp env.info
    # # this database supports duplicate keys
    # db = env.open_database("test_cursors", Lmdb::Flags::Database.flags(CREATE, DUP_SORT))
    # txn = env.open_transaction
    # cur = txn.open_cursor(db)
    # cur.first_dup
    # #
    # txn.commit
    # env.close
  end
  context "movement and fetching" do
    with_cursor do |cur|
      cur.first.should eq({true, "1", "1"})
      # The DUP calls don't return the key
      cur.next_dup.should eq({true, "1", "1.1"})
      cur.first_dup.should eq({true, "", "1"})
      cur.last_dup.should eq({true, "", "1.3"})

      # No dup ones do return keys
      # This goes to the next record with a different key
      cur.next_no_dup.should eq({true, "2", "2"})
      # opposite of the above
      cur.prev_no_dup.should eq({true, "1", "1.3"})

      # jump ahead a little
      cur.find("2.2").should eq({true, "2.2", "2.2"})
      # cast the results
      cur.next(Float64).should eq({true, "data:Float", 1.5})
      cur.next(Int32).should eq({true, "data:Integer", 1})
      # points out the importance of knowing your data,
      # We didn't specify a type
      # the code does not know that the record has an integer value so it dumps
      # the contents of the binary into a string full of gibberish
      cur.current.should eq({true, "data:Integer", "\u{1}\u{0}\u{0}\u{0}"})

      # Search for a specific key and value
      cur.find("1", "1.2").should eq({true, "1", "1.2"})
      cur.find("this key does not exist").should eq({false, "this key does not exist", nil})

      cur.last(Int32).should eq({true, "data:Integer", 1})
      # bouncing at the end without error
      cur.next.should eq({false, "", nil})
      # Finding the first key greater or equal to the specified one
      cur.find_ge(".").should eq({true, "1", "1"})
      # finding the record which has a particular value greater
      # or equal to the specified in a set of repeated duplicate keys
      cur.find_ge("1", "1.").should eq({true, "1", "1.1"})
      # put and delete records

      cur.put("New Record", "some_value").should eq({true, "New Record", "some_value"})
      # The put call puts the cursor on the newly inserted record
      # if it fails it lands `near` the location
      cur.del.should eq(true)
      # Delete all dupes of a key

      cur.put("New Record", "some_value")
      cur.put("New Record", "some_value1")
      cur.put("New Record", "some_value2")
      cur.put("New Record", "some_value3")
      cur.find("New Record")
      cur.count.should eq 4
      cur.del_all.should eq true
      cur.find("New Record").should eq({false, "New Record", nil})
    end
  end
end
