$ResourceGroupName = "OpsStorageRGPS"
$StorageAccountName = "opssa1227"
$StorageAccountKey = (Get-AzStorageAccountKey -ResourceGroupName $ResourceGroupName -Name $StorageAccountName)[0].Value
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
$ContainerName = "testblob1"
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

#pick a file in the container that you want to work with
$BlobName = "mentor.jpg"
$Blob = Get-AzStorageBlob -Context $ctx -Container $ContainerName -Blob $BlobName
$CloudBlockBlob = [Microsoft.Azure.Storage.Blob.CloudBlockBlob] $Blob.ICloudBlob

#check for lease -- there isn't one yet, so all of these should be blank
$CloudBlockBlob.FetchAttributes()
Write-Host "LeaseStatus = " $CloudBlockBlob.Properties.LeaseStatus ", LeaseState = " $CloudBlockBlob.Properties.LeaseState", LeaseDuration = " $CloudBlockBlob.Properties.LeaseDuration

# Lease the blob for 30 seconds
$TimeSpan = [TimeSpan]"0:0:0:30"  #days, hours, minutes, seconds

# Acquiring the lease returns the lease ID
$LeaseID = $CloudBlockBlob.AcquireLease($TimeSpan, $null);

# load the properties, then print them out
$CloudBlockBlob.FetchAttributes()

Write-Host "LeaseStatus = " $CloudBlockBlob.Properties.LeaseStatus ", LeaseState = " $CloudBlockBlob.Properties.LeaseState ", LeaseDuration = " $CloudBlockBlob.Properties.LeaseDuration
Write-Host "LeaseID = " $LeaseID

# wait for the lease to expire and do this again
Start-Sleep 35
$CloudBlockBlob.FetchAttributes()
Write-Host "LeaseStatus = " $CloudBlockBlob.Properties.LeaseStatus `
    ", LeaseState = " $CloudBlockBlob.Properties.LeaseState `
    ", LeaseDuration = " $CloudBlockBlob.Properties.LeaseDuration

# you can renew the lease; it will renew it for the same amount of time
$accessCondition = New-Object Microsoft.Azure.Storage.AccessCondition;
$accessCondition.LeaseId = $LeaseID
$CloudBlockBlob.RenewLease($accessCondition)
$CloudBlockBlob.FetchAttributes()
Write-Host "LeaseStatus = " $CloudBlockBlob.Properties.LeaseStatus ", LeaseState = " $CloudBlockBlob.Properties.LeaseState ", LeaseDuration = " $CloudBlockBlob.Properties.LeaseDuration

#lease the blob for an unlimited amount of time, then release the lease
$LeaseID = $CloudBlockBlob.AcquireLease($null, $null);
$CloudBlockBlob.FetchAttributes()
Write-Host "LeaseStatus = " $CloudBlockBlob.Properties.LeaseStatus ", LeaseState = " $CloudBlockBlob.Properties.LeaseState ", LeaseDuration = " $CloudBlockBlob.Properties.LeaseDuration
$accessCondition = New-Object Microsoft.Azure.Storage.AccessCondition;
$accessCondition.LeaseId = $LeaseID
$CloudBlockBlob.ReleaseLease($accessCondition)
$CloudBlockBlob.FetchAttributes()
Write-Host "LeaseStatus = " $CloudBlockBlob.Properties.LeaseStatus ", LeaseState = " $CloudBlockBlob.Properties.LeaseState ", LeaseDuration = " $CloudBlockBlob.Properties.LeaseDuration

# lease the blob for an unlimited amount of time, then break the lease
$LeaseID = $CloudBlockBlob.AcquireLease($null, $null);
$CloudBlockBlob.FetchAttributes()
Write-Host "LeaseStatus = " $CloudBlockBlob.Properties.LeaseStatus ", LeaseState = " $CloudBlockBlob.Properties.LeaseState ", LeaseDuration = " $CloudBlockBlob.Properties.LeaseDuration
#Break the lease on the blob after 1 second
$TimeSpan2 = [TimeSpan]"0:0:0:01"  #days, hours, minutes, seconds
$CloudBlockBlob.BreakLease($TimeSpan2)
$CloudBlockBlob.FetchAttributes()
Write-Host "LeaseStatus = " $CloudBlockBlob.Properties.LeaseStatus ", LeaseState = " $CloudBlockBlob.Properties.LeaseState ", LeaseDuration = " $CloudBlockBlob.Properties.LeaseDuration

