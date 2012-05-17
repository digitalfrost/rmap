
module Rmap
  class Migration
    
    attr_accessor :up_block, :down_block
    
    def initialize(file_path)
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
