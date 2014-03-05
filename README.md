# gdocs-export

Script to programatically download a text document from Google Docs and convert
it to LaTeX.

## Usage

See below for how to get google drive API client_id and client_secret.
See the `Vagrantfile` for installation steps.
See the `Makefile` for usage.

```bash
vagrant up
vagrant ssh
cd /vagrant/

# runs "docker build ..."
make build_docker

# see below for how to get your Google API client_id and client_secret (these are fake)
export CLIENT_ID=409429960585-o2i6nc17gf5sdhpa6o2g5gkkclmq229g.apps.googleusercontent.com
export CLIENT_SECRET=PqKk00otoY11cxEfSSE7pCdw

# Populates ./google-api-authorization.yaml which contains access_token, refresh_token, etc..
# Launches a web-server on http://localhost:12736
# Will require you to open the generated URL in your browser.
make docker_api_auth client_id=$CLIENT_ID client_secret=$CLIENT_SECRET

# downloads file into input/document-march22.html
make docker_api_download doc=$GOOGLE_DOC_URL name=document-march22

# creates build/document-march22/document-march22.pdf
make docker_convert name=document-march22

# creates build/document-march22/diff.pdf
make docker_diff name=document-march22 before=document-march21
```

## Getting google drive API token

The Google API console seems to be always changing. The following steps were sufficient as of March 4, 2014.

* Visit https://console.developers.google.com/project, create new project (pick a descriptive name and ID)
    ![](https://dl.dropbox.com/u/29440342/screenshots/QOXZHZMW-2014.03.04-17-49-16.png)
* In the new project, go to "APIs & Auths > APIs" and enable "Drive SDK". 
 * Leave defaults, since they seem to include http://localhost (which covers http://localhost:12736)
    ![](https://dl.dropbox.com/u/29440342/screenshots/YXQGJYLR-2014.03.04-17-50-44.png)
* Visit "APIs & Auths > Credentials" and click "Create New Client ID"
    ![](https://dl.dropbox.com/u/29440342/screenshots/QJRSROZL-2014.03.04-17-51-50.png)
* Select "Installed Application" and "Other" when prompted for application type.
    ![](https://dl.dropbox.com/u/29440342/screenshots/SNFDZSWW-2014.03.04-17-52-19.png)
* Copy "Client ID" and "Client Secret", store them somewhere for future sourcing.
    ![](https://dl.dropbox.com/u/29440342/screenshots/GGJDQSIN-2014.03.04-17-57-34.png)
