#!/bin/sh

az extension add --name storage-preview
az storage blob service-properties update --static-website --404-document error.html --index-document index.html

az storage blob upload-batch -s /mnt/content/dist -d "\$web"