include .env
#===============================================================================
# DEFAULT MAKE VARIABLES
#===============================================================================
AUTH_FILE=google-api-authorization.yaml

#DATE=$(eval DATE_DIR=$(shell date +%Y-%m))
#DATE=$(shell date +%Y-%m)

FILE_NAME=default
THEME=sample

INPUT_FILE_DIR=input
INPUT_FILE=$(INPUT_FILE_DIR)/$(FILE_NAME).html

OUTPUT_DIR=build
OUTPUT_FILE_DIR=$(OUTPUT_DIR)/$(FILE_NAME)



#===============================================================================
# GOOGLE_DRIVE_API TARGETS
# run on Docker container
#===============================================================================

install_auth_file:
	@cp ${APP_DOCKER_DIR}/${AUTH_FILE} ${APACHE_USER_HOME_DIR}/.google-api.yml

# Download google-api-authorization.yaml
# usage:
# make api_auth
api_auth:
	bundle exec ruby bin/authorize.rb \
		${GOOGLE_CLIENT_ID} ${GOOGLE_CLIENT_SECRET} \
		https://www.googleapis.com/auth/drive.readonly \
		> $(AUTH_FILE)

# Download HTML version of the Google document and store it in INPUT_FILE_DIR
# usage:
# make api_download DOC_ID=xxxxx FILE_NAME=xxx
api_download: #install_auth_file
	# get DOC_ID from input
	bundle exec google-api execute \
	  -u "https://docs.google.com/feeds/download/documents/export/Export?id=$(DOC_ID)&exportFormat=html" \
	  > $(INPUT_FILE_DIR)/$(FILE_NAME).html

#===============================================================================
# PANDOC TARGETS
# run on Docker container
#===============================================================================
latex:
	mkdir -p $(OUTPUT_FILE_DIR)
	cp assets/default/* $(OUTPUT_FILE_DIR)
	test -z "$(THEME)" || cp assets/$(THEME)/* $(OUTPUT_FILE_DIR)
	cp $(INPUT_FILE) $(OUTPUT_FILE_DIR)/in.html

	bundle exec ruby -C$(OUTPUT_FILE_DIR) "$$PWD/lib/pandoc-preprocess.rb" in.html > $(OUTPUT_FILE_DIR)/preprocessed.html
	pandoc --parse-raw $(OUTPUT_FILE_DIR)/preprocessed.html -t json > $(OUTPUT_FILE_DIR)/pre.json
	cat $(OUTPUT_FILE_DIR)/pre.json | ./lib/pandoc-filter.py > $(OUTPUT_FILE_DIR)/post.json

	# use pandoc to create metadata.tex, main.tex (these are included by ew-template.tex)
	pandoc $(OUTPUT_FILE_DIR)/post.json --no-wrap -t latex --template $(OUTPUT_FILE_DIR)/template-metadata.tex > $(OUTPUT_FILE_DIR)/metadata.tex
	pandoc $(OUTPUT_FILE_DIR)/post.json --chapters --no-wrap -t latex > $(OUTPUT_FILE_DIR)/main.tex

	# must use -o with docx output format, since its binary
	pandoc $(OUTPUT_FILE_DIR)/post.json -s -t docx -o $(OUTPUT_FILE_DIR)/$(FILE_NAME).docx
	pandoc $(OUTPUT_FILE_DIR)/post.json -s -t rtf -o $(OUTPUT_FILE_DIR)/$(FILE_NAME).rtf

pdf:
	# convert latex to PDF
	echo "Created $(OUTPUT_FILE_DIR)/$(FILE_NAME).tex, compiling into $(FILE_NAME).pdf"
	# rubber will set output PDF filename based on latex input filename
	cp -f $(OUTPUT_FILE_DIR)/template.tex $(OUTPUT_FILE_DIR)/$(FILE_NAME).tex
	( cd $(OUTPUT_FILE_DIR); rubber --pdf $(FILE_NAME))

convert: latex pdf

# diff:
# 	/usr/bin/perl "`which latexdiff`" --flatten $(outdir)/$(before)/$(before).tex $(OUTPUT)/$(name).tex > $(OUTPUT)/diff.tex
# 	(cd $(OUTPUT); latexmk -pdf diff)


#===============================================================================
# DOCKER TARGETS
#===============================================================================

build_docker:
	docker-compose up -d --build

access:
	# Access docker container as gdocs user
	docker exec -it --user ${APACHE_USER} ${DOCKER_CONTAINER} /bin/bash

stop:
	docker-compose stop

restart:
	docker-compose stop
	docker-compose start

#===============================================================================
# MISC TARGETS
#===============================================================================

test:
	bundle exec rspec

#===============================================================================
# TEST
# Test build Alex's public document
# https://docs.google.com/document/d/1dwYaiiy4P0KA7PvNwAP2fsPAf6qMMNzwaq8W66mwyds/edit
#===============================================================================
test_convert:
	$(eval DOC_ID=1dwYaiiy4P0KA7PvNwAP2fsPAf6qMMNzwaq8W66mwyds)
	$(eval FILE_NAME=sample2)
	$(MAKE) api_download DOC_ID=$(DOC_ID) FILE_NAME=$(FILE_NAME)
	$(MAKE) convert FILE_NAME=$(FILE_NAME) THEME=ew
