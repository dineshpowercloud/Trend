pipeline {
  agent any
  environment {
    DOCKER_IMAGE = "dockerpowercloud/trend"
    DOCKER_CREDENTIALS = "dockerhub-creds"
  }
  stages {
    stage('Checkout') {
      steps { git branch: 'main', url: 'https://github.com/dineshpowercloud/Trend.git' }
    }
    stage('Build Docker') {
      steps { sh "docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} ." }
    }
    stage('Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
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
          aws eks update-kubeconfig --name trend-eks --region us-east-1
          kubectl set image deployment/trend-app trend=${DOCKER_IMAGE}:${BUILD_NUMBER} --record || kubectl apply -f k8s/deployment.yml
          kubectl apply -f k8s/service.yml
          kubectl rollout status deployment/trend-app
        """
      }
    }
  }
}
