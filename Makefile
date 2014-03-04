# defaults to "Test doc for gd-pandoc"
doc = https://docs.google.com/a/evolvingweb.ca/document/d/1dwYaiiy4P0KA7PvNwAP2fsPAf6qMMNzwaq8W66mwyds/edit#heading=h.4lk08p1hx3w
doc_id = $(shell echo $(doc) | sed -e 's@^https.*document/d/@@' -e 's@/edit.*@@')
name = default
input_file = input/$(name).html

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
	bash bin/run.sh $(input_file)

#TODO: this has not been tested recently
diff:
	bash bin/diff.sh build/$(before)/$(before).tex build/$(after)/$(after).tex
