
module Rmap
  class Migration
    
    attr_accessor :schema_version, :up_block, :down_block
    
    def initialize(file_path)
      @schema_version = file_path.sub(/\A.*?(\d+)[^\/]*\Z/, "\\1").to_i
      instance_eval(::File.open(file_path).read, file_path)
    end
    
    def up(&block)
      @up_block = block
    end
    
    def down(&block)
      @down_block = block
    end
    
  end
end
