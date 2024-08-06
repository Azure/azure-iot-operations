Write-Host "Creating archive..."

. ".\update-dependencies.ps1"

if (Test-Path "media-connector-demo.zip") {
    Write-Host "Removing existing archive..."
    Remove-Item "media-connector-demo.zip" -ErrorAction SilentlyContinue
}

Write-Host "Getting file list..."
$FileList = Get-ChildItem -Path "." -Exclude "media-connector-demo.zip","create-archive.ps1","update-dependencies.ps1"
Write-Host "Files to archive:"
$FileList | Sort-Object -Property Directory, Name | Format-Table -AutoSize -Property Name, LinkType, Directory | Out-String | Write-Host

Write-Host "Creating archive..."
$FileList | Compress-Archive -DestinationPath "media-connector-demo.zip" -Force
Write-Host "Archive created."

Write-Host "Done!"
