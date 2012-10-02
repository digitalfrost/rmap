
table('posts').should_be_kind_of ::Rmap::Table

table(:posts).should_be_kind_of ::Rmap::Table

table('posts').name.should_equal('posts')

table(:posts).name.should_equal('posts')
