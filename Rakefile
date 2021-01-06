begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

require 'yard'

YARD::Rake::YardocTask.new do |t|
  t.files = ['{app,lib}/**/*.rb']
end
