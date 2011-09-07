require 'rubygems'
require 'rest-client'
require 'open-uri'
require 'nokogiri'
require 'rsolr'
require 'rsolr-ext'

#
# This is used to access Orbeon forms / metadatatoolkit instance  
#
#

module Stanford
  
  class Orbeon
    
   # This method initializes the fedora repository and solr instance
    attr_reader :orbeon

    def initialize(orbeon='http://lyberapps-dev.stanford.edu/orbeon/')  
      orbeon.chop! if /\/$/.match(orbeon)
      @orbeon = orbeon
    end
    
    # This gets the default XML document for a new documents and adds the druid and creationDate
    # /orbeon/fr/page/custom/mods/mclaughlin/template
    def get_mods_template(application, form, druid = "CHANGEME")
        uri = URI.parse(@orbeon + "/fr/page/custom/#{application}/#{form}/template")
        xml = Nokogiri::XML(RestClient.get(uri.to_s))
        xml.at_xpath("/mods:mods/mods:identifier[@displayLabel = 'SU DRUID']").content = druid
        
        if xml.at_xpath("/mods:mods/mods:recordInfo/mods:recordCreationDate")
          xml.at_xpath("/mods:mods/mods:recordInfo/mods:recordCreationDate")["encoding"] = "w3cdtf"
          xml.at_xpath("/mods:mods/mods:recordInfo/mods:recordCreationDate").content = Time.now.strftime("%Y-%m-%dT%l:%M:%S%z")
        elsif xml.at_xpath("/mods:mods/mods:recordInfo")
            creationDate = Nokogiri::XML::Node.new("recordCreationDate", xml)
            creationDate["encoding"] = "w3cdtf"
            creationDate.content = Time.now.strftime("%Y-%m-%dT%l:%M:%S%z")
            xml.at_xpath("//mods:recordInfo") << creationDate
        else
            recordInfo = Nokogiri::XML::Node.new("recordInfo", xml)
            creationDate = Nokogiri::XML::Node.new("recordCreationDate", xml)
            creationDate["encoding"] = "w3cdtf"
            creationDate.content = Time.now.strftime("%Y-%m-%dT%l:%M:%S%z")
            recordInfo << creationDate
            xml.root << recordInfo
        end
      
        xml.to_xml
    rescue => e
      e.inspect
    end
    
  end
  
end