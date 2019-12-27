$ResourceGroupName = "OpsStorageRGPS"
$StorageAccountName = "opssa1227"
$StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
$ContainerName = "testblob2"
New-AzStorageContainer -Name $ContainerName -Context $ctx

$localFileDirectory = "C:\images\"
$BlobName1 = "blanklaptop.jpg"
$BlobName2 = "containers.jpg"
$BlobName3 = "mentor.jpg"
$BlobName4 = "paused.jpg"

# upload blobs
Set-AzStorageBlobContent -File ($localFileDirectory + $BlobName1) -Container $ContainerName -Blob $BlobName1 -Context $ctx
Set-AzStorageBlobContent -File ($localFileDirectory + $BlobName2) -Container $ContainerName -Blob $BlobName2 -Context $ctx
Set-AzStorageBlobContent -File ($localFileDirectory + $BlobName3) -Container $ContainerName -Blob $BlobName3 -Context $ctx
Set-AzStorageBlobContent -File ($localFileDirectory + $BlobName4) -Container $ContainerName -Blob $BlobName4 -Context $ctx

# download blobs
$localFileDirectory = "C:\Downloads\"
Get-AzStorageBlobContent -Blob $BlobName1 -Container $ContainerName -Destination $localFileDirectory -Context $ctx
Get-AzStorageBlobContent -Blob $BlobName2 -Container $ContainerName -Destination $localFileDirectory -Context $ctx
Get-AzStorageBlobContent -Blob $BlobName3 -Container $ContainerName -Destination $localFileDirectory -Context $ctx
Get-AzStorageBlobContent -Blob $BlobName4 -Container $ContainerName -Destination $localFileDirectory -Context $ctx

# delete a blob
$BlobName = "containers.jpg"
Remove-AzStorageBlob -Blob $BlobName -Container $ContainerName -Context $ctx

# copy a blob
$BlobName = "mentor.jpg"
$NewBlobName = "CopyOf_" + $BlobName
Start-AzStorageBlobCopy -SrcBlob $BlobName -SrcContainer $ContainerName -DestContainer $ContainerName -DestBlob $newBlobName -Context $ctx

# list the blobs
Get-AzStorageBlob -Container $ContainerName -Context $ctx | Select Name

# read blob properties
$Blob = Get-AzStorageBlob -Context $ctx -Container $ContainerName -Blob $BlobName
$CloudBlockBlob = [Microsoft.Azure.Storage.Blob.CloudBlockBlob] $Blob.ICloudBlob
Write-Host "blob type = " $CloudBlockBlob.BlobType
Write-Host "blob name = " $CloudBlockBLob.Name
Write-Host "blob uri = " $CloudBlockBlob.Uri
$CloudBlockBlob.FetchAttributes()
Write-Host "content type = " $CloudBlockBlob.Properties.ContentType
Write-Host "size = " $CloudBlockBlob.Properties.Length

# set blob property
$ContentType = "image/jpg"
$CloudBlockBlob.Properties.ContentType = $ContentType
$CloudBlockBlob.SetProperties()
Write-Host "content type = " $CloudBlockBlob.Properties.ContentType
Write-Host "size = " $CloudBlockBlob.Properties.Length

# set blob metadata
$CloudBlockBlob.Metadata["version"] = "original"
$CloudBlockBlob.Metadata["author"] = "Kanye"
$CloudBlockBlob.SetMetadata()
$CloudBlockBlob.Metadata

# clear blob metadata
$CloudBlockBlob.Metadata.Clear()
$CloudBlockBlob.SetMetadata()
$CloudBlockBlob.Metadata
