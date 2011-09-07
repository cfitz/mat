#! /usr/bin/env ruby


# To start the application, use either rackup or ruby mat.rb

require 'rubygems'
require 'sinatra'
require 'repository'
require 'orbeon'
require 'config/environment'


use Rack::Auth::Basic, "Restricted Area" do |username, password|
  [username, password] == ['admin', 'admin']
end


get "/" do
  "<img src='images/mat.jpg' alt='Hi, I'm mat' />"  
end


# SEARCH
# POST  :  /search/mods/mclaughlin

post '/search/:application/:form' do
  content_type :xml
  repository = Stanford::Repository.new(DOR_URI, SOLR_URI )
  xml = request.body.read
  "#{repository.search(params[:application], params[:form], xml)}"
end

# CRUD
# =>    /crud/mods/mclaughlin/data/mat:test/data.xml
# GET : crud/mods/mclaughlin/data/cb77b5c1979db5797087055bf4b47a44/data.xml
# Gets XML out of Fedora 
get '/crud/:application/:form/data/:pid/data.xml' do 
   content_type :xml
   repository = Stanford::Repository.new(DOR_URI, SOLR_URI )
   "#{repository.get_datastream( params[:pid], 'descMetadata')}"
end

# PUT : /crud/mods/mclaughlin/data/cb77b5c1979db5797087055bf4b47a44/data.xml
# Replaces DS XML Content in Fedora
put '/crud/:application/:form/data/:pid/data.xml' do
   content_type :xml
   repository = Stanford::Repository.new(DOR_URI, SOLR_URI )
   "#{repository.put_datastream(params[:pid], 'descMetadata', request.body.read )}"
end

#### Orbeon Related #####
# Gets the default XML for a mods new object 
get '/orbeon/mods/:application/:form/:pid' do
  content_type :xml
  orbeon = Stanford::Orbeon.new(ORBEON_URI)
  "#{orbeon.get_mods_template(params[:application], params[:form], params[:pid])}"
end




