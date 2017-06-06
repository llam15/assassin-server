# Assassin::Server

![Travis CI](https://travis-ci.org/llam15/assassin-server.svg?branch=master)

GPS Assassins is a mobile-based multiplayer game that uses GPS to let players physically compete in this adaptation of tag. Every player receives a target to assassinate (and are similarly assigned to another player). As targets are taken out, players are reassigned to each other in the quickly dwindling pool. The last player standing wins.

Client side located at https://github.com/meeshic/assassin-client.

Completed for CS M117 during the Spring 2017 quarter at UCLA. 

Team: 

* [Breanna Nery](https://github.com/binerys)
* [Ky-Cuong Huynh](https://github.com/KyCodeHuynh)
* [Lauren Yeung](https://github.com/laurenyeung)
* [Leslie Lam](https://github.com/llam15)
* [Michelle Chang](https://github.com/meeshic)

TA: 

* [Reuben Vincent Rabsatt](http://web.cs.ucla.edu/~rrabsatt/)


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To start the server: 

```
rackup -p 4567
```

To watch for changes and automatically restart, run:

```
rerun "rackup -p 4567"
```


### Working with the Database

We use SQLite for development, so you'll want 
the [DB Browser for SQLite](http://sqlitebrowser.org/)
to view database contents. In production, we have yet
to choose between MySQL and PostgreSQL. Depending on which
database we choose, you'll want either [Sequel Pro](http://sequelpro.com/) 
or [PSequel](http://www.psequel.com/). If you're rusty on SQL syntax, 
[SQLBolt](https://sqlbolt.com/) is your friend.

Regardless of the database used,
[Active Record](http://guides.rubyonrails.org/active_record_basics.html) 
is our ORM (object-relational mapper) of choice.

* To set-up the local SQLite database files after cloning
    - `bundle exec db:create`
    - `bundle exec db:schema:load`
    - `bundle exec db:seed` (once we have a `seeds.rb` file)

* If you need to modify the database (add tables, change columns, etc.), then
  you'll need to write migrations
    - Here's the [Active Record guide on migrations](http://edgeguides.rubyonrails.org/active_record_migrations.html)
    - After you write the migration, SAVE FIRST, and then run 
      `bundle exec rake db:migrate` to run it, which will update 
      the `schema.rb`
    - [Our current migrations](https://github.com/llam15/assassin-server/tree/master/db/migrate) are good examples to follow

* If you need to link entities, e.g., a Game has many Players, then you're
  creating associations between models
    - Here's the accompanying [Active Record guide](http://guides.rubyonrails.org/association_basics.html)
    - As well as [a tutorial](https://learn.co/lessons/sinatra-activerecord-associations)
    - And this [example integration](https://github.com/llam15/assassin-server/blob/20e9fa52f4ba5bc2965ea292c850461ee4b1f125/lib/assassin/server.rb#L50) in our app


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/llam15/assassin-server. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

`assassin-server` is an open source project, with its code under the terms of the [MIT License](http://opensource.org/licenses/MIT).

