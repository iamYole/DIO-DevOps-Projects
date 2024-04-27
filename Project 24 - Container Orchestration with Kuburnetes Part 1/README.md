# Container Orchestration with Kubernetes Part 1

In previous projects, we learnt about containers, it's usefulness, and how to containerize applications. In this project, we will be introduce to Container Orchestration and Kubernetes.

## **What is Container Orchestration**

Container Orchestration is the automated management and coordination of containerized applications which involves deploying, scaling, updating, and managing containers across a cluster of servers. There are several container orchestration platforms in the market Kubernetes, Docker Swarm, and Apache Mesos, and these softwares will be responsible for the orchestration of the containers. Kubernetes is the market leader in this category, and that's what we would be working with in this project.

**Kubernetes**, often abbreviated as K8s, is an open-source container orchestration platform originally developed by Google and now maintained by the Cloud Native Computing Foundation (CNCF). Kubernetes provides a platform for orchestrating containers, enabling efficient resource utilization, seamless scaling, and high availability.

### **The Kubernetes architecture**

Kubernetes is designed around a master-slave model, with a master node orchestrating multiple worker nodes.

![alt text](Images/Img_02.png)

At the heart of the architecture lies the **Kubernetes master**, which consists of several components:

- **API Server**: The API Server acts as the frontend for the Kubernetes control plane. It validates and processes RESTful API requests, serving as the primary entry point for all administrative tasks.
- **Scheduler**: Responsible for placing containers onto available nodes in the cluster based on resource requirements, workload constraints, and other policies.
- **Controller Manager**: Manages various controllers that regulate the state of the cluster, ensuring that the desired state matches the actual state and initiating corrective actions when necessary.
- **etcd**: A distributed key-value store that stores all cluster data, including configuration details, cluster state, and metadata. It serves as the Kubernetes' backing store for all cluster data.

On the **Kubernetes worker nodes**, the following components run:

- **Kubelet**: An agent that runs on each node and is responsible for communicating with the Kubernetes master. It manages containers on the node, ensuring that they are running and healthy.
- **Kube-proxy**: Maintains network rules on the host and performs connection forwarding for Kubernetes services. It enables communication between services within the cluster and from external clients to services running on the cluster.
- **Container Runtime**: The software responsible for running containers, such as Docker or containerd. It manages the lifecycle of containers, including starting, stopping, and managing their resources.

These components work together to provide the foundation for container orchestration in Kubernetes, enabling the deployment, scaling, and management of containerized applications across clusters of nodes.

![alt text](Images/Img_01.png)

I'll recommend you read more about these components and how the function from the Kubernetes official documentation [here](https://kubernetes.io/docs/concepts/overview/components/)

## Installing Kubernetes (k8s) from scratch

Installing and configuring a K8s cluster from scratch in a production or Corporate environment is quite a task especially when considering security and scalability of the environment. Luckily, there are managed versions of k8s already created by some software giants: Amazon Elastic Kubernetes Services (Amazon EKS), Google Kubernetes Engine (GKE) and Azure Kubernetes Services (AKS). There are also open source tools for running k8s locally or in a development environment as minikube, MicroK8s, K3s, etc.
