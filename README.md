# lmdb

Crystal bindings for the LMDB database by Symas.  It covers most but not all of the library functionality.

TODO:

1. Make better use of read only transactions by reusing them
2. Write specs for child transactions
3. Implement callback functions
4. Enhance the database API to implement more enumerable like functionality



## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  lmdb:
    github: timuckun/crystal-liblmdb
```


## Usage


```crystal
require "lmdb"
```


Please see the specs for how to use this library, especially
transaction_spec and cursor_spec. The database_spec shows how to use it in the simplest form possible

## Development

Pull requests are always welcome

## Contributing

1. Fork it ( https://github.com/timuckun/crystal-liblmdb/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [Tim Uckun](https://github.com/timuckun Tim Uckun - creator, maintainer
- A massive debt of gratitude to the Crystal dev team for answering all the questions on the mailing list. This could not have happened without their help.
