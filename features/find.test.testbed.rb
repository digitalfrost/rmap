
posts.should_be_kind_of ::Rmap::Table

posts.should_have_method :find

posts.find(1).should_be_kind_of ::Rmap::Row

posts.find(1).id.should_equal(1)

posts.find(3423434).should_equal(nil)

row = posts.find(:title => "Test title 5")

row.id.should_equal(5)
