To use:
1.  create a Solr index.
a. do it on sul-solr --- the number of possible fields required Chris Beer to tweak a tomcat parameter.
  https://consul.stanford.edu/display/DLSSINFRAAPP/SUL+Solr+Infrastructure
b. you can copy the configs from the solr_conf folder

2.  I suggest you run it on harvestdor-dev for speed 
I ran off my laptop using ssh tunnel to get to sul-solr and it took 1 second per record.

b.  create a yml config file for your collection going to your Solr index.  See  bin/bnf-image.yml for an example.


To run:

 ./bin/indexer bin/(your coll).yml


TODO:
----

1.  add a "collection" field in case we write more than one collection to the same Solr index
2.  change fields from _ssim to _sim -- we don't need to store them.
2a.  change solrconfig.xml, here and on sul-solr
2b.  change code (& specs)