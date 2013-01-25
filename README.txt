To use:
1.  create a yml config file for your collection going to a Solr index.  

See  config/ap.yml for an example.

You will want to copy that file and change the following settings:
1. log_name
2. default_set
3. coll_fld_val  (at bottom)

I suggest you use sul-solr-test-a/solr/sax_profiler  as your Solr index, as the number of possible facet fields required Chris Beer to tweak a tomcat parameter.

To run:

(bundle install)

 ./bin/indexer config/(your coll).yml

I suggest you run it on harvestdor-dev, as it is already set up to be able to harvest from the DOR OAI provider and to write to the sul-solr-test index.

To view results:
  https://sul-solr-test-a/solr/sax_profiler/select?q=collection:(yer_coll_fld_val)&rows=0&qt=standard
  https://sul-solr-test-a/solr/sax_profiler/select?q=collection:archives&rows=0&qt=standard

To view more than 20 or 30 facet values

  https://sul-solr-test-a/solr/sax_profiler/select?q=collection:(yer_coll_fld_val)&rows=0&qt=standard&facet.limit=50
  https://sul-solr-test-a/solr/sax_profiler/select?q=collection:archives&rows=0&qt=standard&facet.limit=50

To view all the values for a particular facet
  https://sul-solr-test-a/solr/sax_profiler/select?q=collection:(yer_coll_fld_val)&rows=0&qt=standard&facet.limit=-1&facet.field=(field_name)
  https://sul-solr-test-a/solr/sax_profiler/select?q=collection:archives&rows=0&qt=standard&facet.limit=-1&facet.field=head_sim
  
