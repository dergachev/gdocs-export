gdocs-export
============

Script to programatically download a text document from Google Docs and convert
it to LaTeX, and compile it into a PDF.

For example, this [google
doc](https://docs.google.com/a/evolvingweb.ca/document/d/1dwYaiiy4P0KA7PvNwAP2fsPAf6qMMNzwaq8W66mwyds/edit)
is converted into [this
pdf](https://raw.githubusercontent.com/dergachev/gdocs-export/master/build/example/example.pdf).

Under the hood, it uses [pandoc](http://johnmacfarlane.net/pandoc/) to convert from HTML to LaTeX and PDF.

Installation
------------

See below for how to get google drive API *client_id* and *client_secret*.
See the `Vagrantfile` for installation steps.
See the `Makefile` for usage.

Starts a VM with docker and squid-deb-proxy running, then builds the gdocs-export docker image:

```bash
vagrant up
vagrant ssh
cd /vagrant/

# pulls the image from index.docker.io  (about ~2GB)
docker pull dergachev/gdocs-export
```

Alternatively, we can build the image from this repo, but this takes a while
and installing squid-deb-proxy to cache 'apt-get install' downloads is highly
recommended:

```bash
# optional, caches apt-get downloads in containers
apt-get install -y squid-deb-proxy

# takes 10-20 minutes
docker build -t dergachev/gdocs-export .
```

Configuration
-------------

Before being able to interact with Google APIs, you'll need to register a new
project in the [Google Developers
Console](https://console.developers.google.com/project), enable Google Drive
SDK for it, then retreive the associated *client_id* and *client_secret*
parameters.  For help with this, see below.

```bash
# see below for how to get your Google API client_id and client_secret (these are fake)
export CLIENT_ID=409429960585-o2i6nc17gf5sdhpa6o2g5gkkclmq229g.apps.googleusercontent.com
export CLIENT_SECRET=PqKk00otoY11cxEfSSE7pCdw
```

Now you'll need to give our newly-registered app permission to read all the Google Drive
documents associated with your account, which is done via an in-browser OATH workflow.

Before gdocs-export can download Google Drive documents associated with your
account, you'll need to grant it the appropriate permissions.


```bash
make docker_api_auth CLIENT_ID=$CLIENT_ID CLIENT_SECRET=$CLIENT_SECRET
```

That command command will prompt you to visit a URL that looks like this:

```
https://accounts.google.com/o/oauth2/auth?access_type=offline&approval_prompt=force&client_id=CLIENT_ID_GOES_HERE&redirect_uri=http://localhost:12736/&response_type=code&scope=https://www.googleapis.com/auth/drive.readonly
```

On successful authorization, the browser will be automatically redirected to
http://localhost:12736, where the command is listening for the resulting access
tokens, which it will save to `./google-api-authorization.yaml` in the
following format:

```
---
mechanism: oauth_2
scope: https://www.googleapis.com/auth/drive.readonly
client_id: 409429960585-o2i6nc17gf5sdhpa6o2g5gkkclmq229g.apps.googleusercontent.com
client_secret: PqKk00otoY11cxEfSSE7pCdw
access_token: ya29.1.klsfj3kj3kj23k4jkkjsfkfjksdjfksdjfkjjiuiquiuwiue-324k234kj324GI
refresh_token: 1/EJKERKJERKJ3jkkj34998889i9jkAAAAAAjjjjjjjzQ
```

The *client_id* and *client_secret * properties are your application's API
credentials, while the *access_token* and *refresh_token* are proof that your
application has been authorized access to a given account's data. Be sure to
keep this file private!

Usage
-----

Now that we've got all the access tokens we need, we can use it to download an
arbitrary document. For example, try downloading the [gdocs-export example
document](https://docs.google.com/a/evolvingweb.ca/document/d/1dwYaiiy4P0KA7PvNwAP2fsPAf6qMMNzwaq8W66mwyds/edit)
which I've shared publicly.

```bash
export GOOGLE_DOC_URL=https://docs.google.com/a/evolvingweb.ca/document/d/1dwYaiiy4P0KA7PvNwAP2fsPAf6qMMNzwaq8W66mwyds/edit
make docker_api_download name=example doc=$GOOGLE_DOC_URL
```

The above just created `./input/example.html`. Let's convert it to PDF:

```bash
make docker_convert name=example
```

The above command creates the following files inside of `./build/example/`:

    example.pdf
    example.docx
    example.rtf

By default it'll use the header.tex and logo image in `./assets/sample/`.
To use the customized files under `./assets/ew/` instead, do the following:

```bash
# pick up latex assets from ./assets/ew/ instead of ./assets/sample
make docker_convert name=example theme=ew
```

Finally, we also support generating a diff.pdf highlighting differences between
the current document and a previously downloaded and compiled version. The
workflow is as follows:

```bash
make docker_api_download name=my-doc-v1 doc=$GOOGLE_DOC_URL
make docker_convert name=my-doc-v1

# make some changes to the document
make docker_api_download name=my-doc-v2 doc=$GOOGLE_DOC_URL
make docker_convert name=my-doc-v2

# creates build/my-doc-v2/diff.pdf
make docker_diff before=my-doc-v1 name=my-doc-v2
```

Registering with Google Developers Console
------------------------------------------

The following shows how to get a register your app (or rather, your instance of
gdocs-export) and get a Google API *client_id* and *client_secret* tokens.

The Google Developers Console API console seems to be always changing. The
following steps were sufficient as of March 4, 2014.

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
