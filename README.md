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

## Getting google drive API token

* Visit https://console.developers.google.com/project, create new project (pick a descriptive name and ID)
 * ![](https://dl.dropbox.com/u/29440342/screenshots/QOXZHZMW-2014.03.04-17-49-16.png)
* In the new project, go to "APIs & Auths > APIs" and enable "Drive SDK". Leave defaults.
 * ![](https://dl.dropbox.com/u/29440342/screenshots/YXQGJYLR-2014.03.04-17-50-44.png)
* Visit "APIs & Auths > Credentials" and click "Create New Client ID"
 * ![](https://dl.dropbox.com/u/29440342/screenshots/QJRSROZL-2014.03.04-17-51-50.png)
* Select "Installed Application" and "Other" when prompted for application type.
 * ![](https://dl.dropbox.com/u/29440342/screenshots/SNFDZSWW-2014.03.04-17-52-19.png)
* Copy and paste "Client ID" and "Client Secret"
 * ![](https://dl.dropbox.com/u/29440342/screenshots/GGJDQSIN-2014.03.04-17-57-34.png)




