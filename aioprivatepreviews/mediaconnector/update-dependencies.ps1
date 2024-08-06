Write-Host "Updating dependencies..."

Write-Host "Updating aks-cluster scripts..."
Copy-Item -Path ..\..\scripts\aks-cluster\ -Destination . -Recurse -Force

Write-Host "Updating kubernetes-info scripts..."
Copy-Item -Path ..\..\scripts\kubernetes-info\ -Destination . -Recurse -Force

Write-Host "Updating monitoring distrib..."
Copy-Item -Path ..\..\distrib\monitoring\ -Destination . -Recurse -Force

Write-Host "Updating media-server distrib..."
Copy-Item -Path ..\..\distrib\media-server\ -Destination . -Recurse -Force

Copy-Item -Path ..\..\test-data\media\ -Destination . -Recurse -Force

Copy-Item -Path ..\..\test-components\media-web-server\ -Destination . -Recurse -Force

Write-Host "Dependencies updated."
