pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "dineshpowercloud/trend:latest"  // DockerHub repo
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
        	withEnv(["KUBECONFIG=/home/ubuntu/.kube/config"]) {
            	sh '''
                echo "Updating deployment with new Docker image..."
                kubectl set image -f k8s/deployment.yml trend=dineshpowercloud/trend:latest
                kubectl rollout status deployment/trend
            '''
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

