# What is the media connector?

The media connector makes media from media sources such as edge attached cameras available to other Azure IoT Operations components. The media connector is secure, performant, and can connect to the following media sources:

| Media source | Example URLs | Notes |
|--------------| ---------------|-------|
| Edge attached camera | `file://host/dev/video0`<br/>`file://host/dev/usb0` | No authentication required. The URL refers to the device file. Connects to a node using USB, FireWire, MIPI, or proprietary interface. |
| IP camera | `rtsp://192.168.178.45:554/stream1` | JPEG over HTTP for snapshots, RTSP/RTCP/RTP/MJPEG-TS for video streams. An IP camera might also expose a standard ONVIF control interface. |
| Media server | `rtsp://192.168.178.45:554/stream1` | JPEG over HTTP for snapshots, RTSP/RTCP/RTP/MJPEG-TS for video streams. A media server can also serve images and videos using URLs such as `ftp://host/path` or `smb://host/path` |
| Media file | `http://camera1/snapshot/profile1`<br/>`nfs://server/path/file.extension`<br/>` file://localhost/media/path/file.mkv`  | Any media file with a URL accessible from the cluster. |
| Media folder | `file://host/path/to/folder/`<br/>`ftp://server/path/to/folder/` | A folder, accessible from the cluster, that contain media files such as snapshots or clips. |

Example uses of the media connector include:

- Capture snapshots from a video stream or from an image URL and publish them to an MQTT topic. A subscriber to the MQTT topic can use the captured images for further processing or analysis.

- Save video streams to a local file system on your cluster. [Edge Storage Accelerator](https://learn.microsoft.com/azure/azure-arc/edge-storage-accelerator/) can provide a reliable and fault-tolerant solution for uploading the captured video to the cloud for storage or processing.

- Proxy a live video stream from a camera to an endpoint that an operator can access. For security and performance reasons, only the media connector should have direct access to an edge camera. The media connector uses a separate media server component to stream video to an operator's endpoint. This media server can transcode to a variety of protocols such as RTSP, RTCP, SRT, and HLS.

## How does it relate to Azure IoT Operations?

The media connector component is part of Azure IoT Operations. The connector deploys to an Arc-enabled Kubernetes cluster on the edge as part of an Azure IoT Operations deployment. The connector interacts with other Azure IoT Operations elements, such as:

- _Asset endpoints_, which are custom resources in your Kubernetes cluster that define connections to resources such as cameras. An asset endpoint configuration includes the URL of the media source, the type of media source, and any credentials that are needed to access the media source. The media connector uses an asset endpoint to access the media source.

- _Assets_, which in Azure IoT Operations Preview are logical entities that you create to represent a real assets such as cameras. An Azure IoT Operations camera asset can have properties, tags, and video streams.

- The Azure IoT Operations portal, which is a web UI that provides a unified experience for you to manage assets such as cameras. You can use the portal to configure the assets and asset endpoints that the media connector uses to access media sources.

To control the media connector at runtime, you use an mRPC API. For usage examples, see [media-connector-mrpc-api.dib](media-connector-mrpc-api.txt).
