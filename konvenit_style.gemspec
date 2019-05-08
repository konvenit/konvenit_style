lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "konvenit_style/version"

Gem::Specification.new do |spec|
  spec.name          = "konvenit_style"
  spec.version       = KonvenitStyle::VERSION
  spec.authors       = ["Michael Deimel"]
  spec.email         = ["m.deimel@miceportal.com"]

  spec.summary       = "A centralised store of the miceportal style rules"
  spec.description   = "Configuration files and other snippets to help you apply standards across multiple projects"
  spec.homepage      = "https://github.com/konvenit/konvenit_style"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rubocop", "~> 0.68.1"
  spec.add_dependency "rubocop-checkstyle_formatter"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
end
