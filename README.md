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


### Test application with PowerShell on Windows PC before conteinerization

1. Download and install Python from the link

**Python 3.13.1 used for testing**

Download from:[https://www.python.org/downloads/release/python-3131/](https://www.python.org/downloads/release/python-3131/)


2. Verify installed Python version

![python --version](https://github.com/user-attachments/assets/db0bf179-61a3-44dc-9fe1-099590cb3f95)


3. Clone git and enter the local repo folder
```
git clone https://github.com/nikolaynachkov/InfraTask.git
cd \InfraTask\
```

4. Create and activate a virtual environment

```
python -m venv C:\temp\venv\
C:\temp\venv\Scripts\activate.bat
```

5. Install the required packages.

```
pip install -r .\RequiredModules\modules.txt
```

6. Set environment variables for the application.
```
[Environment]::SetEnvironmentVariable("TIMEOUT", "2", "MACHINE")
[Environment]::SetEnvironmentVariable("PORT", "8090", "MACHINE")
[Environment]::SetEnvironmentVariable("URLS", "https://httpstat.us/503,https://httpstat.us/200", "MACHINE")
```

7. Run the application

```
python .\http_check\run.py
```

You will see the following output:

![python-run py](https://github.com/user-attachments/assets/f4a83a83-332f-4e26-89be-73bebc3ed586)


8. Check the application

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
You will a message saying that the application is shutting down.

<img width="400" alt="appshutdown" src="https://github.com/user-attachments/assets/7cab5f86-7fdb-4d45-b369-bfa6f91682a4" />


## Build Docker Image and upload it to a dockerhub repository

**Docker is required**

Download from: [https://docs.docker.com/desktop/setup/install/windows-install/](https://docs.docker.com/desktop/setup/install/windows-install/)


1. Build the Docker image

Ensure you are in folder InfraTask in PowerShell (where you synched the git repo and where Dockerfile is located)

```
docker build -t infratask:v1.0 .
```

2. Check the application if the container is working perfectly

```
docker run -p 8090:8090 --env-file .\env_var --name temp-container infratask
```
Browser  [http://localhost:8090](http://localhost:8090)

To see the metrics, browser to [http://localhost:8090/metrics](http://localhost:8090/metrics)



3. Login to your docker registry (create account if not having one), create new repository on **DockerHub** and push the image.

```
docker login
docker tag infratask:v1.0 [USERNAME]/infratask:v1.0
docker push [USERNAME]/infratask:v1.0
```


## Deploy The Application Container Image On local K8s Cluster

In **Kubernetes** directory, the **http_check.yaml** file contains the code for deployment of the image on a K8s cluster.

For a local k8s cluster we will use minikube as a solution

1. Download and install minikube, check the status.

Download and install instructions: [https://minikube.sigs.k8s.io/docs/start/?arch=%2Fwindows%2Fx86-64%2Fstable%2F.exe+download](https://minikube.sigs.k8s.io/docs/start/?arch=%2Fwindows%2Fx86-64%2Fstable%2F.exe+download)

```
minikube start --driver=docker
```

![minikube start](https://github.com/user-attachments/assets/2ff1fc9c-ab9b-4f0f-894c-0142b5c167b5)

```
minikube status
```

![minikube status](https://github.com/user-attachments/assets/6103c9f6-9049-4b6e-b145-d55e5c9368d4)

2. Create a namespace where to deploy the application and not to use the default one.

```
kubectl create ns http-check
```

3. Deploy application in the above created namespace

```
kubectl apply -f Kubernetes/http_check.yaml -n http-check
```

3. Display all the components deployed

```
kubectl get all -n sample-external-url
```

![kubectl get all -n http-check](https://github.com/user-attachments/assets/50a2fd3e-7ca4-4ce1-a94f-4caf6a9906f2)

4. Check if the application is working

```
kubectl port-forward service/sample-external-url-service 8080:80 -n sample-external-url
```

Browse to [http://localhost:8090](http://localhost:8090)

To see the metrics, browse to [http://localhost:8090/metrics](http://localhost:8090/metrics)

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
