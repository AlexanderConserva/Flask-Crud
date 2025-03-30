# Flask CRUD App - Azure Deployment Guide

## Overview
This project deploys a Flask CRUD application in Azure using **Azure Container Registry (ACR)** and **Azure Container Instances (ACI)**. The infrastructure is defined using **Bicep** templates.


## Step 1: Clone The Git Repository & Login In Azure
```sh
git clone https://github.com/AlexanderConserva/Flask-Crud.git
```

```sh
az login
```

## Step 2: Create a Resource Group & Deploy Azure Container Registry (ACR) Using Bicep
```sh
az group create --name flask-crud-rg-ac --location westeurope
```

```sh
az deployment group create --resource-group flask-crud-rg-ac --template-file acr_bicep.bicep
```

## Step 3: Login To The Container Registry
```sh
az acr login --name flaskcrudacrac
```

## Step 4: Build & Push Docker Image To ACR

```sh
docker build -t flaskcrudacrac.azurecr.io/flask-crud-app:latest .
```

```sh
docker push flaskcrudacrac.azurecr.io/flask-crud-app:latest
```

## Step 5: Deploy the Application

```sh
az deployment group create --resource-group flask-crud-rg-ac --template-file main_bicep.bicep
```

## Step 5: Get The Public Ip
```sh
az container show --resource-group flask-crud-rg-ac --name flaskcrudaciac --query ipAddress.ip --output tsv
```

Use the displayed **Public IP** to access your Flask CRUD application.

## Step 6: View Logs

```sh
az container logs --resource-group flask-crud-rg-ac --name flaskcrudaciac
```


**Now your Flask CRUD app is running on Azure!**