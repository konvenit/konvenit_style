require "konvenit_style/cops"
require "rubocop/rspec/support"

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense
  config.disable_monkey_patching!
  config.order = :random
end
