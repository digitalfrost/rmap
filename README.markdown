
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
You can get more configuration options by going to the mysql2 gem documentation, as rmap wraps the mysql2 gem and simple passes through conf hash to it:

* https://github.com/brianmario/mysql2

## How to use

```ruby
row = db.posts.first
```
