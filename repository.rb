require 'rubygems'
require 'rest-client'
require 'open-uri'
require 'nokogiri'
require 'rsolr'
require 'rsolr-ext'

#
# This was written to give a quick/dirty XML datastream utility for Fedora without using
# Active Fedora, which can be slow to retrieve large objects.
#

module Stanford

  class Repository
  
    #
    # This method initializes the fedora repository and solr instance
    attr_reader :fedora
    attr_reader :solr
  
    def initialize(fedora='http://fedoraAdmin:fedoraAdmin@localhost:8983/fedora', solr='http://localhost:8983/solr/test')  
      #puts "Initializing Repository at #{base}" 
      fedora.chop! if /\/$/.match(fedora)
      solr.chop! if  /\/$/.match(solr)
      @fedora = fedora
      @solr = RSolr.connect(:url => solr )
    
    end

 
 #
 # FEDORA RELATED METHODS
 #
    
    #
    # This method retrieves a comprehensive list of datastreams for the given object
    # It returns either a Nokogiri XML object or a IOString 
    # 
    def get_datastream( pid, dsID )
        pid.include?("druid") ? pid = pid : pid = "druid:#{pid}"
        uri = URI.parse(@fedora + '/objects/' + pid + '/datastreams/' + dsID + '/content') 
        RestClient.get(uri.to_s)
    rescue => e
        p e
        return nil     
    end
    
    # This method replaces a datastream in fedora. Inputs the pid, dsID, and xml string
    def put_datastream(pid, dsID, xml)
         uri = URI.parse(@fedora + '/objects/' + pid + '/datastreams/' + dsID ) 
         res = RestClient.put uri.to_s, xml, :content_type => "application/xml"
        return res
    end
  
  
  #
  # SOLR RELATED METHODS
  #
  # This is used for searching for documents. The requests come via a POST with the application and form name, 
  # as well as some XML to structure the request. Here is the same XML:
  #<?xml version="1.0" encoding="UTF-8"?><search xmlns:mods="http://www.loc.gov/mods/v3" xmlns:f="http://orbeon.org/oxf/xml/formatting" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xxi="http://orbeon.org/oxf/xml/xinclude" xmlns:xi="http://www.w3.org/2001/XInclude" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xbl="http://www.w3.org/ns/xbl" xmlns:exforms="http://www.exforms.org/exf/1-0" xmlns:pipeline="java:org.orbeon.oxf.processor.pipeline.PipelineFunctionLibrary" xmlns:fr="http://orbeon.org/oxf/xml/form-runner" xmlns:xxforms="http://orbeon.org/oxf/xml/xforms" xmlns:widget="http://orbeon.org/oxf/xml/widget">
  #                    <!-- Application name -->
  #                    <app/>
  #                    <!-- Form name -->
  #                    <form/>
  #                    <!-- Free text search query -->
  #                    <query/>
  #          <query name="mods_book_number_identifier_field" path="mods_book_number_identifier_field" label="Entry Number" type="" control="input" search-field="true" match="substring"/>
  #           <query name="mods_titleInfo_field" path="mods_titleInfo_field" label="Title" type="" control="input" search-field="true" match="substring"/>
  #           <query name="mods_name_field" path="mods_name_field" label="Name" type="" control="input" search-field="true" match="substring"/>
  #                    <!-- Paging -->
  #                    <page-size>25</page-size>
  #                    <page-number>1</page-number>
  #                    <!-- Sorting -->
  #                    <sort-key/>
  #                    <!-- Language -->
  #                    <lang>en</lang>
  #                </search>
  
  # The returned XML Format should be :
  #<documents total="2" page-size="10" page-number="1">
  #    <document created="2008-03-14T12:33:15.735-07:00" last-modified="2008-03-14T12:36:51.657-07:00" name="847C6B6ADB949146C0105433A374B5CE">
  #        <details>
  #            <detail>John</detail>
  #            <detail>Doe</detail>
  #        </details>
  #    </document>
  #    <document created="2008-03-14T12:32:53.735-07:00" last-modified="2008-03-14T12:32:53.735-07:00" name="85F3E3433DEB6E1EDE9DCD6F87D24240">
  #        <details>
  #            <detail>Sofia</detail>
  #            <detail>Smith</detail>
  #        </details>
  #    </document>
  # </documents>
  
  # conducts the search. takes application and form names (strings), the query xml (string) and page number and page size (integers)
    def search(application, form, queryXML, page = 1, page_size = 25)
    
      xml = Nokogiri::XML(queryXML)
      params = {:fq => ["mdform_tag_field:#{form}"], :fl => ["*"], :qt => "dismax"}
      
    
      # first extract the fulltext query, one is present
      fulltext = xml.search('//query[not(@name)]')  
      if !fulltext.first.nil? and !fulltext.first.content.empty?
        params[:q] = fulltext.first.content
      end
      
      # filter to only look for fielded queries that have been tagged for this form
      queries = xml.search('//query[@name]')
      queries.each do |q|
        if !q.content.empty?  
          params[:fq] << "{!dismax f=#{q['name']}}#{q.content}"
        end
      end
      
      
     puts params.inspect + "\n%%%%%%"
      # get response from SOLR
      solr_docs = @solr.paginate(page, page_size, "select", :params => params) 
      # store this in the hash so we can access it later
      solr_docs["page"] = page.to_s
      solr_docs["page_size"] = page_size.to_s
 
      # store the rest of the queries
      solr_docs["queries"] = []
      queries.each {|q| solr_docs["queries"] << q['name'] }
    
    
      response = build_results(solr_docs)
      return response
    
    
    rescue => e
      raise   e.backtrace.join("\n")
    end
  
  
    # takes a Solr results hash and builds the results XML to be sent to Orbeon
    def build_results(solr_docs)
      results = Nokogiri::XML::Builder.new do |xml|
        xml.documents( :total => solr_docs["response"]["numFound"], :"page-size" => solr_docs["page_size"], :"page-number" => solr_docs["page"] ) { 
          solr_docs["response"]["docs"].each do |doc| 
            xml.document(:created => check_solr_field(doc["fgs_createdDate_date"]), :"last-modified" =>  check_solr_field(doc["fgs_lastModifiedDate_date"]), :name => doc["id"] ) {
              xml.details {
                solr_docs["queries"].each do |q| 
                  xml.detail_ check_solr_field(doc[q])
                end
              }
            }
          end
        }
      end
      return results.to_xml
    end
    
    
    # This is used to check if a Solr field is  nil. Returns the value if it is not, returns an empty string is it is
    def check_solr_field(field=nil)
      if field.nil? 
        return ""
      elsif field.is_a?(Array)
        return field.join(" | ")
      elsif field.is_a?(String)
        return field.strip
      else
         return "" 
      end
    end


