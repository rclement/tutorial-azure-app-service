# Tutorial for Azure App Service deployment

> Deploy a Python Streamlit app with Azure App Service

## Azure CLI

### Setup

1. [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. [Authenticate with Azure CLI](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli)

## Azure App Service

For ease of deployment, we will use Azure App Service for Linux which allows
developers to deploy web applications with a PaaS experience, similar to Heroku.

Supported web frameworks in Python are Flask and Django. For other non-supported
frameworks such as FastAPI, a Docker image is required.

First step is to make sure a ressource group is available. If not, a new one
can be created:

```bash
az group create \
    --name tutorial-azure-app-service-group \
    --location westeurope
```

### Flask app deployment

As Flask is one of the two Python frameworks natively supported by Azure App Service
(the other one being Django), we are going to take advantage of this and deploy a
simple Flask app using Git!

Documentation:

- [Quickstart Azure App Service for Python](https://docs.microsoft.com/en-us/azure/app-service/quickstart-python)
- [Configure Python for Azure App Service](https://docs.microsoft.com/en-us/azure/app-service/configure-language-python)
- [Azure App Service deploy with Git](https://docs.microsoft.com/en-us/azure/app-service/deploy-local-git)
- [Azure App Service configure credentials](https://docs.microsoft.com/en-us/azure/app-service/deploy-configure-credentials?tabs=cli)

1. Configure a deployment user (might require `git config --system --unset credential.helper` before-hand):

```bash
az webapp deployment user set --user-name <username> --password <password>
```

2. Create a Git enabled app

```bash
az appservice plan create \
    --name tutorial-azure-app-service-flask-plan \
    --resource-group tutorial-azure-app-service-group \
    --is-linux \
    --sku F1

az webapp create \
    --name tutorial-azure-app-service-flask-app \
    --resource-group tutorial-azure-app-service-group \
    --plan tutorial-azure-app-service-flask-plan \
    --runtime "PYTHON|3.8" \
    --deployment-local-git
```

3. Configure the deployment branch:

```bash
az webapp config appsettings set \
    --name tutorial-azure-app-service-flask-app \
    --resource-group tutorial-azure-app-service-group \
    --settings DEPLOYMENT_BRANCH='master'
```

4. Add the Git remote:

```bash
git remote add azure-flask https://tutorial-azure-app-service-flask-app.scm.azurewebsites.net/tutorial-azure-app-service-flask-app.git
```

5. Deploy to Azure:

```bash
git push azure-flask master
```

6. Open the app: https://tutorial-azure-app-service-flask-app.azurewebsites.net

7. To delete the app:

```bash
az webapp delete \
    --name tutorial-azure-app-service-flask-app \
    --resource-group tutorial-azure-app-service-group
```

### Streamlit app deployment

In order to deploy a Streamlit app on Azure App Service, we will need to build
and deploy a Docker container.

Documentation: [Azure App Service Custom Container](https://docs.microsoft.com/en-us/azure/app-service/tutorial-custom-container)

1. Build and run the Docker image locally:

```bash
docker build -t tutorial-azure-app-service-streamlit-app:latest .
docker run --rm -it -p "5000:5000" tutorial-azure-app-service-streamlit-app:latest
```

2. Create an Azure Container Registry to push the Docker image:

```bash
az acr create \
    --name TutorialAzureAppServiceRegistry \
    --resource-group tutorial-azure-app-service-group \
    --sku Basic \
    --admin-enabled true
```

3. Get the credentials for Azure Container Registry:

```bash
az acr credential show \
    --name TutorialAzureAppServiceRegistry \
    --resource-group tutorial-azure-app-service-group
```

4. Log into Azure Container Registry using Docker:

```bash
docker login TutorialAzureAppServiceRegistry.azurecr.io --username TutorialAzureAppServiceRegistry
```

5. Tag and push the Docker image to Azure Container Registry:

```bash
docker tag tutorial-azure-app-service-streamlit-app TutorialAzureAppServiceRegistry.azurecr.io/tutorial-azure-app-service-streamlit-app:latest
docker push TutorialAzureAppServiceRegistry.azurecr.io/tutorial-azure-app-service-streamlit-app:latest
```

6. Verify the Docker image has been pushed:

```bash
az acr repository list --name TutorialAzureAppServiceRegistry
```

7. Create the Azure App Service:

```bash
az appservice plan create \
    --name tutorial-azure-app-service-streamlit-plan \
    --resource-group tutorial-azure-app-service-group \
    --is-linux \
    --sku F1

az webapp create \
    --name tutorial-azure-app-service-streamlit-app \
    --resource-group tutorial-azure-app-service-group \
    --plan tutorial-azure-app-service-streamlit-plan \
    --deployment-container-image-name TutorialAzureAppServiceRegistry.azurecr.io/tutorial-azure-app-service-streamlit-app:latest

az webapp config appsettings set \
    --name tutorial-azure-app-service-streamlit-app \
    --resource-group tutorial-azure-app-service-group \
    --settings WEBSITES_PORT=5000

az webapp identity assign \
    --name tutorial-azure-app-service-streamlit-app \
    --resource-group tutorial-azure-app-service-group \
    --query principalId \
    --output tsv

az role assignment create \
    --assignee <principal-id> \
    --scope /subscriptions/<subscription-id>/resourceGroups/tutorial-azure-app-service-group/providers/Microsoft.ContainerRegistry/registries/TutorialAzureAppServiceRegistry \
    --role "AcrPull"

az resource update \
    --ids /subscriptions/<subscription-id>/resourceGroups/tutorial-azure-app-service-group/providers/Microsoft.Web/sites/tutorial-azure-app-service-streamlit-app/config/web \
    --set properties.acrUseManagedIdentityCreds=True

az webapp config container set \
    --name tutorial-azure-app-service-streamlit-app \
    --resource-group tutorial-azure-app-service-group \
    --docker-custom-image-name TutorialAzureAppServiceRegistry.azurecr.io/tutorial-azure-app-service-streamlit-app:latest \
    --docker-registry-server-url https://TutorialAzureAppServiceRegistry.azurecr.io
```

8. Whenever a new Docker image is pushed to the registry, restart the App Service:

```bash
az webapp restart \
    --name tutorial-azure-app-service-streamlit-app \
    --resource-group tutorial-azure-app-service-group
```
