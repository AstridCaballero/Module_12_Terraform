![img.png](img.png)

## Module 12 - Infrastructure as a Code with Terraform

### Chapter 24 - Complete CI/CD with Terraform - Part 3

Notes from chapter 24 were taken in notes app in freestyle, and it includes a mix of screenshots of TWN bootcamp as well as
screenshots of my own work on the terminal and browser. I used AI and I have added that research to my notes.

Notes have been exported into pdf format to be able to get the screenshots (avoiding retaking screenshots which is time-consuming)

You can find original notes for
- Chapter 24 [here](Module%2012%20-%20chapter%2024_notes.pdf).

### Description chapter 22 to 24: Complete CI/CD with Terraform
I created the below branches for this DEMO:

https://github.com/AstridCaballero/Module_12_Terraform/tree/Module_12/Terraform_chapter-22

https://github.com/AstridCaballero/Module_12_Terraform/tree/Module_12/Terraform_chapter-23

https://github.com/AstridCaballero/Module_12_Terraform/blob/Module_12/Terraform_chapter-24

#### Part 1:
Previously with Jenkins we:
built a docker image -> push image to a registry -> pull image from registry into existing server

In this demo Jenkins provisioned the server automatically using TF
built a docker image -> push image to a registry -> provision server using TF ->  pull image from registry into provisioned server

We will edit
- Jenkinsfile
    - Add ‘provision server’ stage
    - Edit ‘deploy’ stage
- Create ‘terraform’ folder and add the TF config files to our java app (best practice to include everything the app needs)

#### Part 2:
AWS IAM
- Create Jenkins user
    - Create ‘Access Key’ 
    - Create ‘secret’

Jenkins
- Create a credential to store the AWS IAM ‘Access Key’ for user Jenkins
- Create a credential to store the AWS IAM ‘secret’ for user Jenkins
- Create a new multi-branch pipeline
- SSH key pair
    - Create ssh key pair using AWS -> we get a pem file
    - Create a new ssh credential in Jenkins using the the pem file
- Install terraform inside Jenkins container
    - Find out the jenkins container uses Debian trixie OS
    - Install terraform based on the OS Debian trixie following the TF documentation ( I had to make some adjustments to the commands due to the OS being Debian trixie)

Java-app project
- Add TF config files
    - Create ‘terraform’ folder
    - Create ‘main.tf’ 
        - add the code to provision an EC2 instance -> I re use the code from Module 12 - chapter 14 and make some adjustments like removing ‘aws_key_pair’ resource and use the one created manually in AWs console
        - Reference a file called ‘entry-script.sh’ inside the ‘aws_instance’ resource, so the EC2 instance will run this file.
            - Add logic to file ‘entry-script.sh’ to install docker, start docker and install docker-compose and make it executable
        - Refactor ‘main.tf’ to give default values to the variables and move the variables outside of ‘main.tf’ and into a new file called ‘Variables.tf’ -> ‘main.tf’ is cleaner
- Edit Jenkinsfile
    - Add ‘provision server’ stage logic for Jenkins to run terraform
        - we write a script to cd into ’terraform’ directory 
        - then we run the terraform commands
            - terraform init
            - terraform apply -auto-approve
            - And get the public IP of the provisioned EC2 instance, trim white spaces and store it in a env var called ‘EC2_PUBLIC_IP’ so Jenkins can use it later in ‘deploy’ stage
            - Create env vars so Jenkins can auth to AWS when executing ‘provider’ block in ‘main.tf’
                - AWS_ACCESS_KEY_ID -> assign the credential with the AWS IAM ‘Access Key’ for user Jenkins
                - AWS_SECRET_ACCESS_KEY -> assign the credential with the AWS IAM ‘secret’ for user Jenkins
                - TF_VAR_env_prefix -> to override the default value of the ‘env_prefix’ variable in ’variables.tf’ from ‘dev’ to ‘test’
    - Edit ‘deploy’ stage
        - Use ‘EC2_PUBLIC_IP’ 
        - Give time for the EC2 instance to be up and running (initialising the EC2 instance provisioned by TF takes time and the instance also will be running ‘entry-script.sh’ file to install docker and docker-compose in the EC2 instance. The ‘deploy’ stage needs the EC2 ready before it deploy the app -> add sleep()
        - Add logic to get Jenkins to deploy the java-app in the provisioned EC2 serve
            - Use sshagent (same way we did in Module 9 - chapter 8) and use the SSH key pair created in AWS and stored in a Jenkins credential, so Jenkins can ssh into the EC2 instance.


#### Part 3:
Java-app project
- Edit TF config files
    - Add Jenkins public IP address to ‘variables.tf’ using the CIDR block format
    - Add Jenkins public IP address variable to ‘main.tf’ to update the ‘aws_default_security_group’ resource in the ‘ingress’ section -> The EC2 provisioned by terraform uses this security group resource, so by adding the jenkins public ip address the EC2 instance will allow Jenkins to access it via port 22.
- Make sure ‘docker-compose.yaml’ file exists
- Make sure ‘server-cmds.sh’ file exists and make sure the logic:
    - sets up 3 env vars:
        - IMAGE
        - DOCKER_USER
        - DOCKER_PWD
    - Loggings to docker using DOCKER_USER and DOCKER_PWD env vars
    - Executes ‘docker-compose.yaml’ file -> this file will use IMAGE env var to pull the Java-maven-app image and run the container. It will also run a postgres container.
- Edit Jenkinsfile ‘deploy’ stage
    - Create a shell command ‘shellCmd’ that runs ‘server-cmds.sh’ file and passes 3 arguments ( ‘server-cmds.sh’ file expects 3 parameters to create the 3 env vars):
        - ${IMAGE_NAME}
        - ${DOCKER_CREDS_USR}
        - ${DOCKER_CREDS_USR}
    - Write logic for the sshagent to:
        - Copy two files to the EC2 instance (ssh handshake happens internally)
            - ‘server-cmds.sh’ 
            - ‘docker-compose.yaml’ 
        - Open an interactive SSH session in the EC2 instance (Jenkins can do this due to the edition the the security group -> ingress block we did earlier) and run the shell command ‘shellCmd’ so we deploy the app along with a DB.

The pipeline worked and I was able to ssh into the EC2 server from my machine and verified that the java app and postgres db were up and running.

#### Troubleshooting

My pipeline failed several times due to some issues
- AWS IAM Jenkins user policies
    - I used SSM to store the latest Amazon Linux 2023 image ID (Nana didn’t do it this way) so I had to add a policy so Jenkins could use SSM
    - Other EC2 permission issues because my ‘Jenkins’ user was too restrictive (Nana was using an ‘admin’ user with broader permissions) so I add ‘AmazonEC2FullAccess’ policy to ‘Jenkins’ user.

#### Destroy infra

This was the first time we provisioned infrastructure outside my local machine, this time Jenkins run terraform so the state was stored in Jenkins. To destroy the infrastructure I had to ssh into the Jenkins droplet and get into the Jenkins container and cd into the workspace until I was inside the ‘terraform’ folder, once there I destroyed the infrastructure.


I learnt what needs to be configured in Jenkins credentials, jenkinsfile, terraform files, AWS IAM policies to get Jenkins to provision infrastructure with terraform in AWS and also for Jenkins to deploy an app in the provisioned EC2 instance. And I learnt a way to destroy the infra created by Jenkins.
