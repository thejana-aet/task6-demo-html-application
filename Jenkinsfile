pipeline {
    agent any

    environment {
        
        AWS_ACCOUNT_ID = '041360578609'    
        AWS_REGION     = 'us-east-1'              
        ECR_REPO_NAME  = 'task6-thejana-ecr-test'        
        
        // --- DERIVED VARIABLES (Do not change) ---
        ECR_REGISTRY   = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG      = "${ECR_REGISTRY}/${ECR_REPO_NAME}:${env.BUILD_NUMBER}"
        IMAGE_LATEST   = "${ECR_REGISTRY}/${ECR_REPO_NAME}:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo "Building Docker Image..."
                    sh "docker build -t ${IMAGE_TAG} ."
                    sh "docker tag ${IMAGE_TAG} ${IMAGE_LATEST}"
                }
            }
        }

        stage('Login to ECR') {
            steps {
                script {
                    echo "Logging in to ECR..."
                    // This uses the IAM Role attached to your EC2 instance
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                }
            }
        }

        stage('Push to ECR') {
            steps {
                script {
                    echo "Pushing image to ECR..."
                    sh "docker push ${IMAGE_TAG}"
                    sh "docker push ${IMAGE_LATEST}"
                }
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Image pushed to ECR!'
        }
        failure {
            echo 'FAILURE: Could not push to ECR. Check AWS CLI or IAM Role.'
        }
        always {
            // Cleanup to save space
            sh "docker rmi ${IMAGE_TAG} || true"
            sh "docker rmi ${IMAGE_LATEST} || true"
        }
    }
}