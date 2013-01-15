To use:
1.  create a yml config file for your collection going to a Solr index.  

See  config/bnf-images.yml for an example.
I suggest you use sul-solr-test-a/solr/mods_profiler  as your Solr index, as the number of possible fields required Chris Beer to tweak a tomcat parameter.

To run:

 ./bin/indexer config/(your coll).yml

I suggest you run it on harvestdor-dev for speed.  I ran off my laptop using ssh tunnel to get to sul-solr and it took 1 second per record.


TODO:
----

2a.  change solrconfig.xml, here and on sul-solr
2b.  change code (& specs)