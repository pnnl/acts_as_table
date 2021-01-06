$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'acts_as_table/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'acts_as_table'
  s.version     = ActsAsTable::VERSION
  s.authors     = ['Mark Borkum']
  s.email       = ['mark.borkum@pnnl.gov']
  s.homepage    = 'https://github.com/pnnl/acts_as_table'
  s.metadata    = {
    'bug_tracker_uri' => 'https://github.com/pnnl/acts_as_table/issues',
    'source_code_uri' => 'https://github.com/pnnl/acts_as_table',
  }
  s.summary     = 'A Ruby on Rails plugin for working with tabular data.'
  s.description = 'ActsAsTable is a Ruby on Rails plugin for working with tabular data.'
  s.license     = 'BSD-3-Clause'

  s.files = Dir['.yardopts', '{app,config,db,lib}/**/*', 'LICENSE', 'Rakefile', 'README.md']

  s.add_runtime_dependency 'activerecord', '>= 4.2', '< 6.1'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'redcarpet'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'yard-activerecord'
  s.add_development_dependency 'yard-activesupport-concern'
  s.add_development_dependency 'yard-rails'
end
