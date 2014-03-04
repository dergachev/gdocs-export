# defaults to "Test doc for gd-pandoc"
doc = https://docs.google.com/a/evolvingweb.ca/document/d/1dwYaiiy4P0KA7PvNwAP2fsPAf6qMMNzwaq8W66mwyds/edit#heading=h.4lk08p1hx3w
doc_id = $(shell echo $(doc) | sed -e 's@^https.*document/d/@@' -e 's@/edit.*@@')
name = default
input_file = input/$(name).html
OUTPUT=build/$(name)

api_download:
	bundle exec google-api execute \
	  -u "https://docs.google.com/feeds/download/documents/export/Export?id=$(doc_id)&exportFormat=html" \
	  > $(input_file)

api_authorize:
	bundle exec google-api oauth-2-login -v \
	  --scope https://www.googleapis.com/auth/drive.readonly \
	  --client-id $(client_id) \
	  --client-secret $(client_secret)

# needs ruby 1.9+ to run properly, due to faraday
api_download_alternative:
	bundle exec google-api execute drive.files.get --api drive  -- fileId="$(doc)" \
	 | sed 's/text\/html/textHtml/' \
	 | jq .exportLinks.textHtml -c \
	 | xargs bundle exec google-api execute -u
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
	cp assets/template-ew.tex $(OUTPUT)/$(name).tex
	
	# must use -o with docx output format, since its binary
	pandoc $(OUTPUT)/post.json -s -t docx -o $(OUTPUT)/$(name).docx
	pandoc $(OUTPUT)/post.json -s -t rtf -o $(OUTPUT)/$(name).rtf
	
	# convert latex to PDF
	echo "Created $(OUTPUT)/$(name).tex, compiling into $(name).pdf"
	( cd $(OUTPUT); rubber --pdf $(name))

diff:
	latexdiff --flatten build/$(before)/$(before).tex $(OUTPUT)/$(name).tex > $(OUTPUT)/diff.tex
	(cd $(OUTPUT); rubber --pdf diff)
