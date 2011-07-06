
require "rspec/core/rake_task"


namespace :rcov do

  desc  "Run all specs with rcov"
  RSpec::Core::RakeTask.new(:rspec_run) do |t|
    t.rcov = true
    t.rcov_opts = %w{--rails --exclude osx\/objc,gems\/,spec\/,features\/}
  end

  desc "Run only rspecs"
   task :rspec do |t|
     rm "coverage.data" if File.exist?("coverage.data")
     Rake::Task["rcov:rspec_run"].invoke
   end
   
end