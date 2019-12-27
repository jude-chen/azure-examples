# get storage account context
$ResourceGroupName = "OpsStorageRGPS"
$StorageAccountName = "opssa1227"
$StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

#create a new container that is private
$ContainerName2 = "secure"
#possible values for permission include Off/Blob/Container
New-AzStorageContainer -Name $ContainerName2 -Context $ctx  -Permission Off
#get a reference to the Container to use later
$Container = Get-AzStorageContainer -Name $ContainerName2 -Context $ctx

#upload a blob into the container
$localFileDirectory = "C:\images\"
$BlobName = "blanklaptop.jpg"
$localFile = $localFileDirectory + $BlobName
Set-AzStorageBlobContent -File $localFile -Container $ContainerName2 -Blob $BlobName -Context $ctx

# get a reference to the blob you uploaded, and convert it to a CloudBlockBlob,
# which will give you access to the properties and methods of the blob
$Blob = Get-AzStorageBlob -Context $ctx -Container $ContainerName2 -Blob $BlobName
$CloudBlockBlob = [Microsoft.Azure.Storage.Blob.CloudBlockBlob] $Blob.ICloudBlob

# retrieve the URI to try in the browser, for now the blob cannot be anonymously accessed
$CloudBlockBlob.Uri.AbsoluteUri

# get an ad hoc security access token
$sharedAccessBlobPolicy = New-Object Microsoft.Azure.Storage.Blob.SharedAccessBlobPolicy
# 5 minutes in the future
$selectDate = [DateTime]::Now.Add([TimeSpan]::FromMinutes(5))
# set the expiration date (must be in UTC)
$expirationDate = $selectDate.ToUniversalTime()
# set permissions to read
$sharedAccessBlobPolicy.Permissions = "r"
# set expiration time
$sharedAccessBlobPolicy.SharedAccessExpiryTime = $expirationDate
# pass the shared access properties to GetSharedAccessSignature to get the token
$sasToken = $CloudBlockBlob.GetSharedAccessSignature($sharedAccessBlobPolicy)

#Put the following URI in the browser and it works.
$wholeUri = $cloudblockblob.Uri.AbsoluteUri + $sasToken
write-host "uri = " $wholeUri
write-host "sas " $sasToken

# Another way is using a stored access policy
# set the expiration time to 5 minutes in the future
$selectDate = [DateTime]::Now.Add([TimeSpan]::FromMinutes(5))
$sharedAccessExpiryTime = $selectDate.ToUniversalTime()
# create a stored access policy for a container with the name TestPolicy
$policyName = "TestPolicy"
$sharedAccessBlobPolicy = New-Object Microsoft.Azure.Storage.Blob.SharedAccessBlobPolicy
# read, delete, list, none, write
$sharedAccessBlobPolicy.Permissions = "read"
# set the expiration time
$sharedAccessBlobPolicy.SharedAccessExpiryTime = $sharedAccessExpiryTime
# create the permissions object; you will add this to the container permissions
$blobContainerPermissions = New-Object Microsoft.Azure.Storage.Blob.BlobContainerPermissions
# clear the current blob container policies
$blobContainerPermissions.SharedAccessPolicies.Clear()
# add the policy
$blobContainerPermissions.SharedAccessPolicies.Add($policyName, $sharedAccessBlobPolicy)
# set the permissions on the actual container
$Container.CloudBlobContainer.SetPermissions($blobContainerPermissions)

#get SAS for blobs using the stored access policy
$sasToken = $cloudBlockBlob.GetSharedAccessSignature($null, $policyName);
#set up the URI for accessing the blob
$blobSASURI = $cloudblockblob.uri.absoluteuri + $sasToken;
write-host "### SAS associated with access policy ###"
write-host "SAS = " $sasToken
write-host "URI = " $blobSASURI

