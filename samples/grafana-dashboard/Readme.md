# AIO Sample Dashboard

### Overview
This Grafana dashboard is designed to monitor Azure IoT Operations, offering insights into health, usage, and error trends across clusters. It integrates with **Prometheus** as the data source and is built on Grafana **v11.6.3**. If you need assistance in deploying Observability components, see [this guide](https://learn.microsoft.com/en-us/azure/iot-operations/configure-observability-monitoring/howto-configure-observability).

### Dashboard Panels

1. **AIO Broker Health**  
   State timeline displaying health information on Azure IoT operations' Broker health.

1. **AIO Dataflow Health**  
   State timeline displaying health information on Azure IoT operations' Dataflow Operator health.

1. **Service Errors**  
   A timeseries panel tracking error rates across the service components like:
   - Broker Backpressure events
   - Authentication failures
   - Authorization failures
   - OPC-UA Connectors
   - Dataflow messages and errors

1. **AIO Kubernetes Workload Health**  
   State timeline reflecting Kubernetes pod and container health, including:
   - Workload readiness
   - Container restart rates
   - CPU and memory usage

1. **Kubernetes Node Health**  
   Monitors node statuses, such as CPU and memory health, as well as disk usage levels.

1. **Connector (OPC-UA) Assets and DataPoints**  
   Timeseries view showing the count of OPC-UA assets and data points.

1. **Broker**  
   - Monitors the total sessions and subscriptions in the Broker
   - Tracks messages published or received by category.
   - Tracks payload size published or received by category.

1. **Dataflows**
   - Displays number of active Dataflows and Dataflow Graphs
   - Displays messages received and sent by Endpoint Type
     
### Usage

1. **Add the Dashboard to Grafana**  
   Import this dashboard JSON file into Grafana.

1. **Configure Data Source**  
   Ensure the Prometheus data source is correctly set up and associated with `${DS_MANAGED_PROMETHEUS_INSTANCE}`.

1. **Viewing Data by Cluster**  
   Use the `$cluster` and `$namespace` variables to filter data by specific clusters and namespaces.

### Customization
- **Panel Thresholds**: Color-coded thresholds are set for various metrics. Adjust thresholds in the dashboard settings as needed for specific alerting requirements.
- **Time Ranges**: Modify time ranges for deeper insights into specific timeframes.
