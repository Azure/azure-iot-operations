# AIO Sample Dashboard

### Overview
This Grafana dashboard is designed to monitor Azure IoT Operations, offering insights into health, usage, and error trends across clusters. It integrates with **Prometheus** as the data source and is built on Grafana **v10.4.7**. If you need assistance in deploying Observability components, see [this guide](https://learn.microsoft.com/en-us/azure/iot-operations/configure-observability-monitoring/howto-configure-observability).

### Dashboard Panels

1. **AIO Health Model**  
   Text panel displaying general information on Azure IoT operations' overall health.

2. **AIO Service Health**  
   State timeline visualizes key health metrics across clusters, such as:
   - Authentication failures
   - Authorization denials
   - Message drops
   - Backpressure conditions

3. **Service Errors**  
   A timeseries panel tracking error rates across the service components like:
   - OPC-UA Connectors
   - Dataflow messages and errors

4. **AIO Kubernetes Workload Health**  
   State timeline reflecting Kubernetes pod and container health, including:
   - Workload readiness
   - Container restart rates
   - CPU and memory usage

5. **Kubernetes Node Health**  
   Monitors node statuses, such as CPU and memory health, as well as disk usage levels.

6. **Connector (OPC-UA) Assets and DataPoints**  
   Timeseries view showing the count of OPC-UA assets and data points.

7. **Broker Connected Sessions**  
   Monitors the active sessions of connected brokers and tracks messages published or received by category.

### Usage

1. **Add the Dashboard to Grafana**  
   Import this dashboard JSON file into Grafana.

2. **Configure Data Source**  
   Ensure the Prometheus data source is correctly set up and associated with `${DS_MANAGED_PROMETHEUS_INSTANCE}`.

3. **Viewing Data by Cluster**  
   Use the `$cluster` and `$namespace` variables to filter data by specific clusters and namespaces.

### Customization
- **Panel Thresholds**: Color-coded thresholds are set for various metrics. Adjust thresholds in the dashboard settings as needed for specific alerting requirements.
- **Time Ranges**: Modify time ranges for deeper insights into specific timeframes.
