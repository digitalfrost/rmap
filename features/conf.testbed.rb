
load  File.expand_path("../../rmap.gemspec", __FILE__)

require 'rmap'

create do
  if ::Rmap::Database::exists?('rmap_test')
    ::Rmap::Database::drop('rmap_test')
  end
  ::Rmap::Database::create('rmap_test')
end

set_up do
  posts.add :title, :string
  posts.add :body, :text
  
  (1..10).each do |i|
    posts.insert({:title  => "Test title #{i}", :body => "Test body #{i}"})
  end
  
end

tear_down do
  ::Rmap::Database::drop('rmap_test')
end
