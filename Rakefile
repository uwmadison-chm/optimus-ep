require 'rake'
require 'spec/rake/spectask'
require 'config/requirements'
require 'config/hoe' # setup Hoe + all gem configuration

Dir['tasks/**/*.rake'].each { |rake| load rake }

desc "Run specs"
Spec::Rake::SpecTask.new('default') do |t|
  t.spec_files = FileList['spec/**/*.rb']
end
