=begin
  * Name: superhash.rb
  * Description: A client application for grid search on parameters of lazar or other algorithms
  * Author: Andreas Maunz
  * Date: 09/2012
  * License: BSD
=end

class SuperHash < Hash
    def initialize
      super { |h, k| h[k] = SuperHash.new }
    end
end

