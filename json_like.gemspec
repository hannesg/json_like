require File.join(File.dirname(__FILE__), 'lib', 'json_like', 'version')
Gem::Specification.new do |gem|
  gem.name    = 'json_like'
  gem.version = JsonLike::VERSION
  gem.date    = Time.now.strftime("%Y-%m-%d")

  gem.summary = "human readable json matchers"

  gem.description = 'allows writing json matchers as simple json-like datastructures'

  gem.authors  = ['Hannes Georg']
  gem.email    = 'hannes.georg@googlemail.com'
  gem.homepage = 'https://github.com/hannesg/json_like'

  gem.files = Dir['lib/**/*'] & `git ls-files -z`.split("\0")

  gem.add_dependency 'multi_json'
  gem.add_dependency 'parslet'

  gem.add_development_dependency "cucumber"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "simplecov"
end
