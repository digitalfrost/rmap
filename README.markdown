
# Rmap - a simple yet powerfull object relational mapper

##Installation

```
gem install rmap
```
or add the following to your gem file:

```
gem 'rmap'
```
and then run bundle install from your shell.

##Basic configuration

```ruby
require 'rmap'

db = Rmap::Database.new :database => 'rmap', :username => 'root'
```
You can get more configuration options by going to the mysql2 gem documentation, as rmap wraps the mysql2 gem and simply passes through the conf hash to it:

* https://github.com/brianmario/mysql2

For instance a more advanced configuration might be:

```ruby
require 'rmap'

db = Rmap::Database.new :database => 'rmap', :host => 'localhost', :username => 'root', :password => "secret"
```

## How to use

The following will return a representation of the 'posts' table:

```ruby
db.posts
```
### Creating

You can insert rows into the posts table by doing the following:

```ruby
db.posts.insert(:title => "Hello World", :body => "This is a test")
```

### Retrieval

You can list all the posts by doing the following:

```ruby
db.posts.all.each do |post|
  puts "title #{post.title}"
end
```

You can list all the posts that contain the word apple by doing the following:

```ruby
db.posts.contains(:body, "apple").all.each do |post|
  puts "title #{post.title}"
end
```

You can list all the posts that contain the word apple or pear by doing the following:

```ruby
db.posts.contains(:body, ["apple", "pear"]).all.each do |post|
  puts "title #{post.title}"
end
```

You can retrieve a particular post (row) by doing the following:

```ruby
db.posts.eq(:id, 7).first
```

and then you can print the title to the screen:

```ruby
puts db.posts.eq(:id, 7).first.title
```

### Joins

Joins are really easy. To retrieve all the posts by gmail users, you can do the following:

```ruby
db.users.contains(:email, "@gmail.com").posts.all
```

### Deleting

You can delete all the posts by gmail users by doing the following:

```ruby
db.users.contains(:email, "@gmail.com").posts.delete
```

### Updating

You can update all the posts by gmail users by doing the following:

```ruby
db.users.contains(:email, "@gmail.com").posts.update(:published => true, :last_published => Time.now)
```

or if you just want to update a column:

```ruby
db.users.contains(:email, "@gmail.com").posts.published = true
```

more coming soon....

## License

Rmap is released under the MIT license:

* http://www.opensource.org/licenses/MIT
