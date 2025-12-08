pipeline {
    agent any

    environment {
        
        AWS_ACCOUNT_ID = '041360578609'    
        AWS_REGION     = 'us-east-1'              
        ECR_REPO_NAME  = 'task6-thejana-prod-ecr'

        // --- FARGATE RESOURCES ---
        ECS_CLUSTER    = 'Task6-Thejana-Prod-Cluster'
        ECS_SERVICE    = 'Task6-Thejana-Prod-TaskDefinition-service'
        ECS_TASK_DEF_FAMILY='Task6-Thejana-Prod-TaskDefinition'       
        
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
                    echo "Starting dynamic deployment to cluster: ${ECS_CLUSTER}..."
                    sh """
                        # 1. Fetch current Task Definition JSON
                        TASK_DEFINITION=\$(aws ecs describe-task-definition --task-definition ${ECS_TASK_DEF_FAMILY} --region ${AWS_REGION})

                        # 2. Modify JSON: Update image tag and remove AWS-generated fields
                        NEW_TASK_DEFINITION=\$( echo \$TASK_DEFINITION | jq \
                            --arg IMAGE "${ECR_REGISTRY}/${ECR_REPO_NAME}:\${BUILD_NUMBER}" \
                            '.taskDefinition | \
                            .containerDefinitions[0].image = \$IMAGE | \
                            del(.taskDefinitionArn) | \
                            del(.revision) | \
                            del(.status) | \
                            del(.requiresAttributes) | \
                            del(.compatibilities) | \
                            del(.registeredAt) | \
                            del(.registeredBy)' )
                        
                        # 3. Write modified JSON to a file
                        echo \$NEW_TASK_DEFINITION > task-def.json

                        # 4. Register the new Task Definition revision
                        NEW_TASK_INFO=\$(aws ecs register-task-definition --region ${AWS_REGION} --cli-input-json file://task-def.json)
                        
                        # 5. Extract the new revision number
                        NEW_REVISION=\$(echo \$NEW_TASK_INFO | jq -r '.taskDefinition.revision')
                        
                        echo "Registered new Task Definition revision: \${NEW_REVISION}"

                        # 6. Update the ECS Service to use the specific new revision
                        aws ecs update-service \
                            --cluster ${ECS_CLUSTER} \
                            --service ${ECS_SERVICE} \
                            --task-definition ${ECS_TASK_DEF_FAMILY}:\${NEW_REVISION} \
                            --force-new-deployment \
                            --region ${AWS_REGION}
                    """
                    // Clean up the temporary file
                    sh 'rm -f task-def.json'
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