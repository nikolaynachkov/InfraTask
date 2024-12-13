## Project Details and Overview
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
Browse to  [http://localhost:8090](http://localhost:8090)

To see the metrics, browser to [http://localhost:8090/metrics](http://localhost:8090/metrics)



3. Login to your docker registry (create account if not having one), create new repository on **DockerHub** and push the image. (USERNAME is the one used for Docker registration)

```
docker login
docker tag infratask:v1.0 USERNAME/infratask:v1.0
docker push USERNAME/infratask:v1.0
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
kubectl port-forward service/http-check-service 8090:8090 -n http-check
```

Browse to [http://localhost:8090](http://localhost:8090)

To see the metrics, browse to [http://localhost:8090/metrics](http://localhost:8090/metrics)


6. When you verify the image is working, stop kubectl port-forward and delete the newly created namespace.

```
Ctrl + c
kubectl delete ns http-check
```

## Use Helm chart to deploy the container on the cluster

1. Download and install Helm

Download link: [https://github.com/helm/helm/releases](https://github.com/helm/helm/releases)

Extract Helm binary into C:\Helm and add it to SYSTEM wide PATH variable. In PowerShell navigate to InfraTask folder.

2. Helm chart is already created in .\httpcheckapp, you just need to install it and check the status

```
helm install initial .\httpcheckapp --namespace http-check-helmchart --create-namespace --wait
kubectl get all -n http-check-helmchart
```

3. When you verify the pods are running, execute kubectl port-forward

```
kubectl port-forward service/initial-httpcheckapp 8090:8090 -n http-check-helmchart
```

Browse to [http://localhost:8090](http://localhost:8090)

To see the metrics, browse to [http://localhost:8090/metrics](http://localhost:8090/metrics)

4. Stop port-forward, uninstall Helm chart and delete the namespace.

```
Ctrl + c
helm uninstall initial .\httpcheckapp --namespace http-check-helmchart
kubectl delete ns http-check-helmchart
```

6. Delete minikube cluster from local system

```
minikube delete
```

![minikube delete](https://github.com/user-attachments/assets/c0365e90-40a9-4159-8ebe-85649beed081)

