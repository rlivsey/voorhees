# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{voorhees}
  s.version = "0.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Richard Livsey"]
  s.date = %q{2009-06-21}
  s.email = %q{richard@livsey.org}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.markdown"
  ]
  s.files = [
    ".gitignore",
     "LICENSE",
     "README.markdown",
     "Rakefile",
     "VERSION",
     "examples/twitter.rb",
     "lib/voorhees.rb",
     "lib/voorhees/config.rb",
     "lib/voorhees/exceptions.rb",
     "lib/voorhees/request.rb",
     "lib/voorhees/resource.rb",
     "lib/voorhees/response.rb",
     "spec/config_spec.rb",
     "spec/fixtures/resources.rb",
     "spec/fixtures/user.json",
     "spec/fixtures/users.json",
     "spec/request_spec.rb",
     "spec/resource_spec.rb",
     "spec/response_spec.rb",
     "spec/spec_helper.rb",
     "spec/voorhees_spec.rb",
     "voorhees.gemspec"
  ]
  s.homepage = %q{http://github.com/rlivsey/voorhees}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.3}
  s.summary = %q{Library to consume and interract with JSON services}
  s.test_files = [
    "spec/config_spec.rb",
     "spec/fixtures/resources.rb",
     "spec/request_spec.rb",
     "spec/resource_spec.rb",
     "spec/response_spec.rb",
     "spec/spec_helper.rb",
     "spec/voorhees_spec.rb",
     "examples/twitter.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
