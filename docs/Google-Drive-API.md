# Registering with Google Developers Console

The following shows how to get a register your app (or rather, your instance of gdocs-export) and get a Google API `client_id` and `client_secret` tokens.

The Google Developers Console API console seems to be always changing. The following steps were sufficient as of March 4, 2014.

---

* **CREATE NEW PROJECT:**
	1. Visit [https://console.developers.google.com/project](https://console.developers.google.com/project).
	![](./images/1.0.png)
	1. Create new project.
	![](./images/1.1.png)
	
---
	
* **ENABLE GOOGLE DRIVE API:**
	1. In the next page, you will be prompted to `Enable the APIs you plan to use`. Follow this link.
	![](./images/2.0.png)
	1. Type `drive` in the search field, and then select the `Google Drive API`. 
	![](./images/2.1.png)
	1. Finally, you will be given the choice to `Enable` or `Try this API`, click `Enable`.
	![](./images/2.2.png)
	
---

* **CREATE CREDENTIALS:**
	1. Once enabled, you will be prompted to `Create credentials`. Follow this link.
	![](./images/3.0.png)
	1. You will now be given two drop-down menus and  a radio-button list. Fill them as in the picture (i.e.  `Google Drive API` | `Other UI` | `User Data` ). 
	![](./images/3.1.png)
	1. Name your `OAuth 2.0 client ID` appropriately, and create it. Then name `Product name` appropriately, and press continue.
	![](./images/3.2.png)
	1. Download your credentials in JSON format if needed, and press done.
	![](./images/3.3.png)
	
	---
	
* **ACCESS YOUR ID+PASS:**
	1. Simply click on the name of the OAuth ID you just you just created.
	![](./images/4.0.png)
	1. The **CLIENT\_ID** and **CLIENT\_SECRET** you need are there for you to copy.
	![](./images/4.1.png)
