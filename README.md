# gdocs-export

Script to programatically download a text document from Google Docs and convert
it to LaTeX.

## Usage

See the `Vagrantfile` for installation steps.
See the `Makefile` for usage.

```bash
vagrant up
vagrant ssh
cd /vagrant/

# populates ~/.google-api.yaml with access_token, refresh_token, etc..
make api_authorize client_id=$CLIENT_ID client_secret=$CLIENT_SECRET

# downloads file into input/document-march22.html
make api_download doc=$GOOGLE_DOC_URL name=document-march22

# creates build/document-march22/document-march22.pdf
make convert name=document-march22

# creates build/document-march22/diff.pdf
make diff name=document-march22 before=document-march21
```
