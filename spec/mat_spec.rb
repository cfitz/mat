require File.dirname(__FILE__) + '/spec_helper'

describe "MAT" do
  include Rack::Test::Methods

  def app
    @app ||= Sinatra::Application
  end

  it "should respond to /" do
    get '/'
    last_response.body.should ==  "<img src='images/mat.jpg' alt='Hi, I'm mat' />"  
    last_response.should be_ok
  end
  
  #'/search/:application/:form'
  it "should return the proper XML when searched " do
    post  '/search/mods/mclaughlin',  "<xml/>"
    Nokogiri::XML(last_response.body).root.should be_equivalent_to(Nokogiri::XML(open("spec/fixtures/solrResultsAll.xml")).root)
    last_response.should be_ok    
  end
  
  #'/crud/:application/:form/data/:pid/data.xml'
  it "should return the MODS xml for a specific druid" do
    get '/crud/mods/mods/data/bb110sm8219/data.xml'
    last_response.should be_ok 
    Nokogiri::XML(last_response.body).root.should be_equivalent_to(Nokogiri::XML(open("spec/fixtures/descMetadata.xml")).root)
  end
  
  
end
