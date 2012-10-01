
posts.should_be_kind_of ::Rmap::Table

row = posts.find_by_title("Test title 3")

row.should_be_kind_of ::Rmap::Row

row.id.should_equal(3)

posts.find_by_title("Test title 3 asdda").should_equal(nil)
