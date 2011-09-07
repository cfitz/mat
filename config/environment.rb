require "rubygems"
require "bundler"
Bundler.setup

require 'sinatra'



configure :production do
  DOR_URI = 'http://fedoraAdmin:fedoraAdmin@dor-dev.stanford.edu/fedora/'
  SOLR_URI= 'http://dor-dev.stanford.edu/solr/'
  ORBEON_URI = 'https://mdtoolkit.stanford.edu/ops'
end

configure :development do
  DOR_URI = 'http://fedoraAdmin:fedoraAdmin@dor-dev.stanford.edu/fedora/'
  SOLR_URI= 'http://dor-dev.stanford.edu/solr/'
  ORBEON_URI = 'http://lyberapps-dev.stanford.edu/orbeon/'
end

configure :test do
  DOR_URI = 'http://fedoraAdmin:fedoraAdmin@dor-dev.stanford.edu/fedora/'
  SOLR_URI= 'http://dor-dev.stanford.edu/solr/'
  ORBEON_URI = 'https://mdtoolkit.stanford.edu/orbeon'
end

