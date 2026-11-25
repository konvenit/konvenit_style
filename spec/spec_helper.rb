DeprecationWarningError = Class.new(StandardError)

module RaiseOnDeprecationWarning
  # Gems announce deprecations in plain warnings without a category, hence the match on the message.
  def warn(message, category: nil, **options)
    raise DeprecationWarningError, message if category == :deprecated || message.match?(/deprecat/i)

    super
  end
end

Warning[:deprecated] = true
Warning.singleton_class.prepend(RaiseOnDeprecationWarning)

require "konvenit_style/cops"
require "rubocop/rspec/support"

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense
  config.disable_monkey_patching!
  config.order = :random
end
