# frozen_string_literal: true

module Ea
  module Spa
    module Output
      autoload :Strategy, "ea/spa/output/strategy"
      autoload :SingleFileStrategy, "ea/spa/output/single_file_strategy"
      autoload :ShardedMultiFileStrategy, "ea/spa/output/sharded_multi_file_strategy"
    end
  end
end
