pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "dineshpowercloud/trend"   // DockerHub repo
        DOCKER_CREDENTIALS = "dockerhub-creds"    // Jenkins credential ID
        AWS_REGION = "us-east-1"
        EKS_CLUSTER = "trend-eks"
        K8S_DIR = "${WORKSPACE}/k8s"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/dineshpowercloud/Trend.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ."
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS}", 
                                                 usernameVariable: 'DOCKER_USER', 
                                                 passwordVariable: 'DOCKER_PASS')]) {
                    sh """
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                        docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest
                        docker push ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh """
                    aws eks update-kubeconfig --name ${EKS_CLUSTER} --region ${AWS_REGION}
                    
                    # Update deployment with the new Docker image or apply deployment if not exists
                    kubectl set image deployment/trend-app trend=${DOCKER_IMAGE}:${BUILD_NUMBER} --record || \
                    kubectl apply -f ${K8S_DIR}/deployment.yml
                    
                    # Apply service manifest
                    kubectl apply -f ${K8S_DIR}/service.yml
                    
                    # Wait for rollout to finish
                    kubectl rollout status deployment/trend-app
                """
            }
        }
    }

    post {
        always {
            echo "✅ Deployment finished"
        }
    }
}

