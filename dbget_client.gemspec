# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
VERSION = '0.1.0'

Gem::Specification.new do |s|
  s.name        = "dbget_client"
  s.version     = VERSION
  s.authors     = ["Jan Mendoza"]
  s.email       = ["poymode@gmail.com"]
  s.homepage    = "https://github.com/poymode/dbget_client"
  s.summary     = %q{Client for dbget server}
  s.description = %q{Decrypts and uncompress MySQL and MongoDB backups from dbget server}

  s.rubyforge_project = "dbget_client"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
