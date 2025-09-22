pipeline {
    agent any

    environment {
        DOCKER_CREDENTIALS = "dockerhub-creds"   // Jenkins Docker Hub credentials ID
        DOCKER_IMAGE = "dineshpowercloud/trend:latest"
        KUBECONFIG = "/home/ubuntu/.kube/config" // Path to kubeconfig on Jenkins node
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
                        sh "docker build -t ${DOCKER_IMAGE} ."
                        sh "docker push ${DOCKER_IMAGE}"
                    }
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                withEnv(["KUBECONFIG=${env.KUBECONFIG}"]) {
                    sh '''
                        echo "Updating deployment with new Docker image..."
                        kubectl set image -f k8s/deployment.yml trend=${DOCKER_IMAGE}
                        kubectl rollout status deployment/trend
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "Build and deployment completed successfully!"
        }
        failure {
            echo "Build or deployment failed. Check logs."
        }
    }
}
