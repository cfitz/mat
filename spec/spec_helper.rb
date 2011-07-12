require File.join(File.dirname(__FILE__), '..', 'mat.rb')

require 'rubygems'
require 'sinatra'
require 'rack/test'
require 'rspec'
require 'equivalent-xml'
require 'equivalent-xml/rspec_matchers'
require 'fakeweb'


# set test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

