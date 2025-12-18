pipeline {
    agent any

    environment {
        
        AWS_ACCOUNT_ID = credentials('AWS_ACCOUNT_ID')
        AWS_REGION     = credentials('AWS_REGION')
        ECR_REPO_NAME  = credentials('PROD_ECR_REPO_NAME')
        S3_BUCKET      = credentials('PROD_S3_BUCKET')
        EB_APP_NAME    = credentials('EB_APP_NAME')
        EB_ENV_NAME    = credentials('PROD_EB_ENV_NAME')

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

        stage('Deploy to Elastic Beanstalk') {
            steps {
                script {
                    echo "Starting deployment to Beanstalk Environment: ${EB_ENV_NAME}..."
                    
                    sh """
                        # 1. Update the Dockerrun.aws.json image name dynamically
                        sed -i "s|<IMAGE_PLACEHOLDER>|${IMAGE_TAG}|g" Dockerrun.aws.json

                        # 2. Zip the manifest for Beanstalk
                        zip deploy.zip Dockerrun.aws.json

                        # 3. Upload the source bundle to S3
                        aws s3 cp deploy.zip s3://${S3_BUCKET}/deploy-${BUILD_NUMBER}.zip

                        # 4. Create new Application Version
                        aws elasticbeanstalk create-application-version \
                            --application-name ${EB_APP_NAME} \
                            --version-label v${BUILD_NUMBER} \
                            --source-bundle S3Bucket="${S3_BUCKET}",S3Key="deploy-${BUILD_NUMBER}.zip" \
                            --region ${AWS_REGION}

                        # 5. Update the Environment
                        aws elasticbeanstalk update-environment \
                            --environment-name ${EB_ENV_NAME} \
                            --version-label v${BUILD_NUMBER} \
                            --region ${AWS_REGION}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "SUCCESS: Deployed Build #${env.BUILD_NUMBER} to Elastic Beanstalk!"
        }
        failure {
            echo 'FAILURE: Pipeline failed. Check Jenkins logs.'
        }
        always {
            sh "docker rmi ${IMAGE_TAG} || true"
            sh "docker rmi ${IMAGE_LATEST} || true"
            sh "rm -f deploy.zip"
        }
    }
}