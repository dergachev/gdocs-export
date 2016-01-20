#===============================================================================
# DEFAULT MAKE VARIABLES
#===============================================================================

# defaults to "Test doc for gd-pandoc"
doc = https://docs.google.com/a/evolvingweb.ca/document/d/1dwYaiiy4P0KA7PvNwAP2fsPAf6qMMNzwaq8W66mwyds/edit#heading=h.4lk08p1hx3w

workdir=/var/gdocs-export
outdir=build
doc_id = $(shell echo $(doc) | sed -e 's@^https.*document/d/@@' -e 's@/edit.*@@')
name = default
input_file = input/$(name).html
OUTPUT=$(outdir)/$(name)
auth_file = google-api-authorization.yaml
docker_run_cmd = docker run -t -i -v `pwd`:$(workdir) -p 12736:12736 dergachev/gdocs-export

# directory containing customized header.tex, etc...
theme = sample

#===============================================================================
# GOOGLE_DRIVE_API TARGETS
#===============================================================================

install_auth_file:
	cp $(workdir)/$(auth_file) ~/.google-api.yaml

api_auth:
	bundle exec ruby bin/authorize.rb \
		$(CLIENT_ID) $(CLIENT_SECRET) \
		https://www.googleapis.com/auth/drive.readonly \
		> $(auth_file)

api_download: install_auth_file
	bundle exec google-api execute \
	  -u "https://docs.google.com/feeds/download/documents/export/Export?id=$(doc_id)&exportFormat=html" \
	  > $(input_file)

#===============================================================================
# PANDOC TARGETS
#===============================================================================

latex:
	mkdir -p $(OUTPUT)
	cp assets/default/* $(OUTPUT)
	test -z "$(theme)" || cp assets/$(theme)/* $(OUTPUT)
	cp $(input_file) $(OUTPUT)/in.html

	bundle exec ruby -C$(OUTPUT) `readlink -f lib/pandoc-preprocess.rb` in.html > $(OUTPUT)/preprocessed.html
	pandoc --parse-raw $(OUTPUT)/preprocessed.html -t json > $(OUTPUT)/pre.json
	cat $(OUTPUT)/pre.json | ./lib/pandoc-filter.py > $(OUTPUT)/post.json

	# use pandoc to create metadata.tex, main.tex (these are included by ew-template.tex)
	pandoc $(OUTPUT)/post.json --no-wrap -t latex --template $(OUTPUT)/template-metadata.tex > $(OUTPUT)/metadata.tex
	pandoc $(OUTPUT)/post.json --chapters --no-wrap -t latex > $(OUTPUT)/main.tex

	# must use -o with docx output format, since its binary
	pandoc $(OUTPUT)/post.json -s -t docx -o $(OUTPUT)/$(name).docx
	pandoc $(OUTPUT)/post.json -s -t rtf -o $(OUTPUT)/$(name).rtf

pdf:
	# convert latex to PDF
	echo "Created $(OUTPUT)/$(name).tex, compiling into $(name).pdf"
	# rubber will set output PDF filename based on latex input filename
	mv $(OUTPUT)/template.tex $(OUTPUT)/$(name).tex
	( cd $(OUTPUT); rubber --pdf $(name))

convert: latex pdf

diff:
	latexdiff --flatten $(outdir)/$(before)/$(before).tex $(OUTPUT)/$(name).tex > $(OUTPUT)/diff.tex
	(cd $(OUTPUT); rubber --pdf diff)


#===============================================================================
# DOCKER TARGETS
#===============================================================================

build_docker:
	@echo "Warning: building can take a while (~15m)."
	dpkg -l squid-deb-proxy || sudo apt-get install -y squid-deb-proxy
	docker build -t dergachev/gdocs-export .

docker_debug:
	$(docker_run_cmd) /bin/bash

latest:
	docker run -t -i `docker images -q | head -n 1` /bin/bash

docker_api_auth:
	$(docker_run_cmd) make api_auth CLIENT_ID=$(CLIENT_ID) CLIENT_SECRET=$(CLIENT_SECRET)

docker_api_download:
	$(docker_run_cmd) make api_download doc_id=$(doc_id) input_file=$(input_file)

docker_convert:
	$(docker_run_cmd) make convert OUTPUT=$(OUTPUT) name=$(name) input_file=$(input_file) theme=$(theme)

docker_diff:
	docker run -t -i -v `pwd`:$(workdir) -p 12736:12736 dergachev/gdocs-export make diff OUTPUT=$(OUTPUT) name=$(name) input_file=$(input_file) before=$(before)

#===============================================================================
# MISC TARGETS
#===============================================================================

test:
	bundle exec rspec