#
# DEPRECIATED. JUST HERE TO REMIND ME WHAT I WAS DOING
#
=begin    
    # this takes the solr response and builds the <documents> xml node
    def documents_results(solr_docs)
      # prepare response
      xml_doc = Nokogiri::XML("<documents/>")
      xml_doc.root["total"] = solr_docs["response"]["numFound"].to_s
      xml_doc.root["page-size"] = solr_docs["page_size"]
      xml_doc.root["page-number"] = solr_docs["page"]
      
      solr_docs["response"]["docs"].each{ |solr_doc| xml_doc.root << document_results(solr_doc, xml_doc, solr_docs["mods_queries"] ) }
      return xml_doc.to_xml
    end
  
    #this takes a solr response document and converts it to the xml needed for the response
    def document_results(solr_doc, xml_doc, queries)
      doc_node = Nokogiri::XML::Node.new("document", xml_doc)
      solr_doc["fgs_createdDate_date"] ? doc_node["created"] = solr_doc["fgs_createdDate_date"] : doc_node["created"]  = "0"
      solr_doc["fgs_createdDate_date"] ? doc_node["last-modified"] = solr_doc["fgs_createdDate_date"] : doc_node["last-nodified"] = "0"
      doc_node["name"] = solr_doc["id"]
      
      queries.each { |k, v| doc_node << detail_results(solr_doc, xml_doc, k, v)}
      
      return doc_node 
    end
  
    #this takes a solr response document and converts it to the xml needed for the document details.
    def detail_results(solr_doc, xml_doc, attribute, value)
      
      details_node =  Nokogiri::XML::Node.new("details", xml_doc)
      detail = Nokogiri::XML::Node.new("detail", xml_doc)
      details_node << detail
              
      
      return details_node

    end  
=end

  end  
end