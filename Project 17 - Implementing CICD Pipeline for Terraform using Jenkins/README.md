# Implementing CICD Pipleline for Terraform using Jenkins

CI/CD (Continuous Integration/Continuous Deployment) pipelines are a set of practices, principles, and tools that automate the process of building, testing, and deploying software changes. These pipelines aim to increase the efficiency, reliability, and speed of software development and delivery. The CI/CD process is typically divided into two main stages:

- **Continuous Integration (CI):**
  - **Integration**: Developers regularly merge their code changes into a shared repository (version control system), ensuring that the codebase is continuously integrated.
  - **Automated Builds**: Automated build tools compile the source code, run unit tests, and generate executable artifacts. This ensures that the integrated codebase is always in a buildable and testable state.
- **Continuous Deployment/Delivery (CD):**
  - **Continuous Deployment:** Automatically deploying the application to production environments after passing automated tests. This is common for web applications or services where rapid and frequent deployments are feasible.
  - **Continuous Delivery:** Similar to continuous deployment but stops short of automatically deploying to production. Instead, the deployment to production is triggered manually or by a specific condition. This is often preferred for applications that require additional manual approval or validation before going live.

Jenkins is an open-source automation server that helps automate the building, testing, and deployment of code. CI/CD pipelines using Jenkins provide a systematic and automated way to deliver software changes quickly and reliably.

In this project, we will be writing CICD pipeline to automate the creation of cloud infrastrutures using Terraform. The pipelines would be created in Jenkins.

### Part 1 - Setting up the environment (Docker)

In the [CI/CD With Jenkins](https://github.com/iamYole/DIO-Projects/blob/main/Project%2011%20-%20CI%20CD%20With%20Jenkins/README.md) Project, we saw how to Install and Configure Jenkins. In this project however, we would be using Docker to build our Jenkins Server and the Terraform CLI.  
Let's begin:

- Luanch an EC2 Instance called `Jenkins_Server` running Ubuntu Linux.
- Install Docker Engine. Follow the instruction from the official website on how to [Install Docker Engine on Ubuntu](https://docs.docker.com/engine/install/ubuntu/).
- In the `Jenkins_Server`, create a directory called `terraform-with-cloud`.
- Inside the `terraform-with-cloud` directory, create a file called `Dockerfile`.
- Copy and paste the code below into the `Dockerfile` file.
  > ```docker
  > # Use the official Jenkins base image
  > FROM jenkins/jenkins:lts
  >
  > # Create a label the Image
  > LABEL name = "Jenkins/terraform"
  > LABEL author = "darey.io"
  >
  > # Switch to the root user to install additional packages
  > USER root
  >
  > # Install necessary tools and dependencies (e.g., Git, unzip, wget, software-properties-common)
  > RUN apt-get update && apt-get install -y \
  >   git \
  >   unzip \
  >   wget \
  >   software-properties-common \
  >   && rm -rf /var/lib/apt/lists/*
  >
  > # Install Terraform
  > RUN apt-get update && apt-get install -y gnupg software-properties-common wget \
  >   && wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg \
  >   && gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint \
  >   && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
  >   && apt-get update && apt-get install -y terraform \
  >   && rm -rf /var/lib/apt/lists/*
  >
  > # Set the working directory
  > WORKDIR /app
  >
  > # Print Terraform version to verify installation
  > RUN terraform --version
  >
  > # Switch back to the Jenkins user
  > USER jenkins
  >
  > ```
- The code above are commands we should be familar with. There are commands we've used to install several packages in the past. The only difference here is that we are creating a Docker Image and then executing the commands in the Image, and not our linux machine.
- Save the file and then run the command below to build the image. Ensure you are in the same directory as the `Dockerfile`
  > `docker build -t jenkins-server .`
- If no errors were encountered during the build process, run the command below to confirm the image has ben built sucessfully.

  > `docker images`

  ![Alt text](Images/Img_01.png)

- Now, let's run the image by running the command below:

  > `docker run -d -p 8080:8080 --name jenkins-server jenkins-server`

  The command above runs our `jenkins-server`image and maps it to port 8080.

- We can confirm the image is running using the command below:

  > `docker ps`

  ![Alt text](Images/Img_02.png)

- Finally, to launch Jenkins, open your web browser and then type in the <http://PUBLIC_IP_ADDRESS:8080>. Kindly ensure port `8080` is enabled in the security group.
  ![Alt text](Images/Img_03.png)
- To retrieve the AdminPAssword, we need to log into the image running Jenkins. To do this, run the command below:

  > `docker exec -it jenkins-server /bin/bash`

  This command will log into the image just the way we ssh into our linux machine.

- Navigate to the dictory where the adminpassowrd is stored copy and then paste in the password field to setup jenkins.
  ![Alt text](Images/Img_04.png)
  ![Alt text](Images/Img_05.png)

### Part 2 - Setting up Jenkins for Terraform CI/CD.
