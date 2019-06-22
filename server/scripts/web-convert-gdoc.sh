#!/bin/sh

cd /var/gdocs-export
make api_download DOC_ID=$1 FILE_NAME=$2
make convert FILE_NAME=$2 THEME=ew

# if [ ! -d input/2018-07 ] then \
#   mkdir input/2018-07 \
# fi;
# bundlecd /elif [[ condition ]]; then
#   #statements
# echo "OH"
# # get DOC_ID from input
# bundle exec google-api execute \
#   -u "https://docs.google.com/feeds/download/documents/export/Export?id=1dwYaiiy4P0KA7PvNwAP2fsPAf6qMMNzwaq8W66mwyds&exportFormat=html&ndplr=1" \
#   > input/2018-07/test2.html


# make convert OUTPUT=$(OUTPUT_DIR)/$(FILE_NAME) FILE_NAME=$(FILE_NAME) THEME=ew

# Download HTML version of the Gdoc document
# make api_download doc_id=${DOC_ID} input_file=input/${DOC_NAME}.html workdir=${GDOCS_DIR}/
# # cp ${GDOCS_DIR}/google-api-authorization.yaml /home/gdocs/.google-api.yml
# #
# # GDOC_DOWNLOAD_URL="https://docs.google.com/feeds/download/documents/export/Export?id=${DOC_ID}&exportFormat=html"
# # echo ${GDOC_DOWNLOAD_URL}
# # bundle exec google-api execute -u ${GDOC_DOWNLOAD_URL} > input/${DOC_NAME}.html
#
# #
# # # Convert the file into PDF
# make convert OUTPUT=build/${DOC_NAME} name=${DOC_NAME} input_file=input/${DOC_NAME}.html theme=ew
# #
# # # Copy the PDF file into /output folder
# cp ${GDOCS_DIR}/build/${DOC_NAME}/${DOC_NAME}.pdf ${GDOCS_DIR}/server/www/output
