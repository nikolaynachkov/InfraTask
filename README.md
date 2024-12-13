## Projct Details and Overview
This is a **Python** application that is checking the availability and response time of external URLs and producing Prometheus format metrics at **http://appurl/metrics**. 
The steps below outline how the application can be executed on Windows PC in a minikube K8s single node cluster, locally using a docker image from a public dockerhub repository. 
Dockerfile exist to ease the conteinerization of the application.


Test URLs & metrics:-
1. [https://httpstat.us/200](https://httpstat.us/200)
    - **URL response time** (in milliseconds)
    - **URL up/down** (1 or 0 respectively)
2. [https://httpstat.us/503](https://httpstat.us/503)
    - **URL response time** (in milliseconds)
    - **URL up/down** (1 or 0 respectively)


### Testin application on Windows PC before conteinerization

1. Download and install Python from the link
**Python 3.13.1 used for testing**

[https://www.python.org/downloads/release/python-3131/](https://www.python.org/downloads/release/python-3131/)


2. Clone git and enter the folder
```
git clone https://github.com/nikolaynachkov/InfraTask.git
cd \InfraTask\
```

3. Verify installed Python version

![python --version](https://github.com/user-attachments/assets/db0bf179-61a3-44dc-9fe1-099590cb3f95)

4. Create and activate a virtual environment

```
python -m venv C:\temp\venv\
C:\temp\venv\Scripts\activate.bat
```

5. Install the required packages inside the environment

```
pip install -r .\RequiredModules\modules.txt
```

6. Set environment variables for the application.
```
[Environment]::SetEnvironmentVariable("TIMEOUT", "2", "MACHINE")
[Environment]::SetEnvironmentVariable("PORT", "8090", "MACHINE")
[Environment]::SetEnvironmentVariable("URLS", "https://httpstat.us/503,https://httpstat.us/200", "MACHINE")
```


5. Run the application

```
python .\http_check\run.py
```

You will see the following output:

![python-run py](https://github.com/user-attachments/assets/f4a83a83-332f-4e26-89be-73bebc3ed586)


6. Check the application

Point your browser to [http://localhost:8090](http://localhost:8090)
You will see:

![applicationisrunning](https://github.com/user-attachments/assets/91059856-aa61-4fd5-a5cb-a4b637223c69)

Point your browser to [http://localhost:8090/metrics](http://localhost:8090/metrics)
Prometheus style metrics will be displayed:

![Prometheus_metrics](https://github.com/user-attachments/assets/f04ab2f0-b78a-4406-b552-ecd47724c27f)

7. Exit the application in powershell
```
Ctrl + c
```
You will see a good bye message.

<img width="400" alt="appshutdown" src="https://github.com/user-attachments/assets/7cab5f86-7fdb-4d45-b369-bfa6f91682a4" />

## Building The Container Image For Production
**Docker is required**

1. Build the Docker image

```
docker build -t sample_external_url .
```

2. Check the application if the container is working perfectly

```
docker run -d -p 8080:8080 --env-file ./env-file --name sample sample_external_url
```
Open your browser and point to [http://localhost:8080](http://localhost:8080) you will see a text message.
To see the metrics point your browser to [http://localhost:8080/metrics](http://localhost:8080/metrics)

3. Create new repository on **DockerHub** or your preferred docker registry.

4. Login to your docker registry in console

```
docker login
```

5. Push the image to **DockerHub** or to your preferred docker registry

```
docker tag sample_external_url:latest [USERNAME]/sample_external_url:latest
docker push [USERNAME]/sample_external_url:latest
```

## Deploy The Application Container Image On K8s Cluster

The folder **k8s** contains the **sample_external_url.yaml** file which contains the code for **Kubernetes** deployment.

The file contains following segments:-

1. **CongfigMap** - This contains all the configuration of the application that is the environment variables.

2. **Deployment** - This contains the **k8s** deployment of the application. The **POD** refers to the **configmap** for the configuration. Image used for the **POD** is **image: himadriganguly/sample_external_url**, change that according to your registry url.

**Note:-** DockerHub URL [https://hub.docker.com/r/himadriganguly/sample_external_url](https://hub.docker.com/r/himadriganguly/sample_external_url)

3. **Service** - This will expose the application as **ClusterIP** on **port 80** and **targetPort 8080**. Change the **targetPort** value according to the **PORT** value in **configmap**.

### Deploy The Application

1. Create a namespace

```
kubectl create ns sample-external-url
```

2. Deploy application in the above created namespace

```
kubectl apply -f k8s/sample_external_url.yaml -n sample-external-url
```

3. Display all the components deployed

```
kubectl get all -n sample-external-url
```

![Kubectl Get All Resources](https://raw.githubusercontent.com/himadriganguly/sample_external_url/main/screenshots/kubectl-get-all.png "Kubectl Get All Resources")

**Note:-** Write down the **CLUSTER-IP** we would need it later.

4. Check the application

```
kubectl port-forward service/sample-external-url-service 8080:80 -n sample-external-url
```
Open your browser and point to [http://localhost:8080](http://localhost:8080) you will see a text message.
To see the metrics point your browser to [http://localhost:8080/metrics](http://localhost:8080/metrics)

## Deploy Prometheus

1. Get Repo Info

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
helm repo update
```

2. Install Chart

```
helm install prometheus prometheus-community/prometheus
```

**Note:-** [https://artifacthub.io/packages/helm/prometheus-community/prometheus](https://artifacthub.io/packages/helm/prometheus-community/prometheus)

## Deploy Grafana

1. Get Repo Info

```
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

2. Install Chart

```
helm install grafana grafana/grafana
```

**Note:-** [https://github.com/grafana/helm-charts/tree/main/charts/grafana](https://github.com/grafana/helm-charts/tree/main/charts/grafana)

3. Get the login username and password

```
kubectl get secrets grafana -o jsonpath='{.data.admin-password}' | base64 --decode | cut -d "%" -f1
kubectl get secrets grafana -o jsonpath='{.data.admin-user}' | base64 --decode | cut -d "%" -f1
```

## Update Prometheus Config To Scrape Metrics From The Application

1. Update configmap for Prometheus

```
kubectl edit cm/prometheus-server
```

2. Add the following config under **scrape_configs**

```
- job_name: 'sample_external'
      static_configs:
      - targets: ['CLUSTER-IP:80']
```
**Note:-** Replace **CLUSTER-IP** with the ip that we noted down earlier. In my case it will be **10.104.174.69**.

## Port Forward Prometheus And Grafana

1. Port forward Prometheus

```
kubectl port-forward service/prometheus-server 9090:80
```

2. Port forward Grafana

```
kubectl port-forward service/grafana 3000:80
```

3. Open Prometheus

Open your browser and point to [http://localhost:9090](http://localhost:9090) you will see **Prometheus UI**.

4. Check Prometheus config

Open your browser and point to [http://localhost:9090](http://localhost:9090) you will see **Prometheus UI**. Go to **Status** > **Configuration** and you can see that your configuration has been added under **scrape_configs:**.

![Prometheus Configuration](https://raw.githubusercontent.com/himadriganguly/sample_external_url/main/screenshots/prometheus-config.png "Prometheus Configuration")

5. Check **Prometheus** metrics collected from our **Application**

![Prometheus External URL Response Milliseconds](https://raw.githubusercontent.com/himadriganguly/sample_external_url/main/screenshots/prometheus-external-url-response-ms-table.png "Prometheus External URL Response Milliseconds")

![Prometheus External URL Response Milliseconds](https://raw.githubusercontent.com/himadriganguly/sample_external_url/main/screenshots/prometheus-external-url-response-ms.png "Prometheus External URL Response Milliseconds")

![Prometheus External URL Up](https://raw.githubusercontent.com/himadriganguly/sample_external_url/main/screenshots/prometheus-external-url-up-table.png "Prometheus External URL Up")

![Prometheus External URL Up](https://raw.githubusercontent.com/himadriganguly/sample_external_url/main/screenshots/prometheus-external-url-up.png "Prometheus External URL Up")

6. Open Grafana

Open your browser and point to [http://localhost:3000](http://localhost:3000) you will see **Grafana Login**.

Enter the **username** and **password** we already collected to login.

## Add Prometheus Data Source To Grafana

1. Open Grafana

Open your browser and point to [http://localhost:3000](http://localhost:3000) you will see **Grafana Login**.

Enter the **username** and **password** we already collected to login.

2. Click on **Configuration** > **Data Sources**

3. Click on **Add data source**

![Grafana Add Data Source](https://raw.githubusercontent.com/himadriganguly/sample_external_url/main/screenshots/grafan-configuration.png "Grafana Add Data Source")

4. Select **Prometheus** as the data source

![Grafana Add Data Source Prometheus](https://raw.githubusercontent.com/himadriganguly/sample_external_url/main/screenshots/grafan-configuration-add-data-source.png "Grafana Add Data Source Prometheus")

5. Check Prometheus cluster ip

```
kubectl get svc
```

**Note:-** Write down the **ClusterIP** for **prometheus-server**

![Kubectl Get Prometheus Cluster IP](https://raw.githubusercontent.com/himadriganguly/sample_external_url/main/screenshots/kubectl-get-svc.png "Kubectl Get Prometheus Cluster IP")

6. Add the **ClusterIP** as the **Prometheus** url

![Grafana Add Data Source Prometheus IP](https://raw.githubusercontent.com/himadriganguly/sample_external_url/main/screenshots/grafan-configuration-add-data-source-prometheus.png "Grafana Add Data Source Prometheus IP")

7. Click **Save & Test**


## Import Grafana Dashboard

1. Click on **Create** > **Import**

2. Click on **Upload JSON file** and select the file from the **grafana** folder within this repository.

![Import Grafan Dashboard Step1](https://raw.githubusercontent.com/himadriganguly/sample_external_url/main/screenshots/grafan-import-dashboard1.png "Import Grafan Dashboard Step1")

![Import Grafan Dashboard Step2](https://raw.githubusercontent.com/himadriganguly/sample_external_url/main/screenshots/grafan-import-dashboard2.png "Import Grafan Dashboard Step2")

3. Click on **Import** button it will create the dashboard with the **Prometheus** metrics.

![Import Grafan Dashboard Step3](https://raw.githubusercontent.com/himadriganguly/sample_external_url/main/screenshots/grafan-import-dashboard3.png "Import Grafan Dashboard Step3")

test2
