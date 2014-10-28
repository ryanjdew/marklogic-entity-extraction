
./ml local bootstrap  
./ml local deploy modules  

Download SNOMED_CT data at http://www.nlm.nih.gov/research/umls/Snomed/us_edition.html and unzip  
cd $PROJECT_HOME/scripts/snomed  
perl marklogic-snomed-xmlify.pl ~/Documents/healthcare-data/snomed/SnomedCT_Release_US1000124_20140301/RF2Release/Snapshot  
mlcp.sh import -host localhost -port 9061 -username admin -password admin -options_file snomed-xml-options.txt  
Download RXNORM data at http://www.nlm.nih.gov/research/umls/rxnorm/docs/rxnormfiles.html and unzip  
cd $PROJECT_HOME/scripts/rxnorm  
perl marklogic-rxnorm-xmlify.pl ~/Documents/healthcare-data/rxnorm/RxNorm_full_07072014  
mlcp.sh import -host localhost -port 9061 -username admin -password admin -options_file rxnorm-xml-options.txt  


