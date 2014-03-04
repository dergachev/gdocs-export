# defaults to "Test doc for gd-pandoc"
doc = https://docs.google.com/a/evolvingweb.ca/document/d/1dwYaiiy4P0KA7PvNwAP2fsPAf6qMMNzwaq8W66mwyds/edit#heading=h.4lk08p1hx3w
doc_id = $(shell echo $(doc) | sed -e 's@^https.*document/d/@@' -e 's@/edit.*@@')
name = default
input_file = input/$(name).html
OUTPUT=build/$(name)
auth_file = google-api-authorization.yaml

install_auth_file:
	cp /var/gdocs-export/$(auth_file) ~/.google-api.yaml

api_auth:
	bundle exec ruby bin/authorize.rb \
		$(client_id) $(client_secret) \
		https://www.googleapis.com/auth/drive.readonly \
		> $(auth_file)

api_download: install_auth_file
	bundle exec google-api execute \
	  -u "https://docs.google.com/feeds/download/documents/export/Export?id=$(doc_id)&exportFormat=html" \
	  > $(input_file)

convert:
	mkdir -p $(OUTPUT)
	cp assets/* $(OUTPUT)
	cp $(input_file) $(OUTPUT)/in.html
	
	bundle exec ruby lib/pandoc-preprocess.rb $(OUTPUT)/in.html > $(OUTPUT)/preprocessed.html
	pandoc $(OUTPUT)/preprocessed.html -t json > $(OUTPUT)/pre.json
	cat $(OUTPUT)/pre.json | ./lib/pandoc-filter.py > $(OUTPUT)/post.json
	
	# use pandoc to create metadata.tex, main.tex (these are included by ew-template.tex)
	pandoc $(OUTPUT)/post.json --no-wrap -t latex --template assets/template-metadata.tex > $(OUTPUT)/metadata.tex
	pandoc $(OUTPUT)/post.json --chapters --no-wrap -t latex > $(OUTPUT)/main.tex
	cp assets/template.tex $(OUTPUT)/$(name).tex
	
	# must use -o with docx output format, since its binary
	pandoc $(OUTPUT)/post.json -s -t docx -o $(OUTPUT)/$(name).docx
	pandoc $(OUTPUT)/post.json -s -t rtf -o $(OUTPUT)/$(name).rtf
	
	# convert latex to PDF
	echo "Created $(OUTPUT)/$(name).tex, compiling into $(name).pdf"
	( cd $(OUTPUT); rubber --pdf $(name))

diff:
	latexdiff --flatten build/$(before)/$(before).tex $(OUTPUT)/$(name).tex > $(OUTPUT)/diff.tex
	(cd $(OUTPUT); rubber --pdf diff)

docker_build:
	@echo "Warning: building can take a while. Also currently requires 'apt-get install -y squid-deb-proxy'"
	docker build -t dergachev/gdocs-export .

docker_debug:
	docker run -t -i -v `pwd`:/var/gdocs-export -p 12736:12736 dergachev/gdocs-export /bin/bash

docker_api_auth:
	docker run -t -i -v `pwd`:/var/gdocs-export -p 12736:12736 dergachev/gdocs-export make api_auth client_id=$(client_id) client_secret=$(client_secret)

docker_api_download:
	docker run -t -i -v `pwd`:/var/gdocs-export dergachev/gdocs-export make api_download doc_id=$(doc_id) input_file=$(input_file)

docker_convert:
	docker run -t -i -v `pwd`:/var/gdocs-export dergachev/gdocs-export make convert OUTPUT=$(OUTPUT) name=$(name) input_file=$(input_file)

docker_diff:
	docker run -t -i -v `pwd`:/var/gdocs-export dergachev/gdocs-export make diff OUTPUT=$(OUTPUT) name=$(name) input_file=$(input_file) before=$(before)
