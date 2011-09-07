require File.dirname(__FILE__) + '/spec_helper'


describe "MAT" do
  include Rack::Test::Methods

 
  def app
    @app ||= Sinatra::Application
  end
  
  describe "homepage" do
    it "should respond to /" do
       authorize 'admin', 'admin'
       get '/'
       last_response.body.should ==  "<img src='images/mat.jpg' alt='Hi, I'm mat' />"  
       last_response.should be_ok
     end
    
  end
  
  describe "search" do
    before(:each) do
       @repo = mock(Stanford::Repository)
       Stanford::Repository.should_receive(:new).with(DOR_URI, SOLR_URI).and_return(@repo)
     end
  
    #'/search/:application/:form'
    #"#{repository.search(params[:application], params[:form], xml)}"
    it "should return the proper XML when searched " do
      @repo.should_receive(:search).with("mods", "mclaughlin", "<xml/>")
      authorize 'admin', 'admin'
      post  '/search/mods/mclaughlin',  "<xml/>"
      last_response.should be_ok    
    end
    
  end
  
  describe "get mods" do
    before(:each) do
       @repo = mock(Stanford::Repository)
       Stanford::Repository.should_receive(:new).with(DOR_URI, SOLR_URI).and_return(@repo)
     end
     
    #'/crud/:application/:form/data/:pid/data.xml'
    it "should return the MODS xml for a specific druid" do
      @repo.should_receive(:get_datastream).with("bb110sm8219", "descMetadata")
      authorize 'admin', 'admin'
      get '/crud/mods/mods/data/bb110sm8219/data.xml'
      last_response.should be_ok 
    end
    
  end
  
  describe "replace mods" do 
    before(:each) do
       @repo = mock(Stanford::Repository)
       Stanford::Repository.should_receive(:new).with(DOR_URI, SOLR_URI).and_return(@repo)
     end
  
    it "should update the XML for a MODS ds" do
      @repo.should_receive(:put_datastream).with("bb110sm8219", "descMetadata", "<xml/>")
      
      authorize 'admin', 'admin'
      put '/crud/mods/mods/data/bb110sm8219/data.xml', "<xml/>"
      last_response.should be_ok  
    end
    
  end
  
  
  describe "get mods template" do
    before(:each) do 
      @orbeon = mock(Stanford::Orbeon)
      Stanford::Orbeon.should_receive(:new).with(ORBEON_URI).and_return(@orbeon)
    end
    
    it "should get the XML template for a new object" do
      #"#{orbeon.get_mods_template(params[:application], params[:form], params[:pid])}"
      @orbeon.should_receive(:get_mods_template).with("fooApp", "barForm", "a:druid").and_return("<mods:mods/>")
      authorize 'admin', 'admin'
      get "/orbeon/mods/fooApp/barForm/a:druid"
      last_response.should be_ok  
      
    end
  end
    
  
end
