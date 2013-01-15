To use:
1.  create a yml config file for your collection going to a Solr index.  

See  config/bnf-images.yml for an example.
I suggest you use sul-solr-test-a/solr/mods_profiler  as your Solr index, as the number of possible fields required Chris Beer to tweak a tomcat parameter.

To run:

(bundle install)

 ./bin/indexer config/(your coll).yml

I suggest you run it on harvestdor-dev, as it is already set up to be able to harvest from the DOR OAI provider and to write to the sul-solr-test index.

To view results:
  https://sul-solr-test-a/solr/bnf/select?q=collection:(yer_coll_fld_val)&rows=0&qt=standard

To view more than 20 or 30 facet values

  https://sul-solr-test-a/solr/bnf/select?q=collection:(yer_coll_fld_val)&rows=0&qt=standard&facet.limit=50

To view all the values for a particular facet
  https://sul-solr-test-a/solr/bnf/select?q=collection:(yer_coll_fld_val)&rows=0&qt=standard&facet.limit=-1&facet.field=subject_name_namePart_sim
  
