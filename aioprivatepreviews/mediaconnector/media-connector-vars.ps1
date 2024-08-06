$aioConnectorsNamespace = "aio-connectors"
Write-Host "Using namespace: $aioConnectorsNamespace"
Write-Host "`n"

$aioRuntimeVersion = "0.6.0-preview.4"
Write-Host "Using aio-runtime version: $aioRuntimeVersion"
Write-Host "`n"

$mqttAddress = 'mqtt://mosquitto.' + $aioConnectorsNamespace + ':1883'
Write-Host "Using MQTT address: $mqttAddress"
Write-Host "`n"

Write-Host "Media Connector Configuration:"
$mediaConnectorImageRegistryName = "aioconnectorsdev"
Write-Host "Media Connector Image Registry Name: $mediaConnectorImageRegistryName"
$mediaConnectorImageRegistryServer = "$mediaConnectorImageRegistryName.azurecr.io"
Write-Host "Media Connector Image Registry Server: $mediaConnectorImageRegistryServer"
$mediaConnectorImageRepository = "artifact/d065c211-cbf1-43f4-85d4-e52d2844e743/dev/media-broker"
Write-Host "Media Connector Image Repository: $mediaConnectorImageRepository"
$mediaConnectorImageTag = "0.1.0-alpha.dev.2024-06-12"
Write-Host "Media Connector Image Tag: $mediaConnectorImageTag"
$mediaConnectorConfigurationSchema = "https://aiobrokers.blob.core.windows.net/aio-media-connector/1.0.0.json"
Write-Host "Media Connector Configuration Schema: $mediaConnectorConfigurationSchema"
Write-Host "`n"

Write-Host "Monitoring Configuration:"
$monitoringNamespace = "aio-brokers-monitoring"
Write-Host "Using monitoring namespace: $monitoringNamespace"
$otelCollectorEndpoint = 'http://otel-collector.' + $monitoringNamespace + '.svc.cluster.local:4317'
Write-Host "Using OpenTelemetry collector endpoint: $otelCollectorEndpoint"
$connectorDeploymentName = "aio-brokers-sample-none"
Write-Host "Using connector deployment name: $connectorDeploymentName"
Write-Host "`n"
