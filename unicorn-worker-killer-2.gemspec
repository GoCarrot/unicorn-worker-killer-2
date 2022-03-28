lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |s|
  s.name        = 'unicorn-worker-killer-2'
  s.version     = '1.0.1'
  s.authors     = ['Chris Elsworth']
  s.email       = ['chris@cae.me.uk']
  s.homepage    = 'https://github.com/celsworth/unicorn-worker-killer-2'
  s.summary     = 'Rewrite of unicorn-worker-kill'
  s.description = 'Kill Unicorn child processes when they exceed memory/request limits'

  s.files       = Dir.glob('lib/**/*')

  s.add_dependency 'get_process_mem', '~> 0'
  s.add_dependency 'unicorn',         '>= 4'
end
