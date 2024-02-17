#!/bin/bash
# use pwd to make paths absolute
CATALOG=tomcat/src/main/webapp/WEB-INF/DTD/xml-catalog.xml
XSLT=tomcat/src/main/webapp/xml-to-pdf.xslt
# base url for essays
BASE_URL=https://vlp.mpiwg-berlin.mpg.de/essays/data/
# output directory
PDF_DIR=web/pdf/
# list of articles
ARTICLES="art10 art11 art12 art29 art31 art35 art4 art43 art44 art5 art6 art68 art69 art7 art71 art72 art73 art74 art76 art77 art78 art8 art9 enc13 enc17 enc18 enc19 enc22 enc42" 

# create output directory
mkdir -p $PDF_DIR
java -cp 'tomcat/src/main/webapp/WEB-INF/lib/*' de.mpiwg.fop.servlet.VLPEssayUtil $CATALOG $XSLT $BASE_URL $PDF_DIR $ARTICLES
