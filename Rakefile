require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/editalign'

Hoe.plugin :newgem

$hoe = Hoe.spec 'editalign' do
  self.developer 'W.P. McNeill', 'billmcn@gmail.com'
  self.rubyforge_name = self.name # TODO this is default value
end

require 'newgem/tasks'
Dir['tasks/**/*.rake'].each { |t| load t }
