require_relative './lib/version'

Gem::Specification.new do |spec|
    spec.name        = 'xprint'
    spec.version     = XPrint::VERSION
    spec.authors     = ['JCabr']
    spec.email       = ['jcabr.dev@gmail.com']
    spec.summary     = 'Gem for pretty printing any kind of object.'
    spec.description = "
    Gem that allows for pretty printing data over multiple lines and with
    indentation, and works with objects as well as basic data types.

    Also allows color, and loading settings via a YAML config file.
    ".split.join(' ')
    spec.homepage    = 'https://github.com/JCabr/xprint.rb'
    spec.license     = 'MIT'
    spec.files       = Dir['lib/**/*.rb']
    spec.require_path = 'lib'
end