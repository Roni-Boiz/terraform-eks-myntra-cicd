# Terraform-EKS-GitHub-Actions-Docker-Scout

Automation is at the heart of modern software development, and tools like GitHub Actions, AWS EKS, and Terraform are transforming how developers manage and deploy applications. GitHub Actions enables seamless CI/CD pipelines, automating everything from code integration to deployment. When combined with AWS EKS, developers can efficiently manage Kubernetes clusters, ensuring scalable and resilient applications. Terraform adds another layer by automating infrastructure as code, making the entire deployment process smoother and more reliable. SonarQube, Trivy, Docker Scout use for code analysis and vulnerability scans. In this repository, I will demonstrate how these technologies work together to streamline development and deployment workflows.

![AWS-EKS-Terraform-GitHub-Actions](https://github.com/user-attachments/assets/48f42701-e8d2-4cb1-a807-fec88faa0d5d)


## Prerequisites

1. **AWS Account:** Sign up at [aws.amazon.com](https://aws.amazon.com/).
2. **DockerHub Account:** For deploying a containerized application, register for [DockerHub](https://hub.docker.com/).
3. **Slack Account:** To get pipeline feedback in Slack channel. Sign up at [slack.com](https://slack.com/).


## Steps to deploy Application in EKS

### Step 1: Steup EC2 Instance

1. #### Create EC2 Instance

    To launch an AWS EC2 instance with Ubuntu latest (24.04) using the AWS Management Console, sign in to your AWS account, access the EC2 dashboard, and click “Launch Instances.” In “Step 1,” select “Ubuntu 24.04” as the AMI, and in “Step 2,” choose “t3.large” as the instance type. Configure the instance details, storage (20 GB), tags , and security group ( make sure to create inbound rules to allow tcp traffic on port 22, 80, 443, 9000, 3000 [optional] ) settings according to your requirements. Review the settings, create or select a key pair for secure access, and launch the instance. Once launched, you can connect to it via SSH using the associated key pair or through management console.

    ![ec2-instance](https://github.com/user-attachments/assets/1e3d4ef9-30f4-4af2-a46f-9e5e056340aa)


3. #### Create IAM Role

    To create a new role for manage AWS resource through EC2 Instance in AWS, start by navigating to the AWS Console and typing “IAM” to access the Identity and Access Management service. Click on “Roles,” then select “Create role.” Choose “AWS service” as the trusted entity and select “EC2” from the available services. Proceed to the next step and use the “Search” field to add the necessary permissions policies, such as "Administrator Access" or "EC2 Full Access", "AmazonS3FullAccess" and "EKS Full Access". After adding these permissions, click "Next." In the “Role name” field, enter “EC2 Instance Role” and complete the process by clicking “Create role”.

    ![ec2-role-1](https://github.com/user-attachments/assets/781618f5-dce2-483d-a3d5-68df92d8367d)
   
    ![ec2-role-2](https://github.com/user-attachments/assets/6ee90b60-09c6-49d1-acda-5eb0befc9164)
   
    ![ec2-role-3](https://github.com/user-attachments/assets/b314bade-f007-4fe0-a144-1677bc36b4f2)


2. #### Attach IAM Role

    To assign the newly created IAM role to an EC2 instance, start by navigating to the EC2 dashboard in the AWS Console. Locate the specific instance where you want to add the role, then select the instance and choose "Actions." From the dropdown menu, go to "Security" and click on "Modify IAM role." In the next window, select the newly created role from the list and click on "Update IAM role" to apply the changes.

    ![attach-role-1](https://github.com/user-attachments/assets/5ebcc1a6-eadb-400d-b94b-c8f2728a86cb)

    ![attach-role-2](https://github.com/user-attachments/assets/f84e5f8b-e65b-4aaf-b6ad-4ef51f381f8d)


### Step 2: Setup Self-Hosted Runner on EC2

1. #### In GitHub

   To set up a self-hosted GitHub Actions runner, start by navigating to your GitHub repository and clicking on Settings. Go to the Actions tab and select Runners. Click on New self-hosted runner and choose Linux as the operating system with X64 as the architecture. Follow the provided instructions to copy the commands required for installing the runner (Settings --> Actions --> Runners --> New self-hosted runner).

   ![runner-1](https://github.com/user-attachments/assets/1142e703-0ea5-4124-9581-235f77dcbef0)

   ![runner-2](https://github.com/user-attachments/assets/349499d6-05d9-4781-a182-08ea354c4d85)
   
   **Download Code**
   ```bash
   # Create a folder
   $ mkdir actions-runner && cd actions-runner
   # Download the latest runner package
   $ curl -o actions-runner-linux-x64-2.319.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.319.1/actions-runner-linux-x64-2.319.1.tar.gz
   # Optional: Validate the hash
   $ echo "3f6efb7488a183e291fc2c62876e14c9ee732864173734facc85a1bfb1744464  actions-runner-linux-x64-2.319.1.tar.gz" | shasum -a 256 -c
   # Extract the installer
   $ tar xzf ./actions-runner-linux-x64-2.319.1.tar.gz
   ```

   **Configure Code**
   ```bash
   # Create the runner and start the configuration experience
   $ ./config.sh --url https://github.com/Roni-Boiz/terraform-eks-myntra-cicd --token <your-token>
   # Last step, run it!
   $ ./run.sh
   ``` 

3. #### In EC2 Instance

   Next, connect to your EC2 instance via SSH or management console (wait till all checks passed in EC2 Instance), and paste the commands in the terminal to complete the setup and register the runner. When you enter `./config.sh` enter follwoing details:

   - runner group --> keep as default
   - name of runner --> git-workflow
   - runner labels --> git-workflow
   - work folder --> keep default

   ![runner-3](https://github.com/user-attachments/assets/5dc80b6d-3d52-4fa5-a220-2bfa767ae1b6)

> [!TIP]
> At the end you should see **Connected to GitHub** message upon successful connection


### Step 3: Setup SonarQube

1. #### Install 

   Once the runner is setup it will start accepting pending jobs in the queue. First it will install all requrest software packeges to EC2 instance (docker, trivy, java, aws cli, kubectl, terraform).
   
   ![partial-script-pipeline](https://github.com/user-attachments/assets/b20d2fd7-7f1f-475f-8b85-895701f442fc)

   So once the `docker` is installed, in meantime you can setup `sonarqube` in EC2 instance. For that execute following code in seperate terminal of EC2 instance,

    ```bash
    $ docker run -d --name sonar -p 9000:9000 sonarqube:lts-community
    ```
    
    ![sonar-1](https://github.com/user-attachments/assets/035debca-16e9-4092-9c24-2cdf2418b0d4)

3. #### Integrate

   To integrate SonarQube with GitHub Actions for automatic code quality and security analysis, begin by copying the IP address of your EC2 instance (formatted as <ec2-public-ip:9000>) and logging into SonarQube using the default credentials (**username: admin, password: admin**). Once logged in, update your password, and you will reach the SonarQube dashboard. Click on Manually to create a new project, provide a project name and branch name, and click on Set up. On the next page, choose With GitHub Actions to receive integration instructions.
    
   ![sonar-2](https://github.com/user-attachments/assets/284d14b5-cb7f-4a4f-bb39-da59883baf20)

   ![sonar-3](https://github.com/user-attachments/assets/4386e054-f3a9-4b46-9e0e-da4f886f976b)

   ![sonar-4](https://github.com/user-attachments/assets/d5541f23-a1b3-44e8-96bb-776e4d35c9fd)

   ![sonar-5](https://github.com/user-attachments/assets/545ea1c7-f916-414e-9c53-3d532ddb6356)

   ![sonar-6](https://github.com/user-attachments/assets/137ed008-862d-42f5-9d04-da0f03d59321)

   Open your GitHub repository, go to Settings, and navigate to Secrets and variables under Actions. Click New repository secret. Return to the SonarQube dashboard, generate a token under `SONAR_TOKEN`, copy it, and add it as a secret in GitHub with the name `SONAR_TOKEN`. Repeat this process to add other required secret `SONAR_HOST_URL`.

   ![sonar-7](https://github.com/user-attachments/assets/04d2cae6-6de6-4472-be2b-ef01706be826)

   ![sonar-8](https://github.com/user-attachments/assets/e1e17372-921d-4a2a-ad78-8fe0f51b17dc)

   ![sonar-9](https://github.com/user-attachments/assets/1853a01a-23d5-4b20-880a-acf979f32c43)

   ![sonar-10](https://github.com/user-attachments/assets/dacb86a6-5a0c-4e93-9b06-2905472eabde)

   ![sonar-11](https://github.com/user-attachments/assets/f0d65831-bf6d-45b1-a5b2-aabc719dafd4)

   ![sonar-12](https://github.com/user-attachments/assets/7ce0dfcc-6fc5-4420-9d31-30374ca361a3)

   Back on the SonarQube dashboard, click Continue and create a workflow file for your project, selecting the appropriate framework (e.g., for React JS choose other). SonarQube will generate the necessary workflow file. Go to GitHub, click Add file, and create a new file named `sonar-project.properties` with the provided content, such as `sonar.projectKey=myntra`. This file ensures the integration is set up properly, allowing SonarQube to analyze your code as part of your CI/CD pipeline (this part is already done, you need to update them accordingly).


### Sept 4: Setup DockerHub

1. #### Create Access Token

   To create a Personal Access Token for your Docker Hub account, start by navigating to Docker Hub, clicking on your profile, and selecting Account settings. Go to Security and click on New access token. Provide a name for your token and click Generate token. Make sure to copy the token and save it in a secure location, as it will not be shown again.

   ![docker-1](https://github.com/user-attachments/assets/bcc26fbf-955d-482a-93e9-e91939116494)

2. #### Create Repository Secrets

   Next, go to your GitHub repository, click on Settings, and navigate to Secrets and variables under Actions. Click New repository secret and add your Docker Hub username with the secret name `DOCKERHUB_USERNAME`. Click Add Secret. Then, create another repository secret by clicking New repository secret again, name it `DOCKERHUB_TOKEN`, paste the generated token, and click Add secret.

   ![docker-2](https://github.com/user-attachments/assets/c0c1ea89-61e8-4668-ad67-98fe7a8fb1bd)

   ![docker-3](https://github.com/user-attachments/assets/0253e31c-c274-4ff8-9da7-a75f22e6edc2)

    This securely stores your Docker Hub credentials in GitHub for use in your workflows.

    ![docker-4](https://github.com/user-attachments/assets/7f6d7679-2daa-42a4-9557-00d0278215df)

> [!NOTE]
> Don't forget to update the image tag/name in all the places `.github/workflows/cicd.yml` and `manifests/deployment-service.yml` if you want to use a custum image.

3. #### Enable Docker Scout (Optional)

   Follow the instruction on [docker scout](https://scout.docker.com/) official website to enable docker scout for your repository images.

> [!NOTE]
> For more informations read this [producct guide](https://www.docker.com/products/docker-scout/)


### Step 5: Setup Slack

1. #### Create Channel

   To set up Slack notifications for your GitHub Actions workflow, start by creating a Slack channel `github-actions` if you don't have one. Go to your Slack workspace, create a channel specifically for notifications, and then click on Home.

   ![slack-1](https://github.com/user-attachments/assets/ed0d7a42-81aa-4ab8-a832-b3e4a442dd88)

2. #### Create App

   From the Home click on Add apps than click App Directory. This opens a new tab; click on Manage then click on Build and then Create New App.

   ![slack-2](https://github.com/user-attachments/assets/aa6fbecc-994b-438c-85d7-a16e2f3f8157)

   ![slack-3](https://github.com/user-attachments/assets/a73b7f0f-770c-44b0-bd4f-dc63573f9258)

   ![slack-4](https://github.com/user-attachments/assets/f5b01404-7258-4987-be95-69c46d5f2575)

   ![slack-5](https://github.com/user-attachments/assets/54ca8cbc-978b-4d13-92cb-7a3a70909a8d)

   Choose From scratch, provide a name for your app, select your workspace, and click Create. Next, enable Incoming Webhooks by setting it to "on," and click Add New Webhook to Workspace. Select the newly created channel for notifications and grant the necessary permissions.

   ![slack-6](https://github.com/user-attachments/assets/7a8b0122-463d-4fbb-8533-d518eaccd930)
   
   ![slack-7](https://github.com/user-attachments/assets/36b8e488-b641-4dde-99f0-7d1ab46e40e7)
   
   ![slack-8](https://github.com/user-attachments/assets/c41984d3-4dc2-407c-8e28-c5e472f9e14e)
   
   ![slack-9](https://github.com/user-attachments/assets/3237e7d0-5620-4d7c-97cd-2de12da0ed5b)

3. #### Create Repository Secret

    This generates a webhook URL—copy it and go to your GitHub repository settings. Navigate to Secrets > Actions > New repository secret and add the webhook URL as a `SLACK_WEBHOOK_URL` secret.

    ![slack-10](https://github.com/user-attachments/assets/ca38c027-8abc-4e55-a1ef-60d1f8f5e823)
   
    ![slack-11](https://github.com/user-attachments/assets/9329e223-f771-428c-bef4-5e5cfbee477a)

This setup ensures that Slack notifications are sent using the act10ns/slack action, configured to run "always"—regardless of job status—sending messages to the specified Slack channel via the webhook URL stored in the secrets.

> [!NOTE]
> Don't forget to update the **channel name** (not the app name) you have created in all the places `.github/workflows/terrafrom.yml`, `.github/workflows/cicd.yml`, `.github/workflows/destroy.yml`.


### Step 6: Pipeline

If you go to repository actions tab, following workflows will execute in background `Script --> Terraform --> CI/CD Pipeline`. Wait till the pipeline finishes to build and deploy the application to kubernetes cluster.

**Script Pipeline**

![script-pipeline](https://github.com/user-attachments/assets/ac6d9c81-3a64-44a8-8e6e-9796c8496a85)

**Terraform Pipeline**

![terraform-pipeline](https://github.com/user-attachments/assets/bff4f617-184b-4d63-a151-6f44793ccf11)

**CICD Pipeline**

![cicd-pipeline](https://github.com/user-attachments/assets/0d5f9761-c409-4b5b-9075-bdcc8597c69d)

After ppipeline finished you can access the application. Following images showcase the output results.

**SonarQube Output**

![sonar-out](https://github.com/user-attachments/assets/55594d93-b4f1-472e-8f84-e3b28267d112)

**Trivy File Scan Output**

![trivy-file-scan](https://github.com/user-attachments/assets/5248dd73-33fd-4893-a31c-aef7d7352fac)

**Trivy Image Scan Output**

![trivy-image-scan](https://github.com/user-attachments/assets/0f4086e2-7f9a-4507-a739-28cec81fb179)

**Docker Scout Image Scan Output**

![docker-scout-image-scan](https://github.com/user-attachments/assets/fc4a1a26-95de-457e-9abd-7f38cc2e374b)

**Cluster Output**

To det deployments execute, 

```bash
$ kubectl get all
```

![k8s](https://github.com/user-attachments/assets/55a1b4f0-3063-4bb0-96f8-4f50491529b2)

> [!NOTE]
> Copy the EXTERNAL-IP of application service (`service/myntra-service`) and paste on browser to access the application. If you do not have access to runner right now. The application URL is send through the slack channel as well.

**Slack Channel Output**

![slack-channel-1](https://github.com/user-attachments/assets/d1d3159b-f91e-4447-8101-69cc50b2c264)

> [!NOTE]
> Under deploy message you will get the Application URL copy and paste on browser to access the application.

**Application**

![app-1](https://github.com/user-attachments/assets/c1caf610-6353-4c6e-94c4-11a77e807578)

![app-2](https://github.com/user-attachments/assets/285f11ca-f3eb-494b-8d79-182d5bccdd69)

![app-3](https://github.com/user-attachments/assets/9ff5dc4d-4abd-411a-94bb-d71b666e6ec7)

![app-4](https://github.com/user-attachments/assets/bbc03d25-8887-468f-9caa-41a7d93837c2)

![app-5](https://github.com/user-attachments/assets/64fcc831-0e0b-42a1-be79-06d723377354)


### Step 7: Destroy Resources

Finally if you need to destroy all the resources. For that run the `destroy pipeline` manually in github actions.

**Destroy Pipeline**

![destroy-pipeline](https://github.com/user-attachments/assets/09dae05b-8c5f-4e63-9081-a03c67bd18f3)

**Slack Channel Output**

![slack-channel-2](https://github.com/user-attachments/assets/1456cc35-2808-4ec4-9aeb-06f3fbab0f7d)


### Step 8: Remove Self-Hosted Runner

Finally, you need remove the self-hosted runner and terminate the instance.

1. #### Open your repository 

   Go to Settings --> Actions --> Runners --> Select your runner (git-workflow) --> Remove Runner. Then you will see steps safely remove runner from EC2 instance.

   ![runner-remove-1](https://github.com/user-attachments/assets/ea347d40-d864-4509-8aac-b782b876e5c3)

   ![runner-remove-2](https://github.com/user-attachments/assets/62913e82-9796-4fcf-b885-a39a79faa6d1)

   ```bash
   # Remove the runner
   $ ./config.sh remove --token <your-token>
   ```

3. #### Remove runner 
    
   Go to your EC2 instance and execute the command

   ![runner-remove-3](https://github.com/user-attachments/assets/01ddadd2-e139-4ef9-8679-c017bff57d0d)

> [!WARNING]
> Make sure you are in the right folder `~/actions-runner`

3. **Terminate Instance**

    Go to your AWS Management console --> EC2 terminate the created instance (git-workflow) and then remove any additional resources (vpc, security groups, s3 buckets, dynamodb tables, load balancers, volumes, auto scaling groups, etc)

    **Verify that every resource is removed or terminated**
