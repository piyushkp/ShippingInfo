# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "rake"

Gem::Specification.new do |s|
  s.name        = "ShippingInfo"
  s.version     = 1.0
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Piyush Patel"]
  s.email       = ["er.piyushpatel@gmail.com"]
  s.homepage    = "http://rubygems.org/gems/shippinginfo"
  s.summary     = %q{Shipping Info Services}
  s.description = %q{Provides an interface to get shipping rates and transit time for Fedex, UPS, and USPS}

  s.rubyforge_project = "ShippingInfo"

  s.add_dependency 'httparty',            '~> 0.8.0'
  s.add_dependency 'nokogiri',            '~> 1.5.0'

  s.add_development_dependency "rspec",   '~> 2.9.0'
  s.add_development_dependency 'vcr',     '~> 2.0.0'
  s.add_development_dependency 'fakeweb'
  # s.add_runtime_dependency "rest-client"

  s.files         = FileList[ "lib/**/*" ]
  s.test_files    = [ ]
  s.executables   = [ ]
  s.require_paths = ["lib"]


end
