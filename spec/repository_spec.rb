require File.dirname(__FILE__) + '/spec_helper'


describe Stanford::Repository do
  
  before(:each) do
    @repo =  Stanford::Repository.new(DOR_URI, SOLR_URI)
  end
  
  it "should initizlite correctly" do
    @repo.fedora.should == DOR_URI
    @repo.solr.uri.to_s.chop.should == SOLR_URI #rsolr adds / to the end
  end
  
  describe "#get_datastream" do
    #uri = URI.parse(@fedora + '/objects/' + pid + '/datastreams/' + dsID + '/content') 
    it "should get the datastream XML for an object" do
      FakeWeb.register_uri(:get, "#{DOR_URI}/objects/druid:666/datastreams/descMetadata/content", :body => "<someXML/>")
      xml = @repo.get_datastream("druid:666", "descMetadata")
      xml.should == "<someXML/>"
    end
    
    it "should return an error if the xml is not found" do 
       @repo.get_datastream("druid:668", "descMetadata").code.should == 404
    end
   
  end
  
  describe "#put_datastream" do
    #uri = URI.parse(@fedora + '/objects/' + pid + '/datastreams/' + dsID ) 
    it "should replace the datastream XML for an object" do
        FakeWeb.register_uri(:any, "#{DOR_URI}/objects/druid:666/datastreams/descMetadata", :status => ["200", "OK"])
        res = @repo.put_datastream("druid:666", "descMetadata", "<someXML/>")
        res.code.should == 200
    end
    
    it "should return an error if the datastream was not replaced" do
      res = @repo.put_datastream("druid:668", "descMetadata", "<someXML/>").code.should == 404      
    end
    
  end
  
  #this is a little complicated but hopefully this shows how the query is supposed to be handled. 
  describe "#search" do
    
    it "should submit a query to SOLR correctly without a fulltext query" do
       xml = '<search xmlns:mods="http://www.loc.gov/mods/v3" xmlns:f="http://orbeon.org/oxf/xml/formatting" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xxi="http://orbeon.org/oxf/xml/xinclude" xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xbl="http://www.w3.org/ns/xbl" xmlns:exforms="http://www.exforms.org/exf/1-0" xmlns:pipeline="java:org.orbeon.oxf.processor.pipeline.PipelineFunctionLibrary" xmlns:fr="http://orbeon.org/oxf/xml/form-runner" xmlns:xxforms="http://orbeon.org/oxf/xml/xforms" xmlns:widget="http://orbeon.org/oxf/xml/widget">
                          <query/>
                <query name="mods_book_number_identifier_field" path="mods_book_number_identifier_field" label="Entry Number" type="" control="input" search-field="true" match="substring"/>
                 <query name="mods_titleInfo_field" path="mods_titleInfo_field" label="Title" type="" control="input" search-field="true" match="substring"/>
                 <query name="mods_name_field" path="mods_name_field" label="Name" type="" control="input" search-field="true" match="substring"/>
                          <page-size>666</page-size>
                          <page-number>11</page-number>
                      </search>'
       @repo.solr.should_receive(:paginate).with(11, 666, "select",  {:params=>{:fq=>["mdform_tag_field:barForm"], :fl=>["*"], :qt=>"dismax"}}).and_return({:response => [ :num_found => 49,  :docs => ["our solr docs would be here"] ]})
       @repo.should_receive(:build_results).with({:response=>[{:num_found=>49, :docs=>["our solr docs would be here"]}], "page"=>"11", "queries"=>["mods_book_number_identifier_field", "mods_titleInfo_field", "mods_name_field"], "page_size"=>"666"})                    
       @repo.search("fooApp", "barForm", xml)
      
    end
    
    it "should sumbit a query to SOLR correclt without fulltext or page information" do
      xml = '<search xmlns:mods="http://www.loc.gov/mods/v3" xmlns:f="http://orbeon.org/oxf/xml/formatting" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xxi="http://orbeon.org/oxf/xml/xinclude" xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xbl="http://www.w3.org/ns/xbl" xmlns:exforms="http://www.exforms.org/exf/1-0" xmlns:pipeline="java:org.orbeon.oxf.processor.pipeline.PipelineFunctionLibrary" xmlns:fr="http://orbeon.org/oxf/xml/form-runner" xmlns:xxforms="http://orbeon.org/oxf/xml/xforms" xmlns:widget="http://orbeon.org/oxf/xml/widget">
                         <query/>
               <query name="mods_book_number_identifier_field" path="mods_book_number_identifier_field" label="Entry Number" type="" control="input" search-field="true" match="substring"/>
                <query name="mods_titleInfo_field" path="mods_titleInfo_field" label="Title" type="" control="input" search-field="true" match="substring"/>
                <query name="mods_name_field" path="mods_name_field" label="Name" type="" control="input" search-field="true" match="substring"/>
                         <page-size></page-size>
                         <page-number></page-number>
                     </search>'
              @repo.solr.should_receive(:paginate).with(1, 25, "select",  {:params=>{:fq=>["mdform_tag_field:barForm"], :fl=>["*"], :qt=>"dismax"}}).and_return({:response => [ :num_found => 55,  :docs => ["our solr docs would be here"] ]})
              @repo.should_receive(:build_results).with({:response=>[{:num_found=>55, :docs=>["our solr docs would be here"]}], "page"=>"1", "queries"=>["mods_book_number_identifier_field", "mods_titleInfo_field", "mods_name_field"], "page_size"=>"25"})                    
              @repo.search("fooApp", "barForm", xml)
       
    end
    
    it "should sumbit a query to SOLR correclt without fulltext or page information but with a fielded query" do
      xml = '<search xmlns:mods="http://www.loc.gov/mods/v3" xmlns:f="http://orbeon.org/oxf/xml/formatting" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xxi="http://orbeon.org/oxf/xml/xinclude" xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xbl="http://www.w3.org/ns/xbl" xmlns:exforms="http://www.exforms.org/exf/1-0" xmlns:pipeline="java:org.orbeon.oxf.processor.pipeline.PipelineFunctionLibrary" xmlns:fr="http://orbeon.org/oxf/xml/form-runner" xmlns:xxforms="http://orbeon.org/oxf/xml/xforms" xmlns:widget="http://orbeon.org/oxf/xml/widget">
                         <query/>
               <query name="mods_book_number_identifier_field" path="mods_book_number_identifier_field" label="Entry Number" type="" control="input" search-field="true" match="substring">Doo</query>
                <query name="mods_titleInfo_field" path="mods_titleInfo_field" label="Title" type="" control="input" search-field="true" match="substring">Ray</query>
                <query name="mods_name_field" path="mods_name_field" label="Name" type="" control="input" search-field="true" match="substring">Mee</query>
                         <page-size></page-size>
                         <page-number></page-number>
                     </search>'
              @repo.solr.should_receive(:paginate).with(1, 25, "select", {:params=>{:fq=>["mdform_tag_field:barForm", "{!dismax f=mods_book_number_identifier_field}Doo", "{!dismax f=mods_titleInfo_field}Ray", "{!dismax f=mods_name_field}Mee"], :fl=>["*"], :qt=>"dismax"}}).and_return({:response => [ :num_found => 55,  :docs => ["our solr docs would be here"] ]})
              @repo.should_receive(:build_results).with({:response=>[{:num_found=>55, :docs=>["our solr docs would be here"]}], "page"=>"1", "queries"=>["mods_book_number_identifier_field", "mods_titleInfo_field", "mods_name_field"], "page_size"=>"25"})                    
              @repo.search("fooApp", "barForm", xml)
    end
    
    
    it "should submit a fulltext queries correctly to SOLR" do
        xml = '<search xmlns:mods="http://www.loc.gov/mods/v3" xmlns:f="http://orbeon.org/oxf/xml/formatting" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xxi="http://orbeon.org/oxf/xml/xinclude" xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xbl="http://www.w3.org/ns/xbl" xmlns:exforms="http://www.exforms.org/exf/1-0" xmlns:pipeline="java:org.orbeon.oxf.processor.pipeline.PipelineFunctionLibrary" xmlns:fr="http://orbeon.org/oxf/xml/form-runner" xmlns:xxforms="http://orbeon.org/oxf/xml/xforms" xmlns:widget="http://orbeon.org/oxf/xml/widget">
                           <query>Some Full Texting Here Yall</query>
                 <query name="mods_book_number_identifier_field" path="mods_book_number_identifier_field" label="Entry Number" type="" control="input" search-field="true" match="substring"></query>
                  <query name="mods_titleInfo_field" path="mods_titleInfo_field" label="Title" type="" control="input" search-field="true" match="substring"></query>
                  <query name="mods_name_field" path="mods_name_field" label="Name" type="" control="input" search-field="true" match="substring"></query>
                           <page-size>22</page-size>
                           <page-number>4</page-number>
                       </search>'
           @repo.solr.should_receive(:paginate).with(4, 22, "select",  {:params=>{ :q => "Some Full Texting Here Yall", :fq=>["mdform_tag_field:barForm"], :fl=>["*"], :qt=>"dismax"}}).and_return({:response => [ :numFound => 99,  :docs => ["our solr docs would be here"] ]})
           @repo.should_receive(:build_results).with({:response=>[{:numFound=>99, :docs=>["our solr docs would be here"]}], "page"=>"4", "queries"=>["mods_book_number_identifier_field", "mods_titleInfo_field", "mods_name_field"], "page_size"=>"22"})                    
           @repo.search("fooApp", "barForm", xml)
                         
    end
    
    it "should raise an error is something is not right" do
      lambda {  @repo.search(1, 2, 3) }.should raise_error
    end
     
    
  end
  
  
  
  describe "#build_results" do
    
    it "should take a hash and return properly formateed XML " do
      solr_results = {"response" =>{"numFound" => "99", "docs" =>["fgs_createdDate_date" => "1999", "fgs_lastModifiedDate_date" => "2011", "id" => "druid:1234", "mods_book_number_identifier_field" => "123 Book Num", "mods_titleInfo_field" => "Our Title",  "mods_name_field" => "Joey Jo Jo"]}, "page"=>"4", "queries"=>["mods_book_number_identifier_field", "mods_titleInfo_field", "mods_name_field"], "page_size"=>"22"}
      orbeon_xml =  Nokogiri::XML('<?xml version="1.0"?>
           <documents total="99" page-size="22" page-number="4">
             <document created="1999" last-modified="2011" name="druid:1234">
               <details>
                 <detail>123 Book Num</detail>
                 <detail>Our Title</detail>
                 <detail>Joey Jo Jo</detail>
               </details>
             </document>
           </documents>')
        Nokogiri::XML(@repo.build_results(solr_results)).root.should be_equivalent_to(orbeon_xml.root)
           
    end
  end
  
  describe "#check_solr_field" do
    
    it "should return blank string if no field given" do
      @repo.check_solr_field.should == ""
    end
    
    it "should return a concationed string for array values with a pipe between values" do
      @repo.check_solr_field(["One", "Two"]).should == "One | Two"
    end
  
    it "should return a stripped string if a string is given" do
      @repo.check_solr_field("    Value            ").should == "Value"
    end
   
    it "should return a blank string for anything else" do
      @repo.check_solr_field(1).should == ""
    end
  
  end
  
end