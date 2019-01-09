# Azure Blob Storage Static Web Site ARM Template

The repository contains a all-in-one ARM template that creates an Azure Blob Storage Static Web sites, deploys html files to it, and configures CloudFlare DNS with a custom domain name that points to the static web site, as well as enabling CloudFlare's SSL support. 

## Why this template
The template is mostly a proof-of-concept that you can deploy static web sites to Azure in a fully automated way, using only ARM templates. Whether or not it is a good idea I will let you decide for yourself. The reason for using CloudFlare and not an Azure native service are that CloudFlare provides SSL support with their DNS service, if the same was to be accomplished with Azure native services, it would make the template more involved. The Azure native way would involve Azure DNS, Azure CDN (as that is currently the only way to get custom domain name and SSL support for static websites). Finally a SSL certificate would have to be obtained Azure only provides native support for purchasing certificates, if a free SSL certificate is desired Let's Encrypt would have to be used. I will most likely make a revised version of the template that shows this, so watch the repo if you are interested in that.  

## How it works
The solution consists of mulitple templates. 
 

* azuredeploy.json is capable of deploying an Azure Storage Account and enabling static web sites for the storage account. It also deploys a simple dummy html page to the web site. 
* cloudflaredns.json is capable of setting up DNS for an existing azure storage account using cloudflare as DNS register 
* azuredeploy-full.json combines the two templates, such that first the storage account after which cloudflare is configured 

The templates do a few things that aren't possible with ARM templates, for that they rely on Azure Container Instances (ACI) to run docker images that uses either the Azure CLI, the Azure ARM API directly or the CloudFlare cli. 


## Interesting Concepts

The templates shows a few concepts that are worth a mention, this section is dedicated to that. 

### Enabling Azure Static Web Pages
The feature for Azure static web site cannot be enabled using the ARM template, as it is part of the data plane and not the control plane that ARM is supporting. The line between data and control plane is my opinion debatable especially when it comes to Azure Storage, it is quite annoying that not more is avaiable in the control plane. 

Nevertheless to enable static web sites, we need to run an Azure CLI command, to make matters even worse the command we need to run is currently only available from an preview extension `storage-preview` 

To do that from our ARM template (`azuredeploy.json`) we need to use ACI, deploy a container and run the command from inside the container. Luckily Azure CLI is available using the image `microsoft\azure-cli` the preview extension is not installed per default, so we handle that by running a little shell scripts that does all we need. A nice feature of ACI is that you can mount a git repository, which is exactly what the template does. It mounts this git repo and executes the shell script `run.sh` or `runzip.sh`depending on which parameters you provided. 

To make sure that the Azure CLI can authenticate, we provide two environment variables to the container, namely `AZURE_STORAGE_ACCOUNT` and `AZURE_STORAGE_KEY` if these are set the Azure CLI will attempt to use them for any storage operation. 

### Managing Cloudflare from Azure 
Another interesting concept used in this template, it the ability to manage external services from an ARM template using Azure Container Instances. In this template it is cloudflare, but it could in theory be any 3rd party service that has a CLI distributed as a docker image. The Cloudflare CLI docker image is not an official Cloudflare image, but that doesn't really matter, so if you want to use an CLI, and you cant find a container for it, you can always package it up in your own docker image. 

The authenticating with the Cloudflare CLI can be done using the environment variables `CF_API_KEY`, `CF_API_EMAIL` and `CF_API_DOMAIN` which is perfect as these values can be passed to the image using ACI environment variables. Working with the Cloudflare CLI is easy (check the [docs](https://www.npmjs.com/package/cloudflare-cli)). In this template we want to add two DNS entries, one for the `asverify.<domainname>` to make sure that we can configure the storage account with the custom DNS. You can ask, why use the asverify, and not just the actual domain name. The reason for not using the actual domain name is because we want to use Cloudflare SSL Proxy feature, which means that the DNS CNAME will not actually point the storage account domainname, thus the validation will fail when we have the Cloudflare SSL feature enabled. 

### Assigning Custom Domain Name to Azure Storage Account
At this stage in the template deployment, we want to assign our new domain name with the storage account. This can be done either with an ARM template or we can use the ARM API directly. The main challenge here, however is that we can't do it immediately we need to wait for the DNS change to propergate, which for cloudflare takes 2 min as that is the smallest TTL they support. 

So the real question, how do we delay the ARM template from continuing for two minutes? The answer is that to my knowledge that is not possible, so again we have to turn to our swiss knife, ACI where we can run a simple `sleep 120` before we execute the command we want to run. TBC
