# -*-ruby-*-
require 'rubygems'
require 'bundler/setup'

require 'rake'
require 'rdoc/task'
require 'rubygems/package_task'

require 'rake/clean'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'

require 'jeweler'

task :default => [:cucumber, :spec]

desc "Run unit tests"
RSpec::Core::RakeTask.new do |t|
  t.pattern = Dir['spec/**/*_spec.rb']
end

desc "Run functional tests"
Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = %w{--color --format pretty}
end

desc 'Generate documentation for the mime-messgae gem.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = 'MIME::Message'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.md')
  rdoc.rdoc_files.include('lib/**/*.rb')
  rdoc.rdoc_files.exclude('features/**/*')
  rdoc.rdoc_files.exclude('spec/**/*')
end

Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification; see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name                  = "mime-message"
  gem.required_ruby_version = ">= 1.8.7"
  gem.homepage              = "https://github.com/xeger/mime-message"
  gem.license               = "MIT"
  gem.summary               = %Q{Library for composing and parsing MIME messages, including multipart.}
  gem.description           = %Q{Library for composing and parsing MIME messages, including multipart.}
  gem.email                 = "gemspec@tracker.xeger.net"
  gem.authors               = ['Tony Spataro']
  gem.files.exclude 'features/**/*'
  gem.files.exclude 'spec/**/*'
end

Jeweler::RubygemsDotOrgTasks.new

CLEAN.include('pkg')
