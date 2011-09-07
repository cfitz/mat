require File.dirname(__FILE__) + '/spec_helper'


describe Stanford::Orbeon do
  
  before(:each) do
    @repo =  Stanford::Orbeon.new(ORBEON_URI)
  end
  
  it "should initizlite correctly" do
    @repo.orbeon.should == ORBEON_URI
  end
  
  
  describe "#get_mods_template" do
    
    before(:all) do
      @time = Time.utc("Wed Sep 07 12:30:37 -0700 2011")  
      @desired_mods = Nokogiri::XML('<mods:mods xmlns:mods="http://www.loc.gov/mods/v3"><mods:identifier displayLabel="SU DRUID">a:druid</mods:identifier><mods:recordInfo><mods:recordCreationDate encoding="w3cdtf">2000-01-01T12:00:00-0800</mods:recordCreationDate></mods:recordInfo><mods:relatedItem type="host"><mods:recordInfo><mods:recordCreationDate>I SHOULD NOT CHANGE</mods:recordCreationDate></mods:recordInfo></mods:relatedItem></mods:mods>').to_xml   
    end
    
    before(:each) do
      Time.should_receive(:now).once.and_return(@time)
      
    end
    
    it "should add the druid and date" do
      mods = "<mods:mods xmlns:mods='http://www.loc.gov/mods/v3'><mods:identifier displayLabel='SU DRUID'>FOOBAR</mods:identifier><mods:recordInfo><mods:recordCreationDate encoding='w3cdtf'>BARFOO</mods:recordCreationDate></mods:recordInfo><mods:relatedItem type='host'><mods:recordInfo><mods:recordCreationDate>I SHOULD NOT CHANGE</mods:recordCreationDate></mods:recordInfo></mods:relatedItem></mods:mods>"
      RestClient.should_receive(:get).and_return(mods)
      res = @repo.get_mods_template("fooApp", "barForm", "a:druid" )
      res.should == @desired_mods
    end
    
    it "should add the mods:recordCreationDate if it doesnt exist" do
      mods = "<mods:mods xmlns:mods='http://www.loc.gov/mods/v3'><mods:identifier displayLabel='SU DRUID'>FOOBAR</mods:identifier><mods:recordInfo></mods:recordInfo><mods:relatedItem type='host'><mods:recordInfo><mods:recordCreationDate>I SHOULD NOT CHANGE</mods:recordCreationDate></mods:recordInfo></mods:relatedItem></mods:mods>"
      RestClient.should_receive(:get).and_return(mods)
      res = @repo.get_mods_template("fooApp", "barForm", "a:druid" )
      res.should == @desired_mods
    end 
  
    it "should add the recordInfo block if it doesnt exist" do
      mods = "<mods:mods xmlns:mods='http://www.loc.gov/mods/v3'><mods:identifier displayLabel='SU DRUID'>FOOBAR</mods:identifier><mods:relatedItem type='host'><mods:recordInfo><mods:recordCreationDate>I SHOULD NOT CHANGE</mods:recordCreationDate></mods:recordInfo></mods:relatedItem></mods:mods>"
      #slight change in node order
      @recordInfo_desired_mods = Nokogiri::XML('<mods:mods xmlns:mods="http://www.loc.gov/mods/v3"><mods:identifier displayLabel="SU DRUID">a:druid</mods:identifier><mods:relatedItem type="host"><mods:recordInfo><mods:recordCreationDate>I SHOULD NOT CHANGE</mods:recordCreationDate></mods:recordInfo></mods:relatedItem><mods:recordInfo><mods:recordCreationDate encoding="w3cdtf">2000-01-01T12:00:00-0800</mods:recordCreationDate></mods:recordInfo></mods:mods>').to_xml
      RestClient.should_receive(:get).and_return(mods)
      res = @repo.get_mods_template("fooApp", "barForm", "a:druid" )
      res.should == @recordInfo_desired_mods      
    end
    
    
  end  
  
  
  
end