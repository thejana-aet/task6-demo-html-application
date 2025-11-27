pipeline {
    agent any

    environment {
        
        AWS_ACCOUNT_ID = '041360578609'    
        AWS_REGION     = 'us-east-1'              
        ECR_REPO_NAME  = 'task6-thejana-prod-ecr'

        // --- FARGATE RESOURCES ---
        ECS_CLUSTER    = 'Task6-Thejana-Prod-Cluster'
        ECS_SERVICE    = 'Task6-Thejana-Prod-TaskDefinition-service'        
        
        // --- DERIVED VARIABLES ---
        ECR_REGISTRY   = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        IMAGE_TAG      = "${ECR_REGISTRY}/${ECR_REPO_NAME}:${env.BUILD_NUMBER}"
        IMAGE_LATEST   = "${ECR_REGISTRY}/${ECR_REPO_NAME}:latest"
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    echo 'Building Docker Image...'
                    
                    sh "docker build -t ${IMAGE_TAG} ."
                    
                    sh "docker tag ${IMAGE_TAG} ${IMAGE_LATEST}"
                }
            }
        }

        stage('Login to ECR') {
            steps {
                script {
                    echo 'Logging into Amazon ECR...'
                    // Uses the IAM Role attached to the EC2 instance
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}"
                }
            }
        }

        stage('Push Image to ECR') {
            steps {
                script {
                    echo 'Pushing Docker Image to ECR...'
                    sh "docker push ${IMAGE_TAG}"
                    sh "docker push ${IMAGE_LATEST}"
                }
            }
        }

        stage('Deploy to ECS Fargate') {
            steps {
                script {
                    echo "Forcing deployment on service: ${ECS_SERVICE}..."
                    sh "aws ecs update-service --cluster ${ECS_CLUSTER} --service ${ECS_SERVICE} --force-new-deployment --region ${AWS_REGION}"
                }
            }
        }
    }

    post {
        success {
            echo "SUCCESS: Deployed Build #${env.BUILD_NUMBER} to Fargate!"
        }
        failure {
            echo 'FAILURE: Pipeline failed. Check Jenkins logs.'
        }
        always {
            // Clean up local images to save disk space on the Jenkins server
            sh "docker rmi ${IMAGE_TAG} || true"
            sh "docker rmi ${IMAGE_LATEST} || true"
        }
    }
}