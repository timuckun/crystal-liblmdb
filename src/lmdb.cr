# require "./lmdb/*.cr"

require "./lmdb/lib_lmdb.cr"
# require "./lmdb/void_pointer.cr"
require "./lmdb/exceptions.cr"
# require "./lmdb/mdb_val.cr"
require "./lmdb/flags.cr"
require "./lmdb/base.cr"
require "./lmdb/cursor.cr"
require "./lmdb/transaction.cr"
require "./lmdb/database.cr"
require "./lmdb/environment.cr"

module Lmdb
  alias KeyClasses = String.class | UInt64.class | Nil.class
  alias ValClasses = String.class | Int32.class | Int64.class | UInt32.class | UInt64.class | Float32.class | Float64.class | Nil.class
  alias KeyTypes = String | UInt64 | Nil
  alias ValTypes = String | Int32 | Int64 | UInt32 | UInt64 | Float32 | Float64 | Nil
end
