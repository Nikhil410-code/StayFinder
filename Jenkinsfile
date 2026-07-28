pipeline {
    agent any

    environment {
        // AWS and Docker variables
        AWS_ACCOUNT_ID = 'YOUR_AWS_ACCOUNT_ID'
        AWS_DEFAULT_REGION = 'ap-south-1' // Change to your AWS region (e.g., Mumbai)
        IMAGE_NAME = 'stayfinder-api'
        IMAGE_TAG = "${BUILD_NUMBER}"
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
        
        // SonarQube Scanner Tool Name (Matches Jenkins Global Tool Configuration Name)
        SONAR_SCANNER_HOME = tool 'SonarQubeScanner'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('SonarQube Analysis') {
            steps {
                // 'SonarQubeServer' must match the system server name set in Jenkins Settings
                withSonarQubeEnv('SonarQubeServer') { 
                    sh "${SONAR_SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectKey=StayFinder \
                        -Dsonar.projectName=StayFinder \
                        -Dsonar.sources=. \
                        -Dsonar.exclusions=**/__pycache__/**,stayfinder.db,*.db,venv/** \
                        -Dsonar.python.version=3"
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            error "Pipeline aborted due to Quality Gate failure: ${qg.status}"
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${ECR_REGISTRY}/${IMAGE_NAME}:latest"
            }
        }

        stage('Login & Push to ECR') {
            steps {
                // Uses Jenkins AWS credentials binding ('aws-credentials-id' configured in Jenkins Credentials manager)
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-credentials-id']]) {
                    sh "aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                    sh "docker push ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker push ${ECR_REGISTRY}/${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Deploy to AWS') {
            steps {
                // SSH deployment onto an EC2 server instance.
                // Replace 'ec2-ssh-key' with the SSH credentials ID configured in Jenkins.
                withCredentials([sshUserPrivateKey(credentialsId: 'ec2-ssh-key', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                    sh """
                        ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${SSH_USER}@your-ec2-domain-or-ip "
                            # Log in to ECR on remote EC2 server
                            aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}
                            
                            # Pull the latest container image
                            docker pull ${ECR_REGISTRY}/${IMAGE_NAME}:latest
                            
                            # Stop and remove any current running containers with same name
                            docker stop stayfinder-app || true
                            docker rm stayfinder-app || true
                            
                            # Run container with SQLite DB volume mapping for persistence
                            docker run -d --name stayfinder-app \
                                -p 80:4000 \
                                -v /var/lib/stayfinder-data:/app/data \
                                --restart always \
                                ${ECR_REGISTRY}/${IMAGE_NAME}:latest
                        "
                    """
                }
            }
        }
    }

    post {
        always {
            // Cleanup local builder images from Jenkins node to save disk space
            sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true"
            sh "docker rmi ${ECR_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} || true"
            sh "docker rmi ${ECR_REGISTRY}/${IMAGE_NAME}:latest || true"
            cleanWs()
        }
        success {
            echo "StayFinder CI/CD Pipeline executed successfully!"
        }
        failure {
            echo "StayFinder CI/CD Pipeline failed. Check console outputs."
        }
    }
}
