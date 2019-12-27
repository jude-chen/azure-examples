# get storage account context
$ResourceGroupName = "OpsStorageRGPS"
$StorageAccountName = "opssa1227"
$StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey

# create a test container
$ContainerName = "snapshots"
New-AzStorageContainer -Name $ContainerName -Context $ctx -Permission Blob

# upload the first version of the RandomBlob.jpg blob
$localFileDirectory = "C:\images\"
$BlobName = "RandomBlob.jpg"
$localFileName = "paused.jpg"
$localFile = $localFileDirectory + $localFileName
Set-AzStorageBlobContent -File $localFile -Container $ContainerName -Blob $BlobName -Context $ctx

# create the first snapshot
$Blob = Get-AzStorageBlob -Context $ctx -Container $ContainerName -Blob $BlobName
$CloudBlockBlob = [Microsoft.Azure.Storage.Blob.CloudBlockBlob] $Blob.ICloudBlob
$CloudBlockBlob.Metadata["filename"] = $localFileName
$CloudBlockBlob.SetMetadata()
$CloudBlockBlob.CreateSnapshot()

# upload the second version of the RandomBlob.jpg blob and create the second snapshot
$localFileName = "mentor.jpg"
$localFile = $localFileDirectory + $localFileName
Set-AzStorageBlobContent -File $localFile -Container $ContainerName -Blob $BlobName -Context $ctx -Force
$CloudBlockBlob.Metadata["filename"] = $localFileName
$CloudBlockBlob.SetMetadata()
$CloudBlockBlob.CreateSnapshot()

# upload the third version of the RandomBlob.jpg blob and create the third snapshot
$localFileName = "containers.jpg"
$localFile = $localFileDirectory + $localFileName
Set-AzStorageBlobContent -File $localFile -Container $ContainerName -Blob $BlobName -Context $ctx -Force
$CloudBlockBlob.Metadata["filename"] = $localFileName
$CloudBlockBlob.SetMetadata()
$CloudBlockBlob.CreateSnapshot()

# list the blobs and snapshots in the test container
$Container = Get-AzStorageContainer -Name $ContainerName -Context $ctx
$Container.CloudBlobContainer.ListBlobs($BlobName, $true, "Snapshots") | select Name, SnapshotTime

$ListOfBlobs = $Container.CloudBlobContainer.ListBlobs($BlobName, $true, "Snapshots")

#loop through the base blob and the snapshots and write out the metadata entry for filename
foreach ($CloudBlockBlob in $ListOfBlobs) {
    #have to fetch attributes to get the metadata
    $CloudBlockBlob.FetchAttributes()
    Write-Host " snapshot time = " $CloudBlockBlob.SnapshotTime " filename = " $CloudBlockBLob.Metadata["filename"]
}

# copy each of the snapshots to a new blob with the original file name
foreach ($CloudBlockBlob in $ListOfBlobs) {
    if ($CloudBlockBlob.IsSnapshot)
    {
        #copy the snapshot to blob with the name of the original file name
        $CloudBlockBlob.FetchAttributes()
        $newBlobName = $CloudBlockBlob.Metadata["filename"]

        #copy the blob to the destination using the file name stored in the metadata
        Start-AzStorageBlobCopy -ICloudBlob $CloudBlockBlob -DestContainer $ContainerName -DestBlob $newBlobName -Context $ctx -Force
    }
}

Get-AzStorageBlob -Container $ContainerName -Context $ctx | select Name, SnapshotTime

#save the list so you can iterate through them
$ListOfBLobs = $Container.CloudBlobContainer.ListBlobs($BlobName, $true, "Snapshots")

#file name to search for
$fileNameTarget = "containers.jpg"

# look through the list of objects for the one where the filename in the metadata matches the target
# if found, set the $CloudBlockBlobSnapshot object to that blob snapshot and print a message
foreach ($CloudBlockBlob in $ListOfBLobs)
{
        $CloudBlockBlob.FetchAttributes()
        write-host "filename = " $CloudBlockBlob.Metadata["filename"]
        if ($CloudBlockBlob.Metadata["filename"] -eq $fileNameTarget)
        {
        write-host "match found"
        $CloudBlockBlobSnapshot = $CloudBlockBlob
        }
}

#promote the snapshot
#go get the reference to the original blob
$OriginalBlob = Get-AzStorageBlob -Context $ctx -Container $ContainerName -Blob $BlobName

#copy the snapshot over the original blob
Start-AzStorageBlobCopy -ICloudBlob $CloudBlockBlobSnapshot -DestICloudBlob $originalBLob.ICloudBlob -Context $ctx -Force

$originalblob.ICloudBlob.Uri.AbsoluteUri

#list the snapshot time so after you delete it, you can see that one's gone
$CloudBlockBlobSnapshot.SnapshotTime

#delete that snapshot from the blob
$CloudBlockBlobSnapshot.Delete()

#re-list the snapshots; you'll notice one is gone
$Container.CloudBlobContainer.ListBlobs($BlobName, $true, "Snapshots")

