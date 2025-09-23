pipeline {
    agent any
    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')  // Jenkins credentials
        DOCKER_IMAGE = 'dineshpowercloud/trend-app'             // DockerHub repo
        EKS_CLUSTER = 'trend-eks'
        AWS_REGION = 'us-east-1'
    }
    stages {
        stage('Checkout') {
            options {
                timeout(time: 5, unit: 'MINUTES')  // In case Git hangs
            }
            steps {
                git branch: 'main', url: env.GIT_URL
            }
        }
        stage('Build Docker') {
            options {
                timeout(time: 10, unit: 'MINUTES')  // Docker build timeout
            }
            steps {
                script {
                    sh 'docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .'
                    sh 'docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest'
                }
            }
        }
        stage('Push to DockerHub') {
            options {
                timeout(time: 5, unit: 'MINUTES')  // Prevent push hang
            }
            steps {
                script {
                    sh 'echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'
                    sh 'docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}'
                    sh 'docker push ${DOCKER_IMAGE}:latest'
                }
            }
        }
        stage('Deploy to EKS') {
            options {
                timeout(time: 15, unit: 'MINUTES')  // Cap total deploy time
            }
            steps {
                script {
                    sh '''
                    aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER}
                    kubectl apply -f k8s/deployment.yaml
                    kubectl apply -f k8s/service.yaml
                    kubectl rollout restart deployment/trend-app
                    kubectl rollout status deployment/trend-app --timeout=10m
                    '''
                }
            }
        }
    }
    post {
        always {
            sh 'docker logout'
        }
    }
}
