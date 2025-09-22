pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "dockerpowercloud/trend:latest"  // DockerHub repo
        DOCKER_CREDENTIALS = "dockerhub-creds"          // Jenkins DockerHub credentials
        K8S_MANIFEST_PATH = "k8s"                       // Path to k8s manifests
        KUBECONFIG_CREDENTIALS_ID = "eks-kubeconfig"    // Jenkins secret file for kubeconfig
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/dineshpowercloud/Trend.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', DOCKER_CREDENTIALS) {
                        def appImage = docker.build(DOCKER_IMAGE)
                        appImage.push()   // Push latest tag
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS_ID}", variable: 'KUBECONFIG')]) {
                    sh """
                    echo "Updating deployment with new Docker image..."
                    kubectl set image -f ${K8S_MANIFEST_PATH}/deployment.yml trend=${DOCKER_IMAGE}
                    kubectl apply -f ${K8S_MANIFEST_PATH}/service.yml
                    kubectl rollout status -f ${K8S_MANIFEST_PATH}/deployment.yml
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Build & deployment completed successfully!"
        }
        failure {
            echo "Build or deployment failed. Check the logs."
        }
    }
}

