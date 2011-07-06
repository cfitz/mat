configure :production do
  DOR_URI = 'http://fedoraAdmin:fedoraAdmin@dor-dev.stanford.edu/fedora/'
  SOLR_URI= 'http://dor-dev.stanford.edu/solr/'
end

configure :development do
  DOR_URI = 'http://fedoraAdmin:fedoraAdmin@dor-dev.stanford.edu/fedora/'
  SOLR_URI= 'http://dor-dev.stanford.edu/solr/'
end

configure :test do
  DOR_URI = 'http://fedoraAdmin:fedoraAdmin@dor-dev.stanford.edu/fedora/'
  SOLR_URI= 'http://dor-dev.stanford.edu/solr/'
end