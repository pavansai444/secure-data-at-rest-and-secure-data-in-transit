# secure data at rest and secure data in transit

## Table of Contents

1. [Project Overview](#project-overview)
2. [Tools Used](#tools-used)
3. [Requirements](#requirements)
4. [Steps to Run the Project](#steps-to-run-the-project)
5. [Webapp Code](#webapp_code)
6. [Understanding Deployments](#understanding-deployments)
    - [MongoDB Configuration](#mongodb-configuration)
    - [MongoDB Sealed Secrets](#mongodb-sealed-secrets)
    - [Mutual TLS (mTLS) Configuration](#mutual-tls-mtls-configuration)
    - [MongoDB Image and Persistent Volume](#mongodb-image-and-persistent-volume)
    - [Web Application](#web-application)

### Project Overview

This repository demonstrates securing data at rest and in transit by implementing secure communication between two pods: a frontend pod and a backend pod. The frontend pod hosts a web application that connects to the backend pod running MongoDB. The communication between the pods is secured using mTLS provided by Istio. MongoDB is authenticated using a username and password retrieved from Kubernetes Sealed Secrets. Additionally, the MongoDB pod is backed by a LUKS-encrypted persistent volume, which is decrypted using a passphrase managed by HashiCorp Vault.

### Tools Used
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Minikube](https://img.shields.io/badge/Minikube-F5C452?style=for-the-badge&logo=minikube&logoColor=black)
![Istio](https://img.shields.io/badge/Istio-466BB0?style=for-the-badge&logo=istio&logoColor=white)
![HashiCorp Vault](https://img.shields.io/badge/HashiCorp%20Vault-000000?style=for-the-badge&logo=vault&logoColor=white)
![HTML](https://img.shields.io/badge/HTML5-E34F26?style=for-the-badge&logo=html5&logoColor=white)
![CSS](https://img.shields.io/badge/CSS3-1572B6?style=for-the-badge&logo=css3&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)

### Requirements

To set up and run this project, ensure the following tools and platforms are installed on a Linux-based operating system (preferably Ubuntu):

- **Docker**: For containerizing and running the application.
- **Kubernetes**: To orchestrate and manage containerized applications.
- **Minikube**: To create a local Kubernetes cluster for development and testing.
- **Istio**: For securing and managing service-to-service communication.
- **HashiCorp Vault**: To securely manage secrets and encryption keys.
- **Linux with LUKS support**: Ensure your operating system supports LUKS (Linux Unified Key Setup) for encrypting persistent volumes. Popular distributions like Ubuntu, Fedora, and CentOS include native LUKS support.

Make sure all dependencies are properly configured before proceeding with the setup.

### Steps to Run the Project

Follow the steps below to set up and run the project:

1. **Clone the Repository**  
    Clone this repository to your local machine using the following command:  
    ```bash
    git clone https://github.com/pavansai444/secure-data-at-rest-and-secure-data-in-transit.git
    cd secure-data-at-rest-and-secure-data-in-transit
    ```

2. **Ensure Prerequisites are Installed**  
    Verify that all the required tools and dependencies listed in the [Requirements](#requirements) section are installed and properly configured. Ensure Minikube is set up and running. Create a LUKS-encrypted image and mount it as `/dev/loop12` using the following steps:

    I. **Create a LUKS Encrypted Image**  
        Create a blank image file using the `dd` command:  
        ```bash
        dd if=/dev/zero of=luks-image.img bs=1M count=100
        ```

    II. **Initialize LUKS Encryption**  
         Format the image file with LUKS encryption:  
         ```bash
         cryptsetup luksFormat luks-image.img
         ```

    III. **Attach the Encrypted Image**  
          Open the encrypted image and map it to a virtual device:  
          ```bash
          cryptsetup open luks-image.img luks-loop
          ```

    IV. **Create a Filesystem**  
         Format the mapped device with a filesystem:  
         ```bash
         mkfs.ext4 /dev/mapper/luks-loop
         ```

    V. **Mount the Virtual Disk**  
        Mount the encrypted device to `/dev/loop12`:  
        ```bash
        mount /dev/mapper/luks-loop /dev/loop12
        ```
    Ensure the LUKS passphrase is securely stored in HashiCorp Vault as described in the [Set Up HashiCorp Vault](#set-up-hashicorp-vault) section.

3. **Set Up HashiCorp Vault**  
    - Follow the official [HashiCorp Vault Kubernetes Minikube tutorial](https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-consul) to create a Vault instance.
    - Store a secret in Vault containing the LUKS decryption passphrase. For example:
      ```bash
      vault kv put secret/luks-passphrase value=<your-luks-passphrase>
      ```

4. **Apply Deployment Configurations**  
    Run the provided `run.sh` script to apply all Kubernetes deployment configurations and secrets:  
    ```bash
    ./run.sh
    ```

5. **Verify the Setup**  
    - Ensure all pods are running successfully in your Minikube cluster:  
      ```bash
      kubectl get pods
      ```
    - Access the frontend web application and verify secure communication with the backend.

You are now ready to use the project!

### Webapp_Code
This repository contains the code for a web application used in webapp that interacts with a database. The application creates a database named `my-db` to store and retrieve user details. The docker image is available at pavansaibalaga/myapp.

### Understanding Deployments

1. **MongoDB Configuration**  
    The `mongo-config` Kubernetes ConfigMap is used to provide the MongoDB connection URL (`mongo-url`) to the web application. This configuration ensures the web application can connect to the MongoDB service.

2. **MongoDB Sealed Secrets**  
    The `mongo-sealed-secrets` Kubernetes Secret is used to securely store the MongoDB username and password required for authentication. This utilizes Kubernetes Sealed Secrets to ensure that sensitive information, such as passwords, is encrypted and not exposed in plain text within YAML files. Follow these steps to create a Sealed Secret using `kubeseal`:

    - Generate a standard Kubernetes Secret:
      ```bash
      kubectl create secret generic mongo-credentials --from-literal=username=<your-username> --from-literal=password=<your-password> --dry-run=client -o yaml > secret.yaml
      ```
    - Encrypt the Secret using `kubeseal`:
      ```bash
      kubeseal --format=yaml < secret.yaml > sealed-secret.yaml
      ```
    - Apply the Sealed Secret to the cluster:
      ```bash
      kubectl apply -f sealed-secret.yaml
      ```

3. **Mutual TLS (mTLS) Configuration**  
    - The `mTLS.yaml` file configures strict mutual TLS (mTLS) authentication between services. It includes an authorization policy that permits communication only between specific service accounts.
    - The `mTLS2.yaml` file provides a more relaxed configuration. It enforces strict mTLS for the MongoDB pod while allowing both mTLS and non-mTLS connections to the web application.

4. **MongoDB Image and Persistent Volume**  
    The `mongo-img` deployment includes an init container responsible for the following tasks:
    - Fetching the LUKS decryption passphrase from HashiCorp Vault.
    - Decrypting the LUKS-encrypted persistent volume.
    - Mounting the decrypted volume to `/data/db`, where MongoDB stores its database files.
    Once the init container completes, the main MongoDB container starts, handling requests from the web application. Upon termination, the LUKS volume is securely closed.

5. **Web Application**  
    The `webapp` deployment hosts the frontend web application, which serves user requests. It interacts with the MongoDB pod to store and retrieve user details. The web application ensures secure communication with the backend MongoDB service.
