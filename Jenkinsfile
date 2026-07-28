pipeline {
    agent any

    environment {
        // Docker variables
        IMAGE_NAME = 'nikhil1nt24cs410/stayfinder-api'
        IMAGE_TAG = "${BUILD_NUMBER}"
        
        // SonarQube Scanner Tool Name (Matches Jenkins Global Tool Configuration Name)
        SONAR_SCANNER_HOME = tool 'sonar'
    }

    stages {
        

        stage('SonarQube Analysis') {
            steps {
                // 'SonarQubeServer' must match the system server name set in Jenkins Settings
                withSonarQubeEnv('sonarqube') { 
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
                sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${IMAGE_NAME}:latest"
            }
        }

        stage('Deploy Locally') {
            steps {
                // Deploys the built container locally on your Docker Desktop
                sh """
                    # Stop and remove any current running container with the same name
                    docker stop stayfinder-app || true
                    docker rm stayfinder-app || true
                    
                    # Run the container locally using a persistent Docker volume for the SQLite DB
                    docker run -d --name stayfinder-app \
                        -p 4000:4000 \
                        -v stayfinder-data:/app/data \
                        --restart always \
                        ${IMAGE_NAME}:latest
                """
            }
        }
    }

    post {
        always {
            // Clean up the specific build tag image, keeping 'latest' running
            sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG} || true"
            cleanWs()
        }
        success {
            echo "StayFinder Local CI/CD Pipeline executed successfully!"
            echo "Your app is now running and live at: http://localhost:4000"
        }
        failure {
            echo "StayFinder Local CI/CD Pipeline failed. Check console outputs."
        }
    }
}
