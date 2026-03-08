pipeline {
    agent any
 
    environment {
        DOCKER_HUB_REPO  = "yourdockerhubuser/devops-project7"
        IMAGE_TAG        = "${BUILD_NUMBER}"
        DEPLOY_SERVER    = credentials('deploy-server-ip')
        DEPLOY_SSH_KEY   = credentials('deploy-ssh-key')
        APP_PORT         = "5000"
        CONTAINER_NAME   = "project7-app"
    }
 
    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }
 
    stages {
 
        stage('Checkout') {
            steps {
                echo "==> Checking out source code from branch: ${GIT_BRANCH}"
                checkout scm
            }
        }
 
        stage('Lint & Static Analysis') {
            steps {
                echo "==> Running Python linting"
                sh '''
                    pip install flake8 --quiet
                    flake8 app/ --max-line-length=100 --exclude=__pycache__ || true
                '''
            }
        }
 
        stage('Build Docker Image') {
            steps {
                echo "==> Building Docker image: ${DOCKER_HUB_REPO}:${IMAGE_TAG}"
                sh """
                    docker build \
                        --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                        --build-arg VERSION=${IMAGE_TAG} \
                        -t ${DOCKER_HUB_REPO}:${IMAGE_TAG} \
                        -t ${DOCKER_HUB_REPO}:latest \
                        .
                """
            }
        }
 
        stage('Security Scan') {
            steps {
                echo "==> Scanning image for vulnerabilities with Trivy"
                sh """
                    docker run --rm \
                        -v /var/run/docker.sock:/var/run/docker.sock \
                        aquasec/trivy:latest image \
                        --exit-code 0 \
                        --severity HIGH,CRITICAL \
                        --no-progress \
                        ${DOCKER_HUB_REPO}:${IMAGE_TAG} || true
                """
            }
        }
 
        stage('Push to Docker Hub') {
            steps {
                echo "==> Pushing image to Docker Hub"
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "${DOCKER_PASS}" | docker login -u "${DOCKER_USER}" --password-stdin
                        docker push ${DOCKER_HUB_REPO}:${IMAGE_TAG}
                        docker push ${DOCKER_HUB_REPO}:latest
                        docker logout
                    '''
                }
            }
        }
 
        stage('Deploy to Server') {
            when {
                branch 'main'
            }
            steps {
                echo "==> Deploying to production server"
                sh """
                    ssh -o StrictHostKeyChecking=no \
                        -i ${DEPLOY_SSH_KEY} \
                        ec2-user@${DEPLOY_SERVER} \
                        'bash -s' < scripts/deploy.sh ${DOCKER_HUB_REPO} ${IMAGE_TAG} ${CONTAINER_NAME} ${APP_PORT}
                """
            }
        }
 
        stage('Health Check') {
            when {
                branch 'main'
            }
            steps {
                echo "==> Running post-deployment health check"
                sh """
                    sleep 10
                    ssh -o StrictHostKeyChecking=no \
                        -i ${DEPLOY_SSH_KEY} \
                        ec2-user@${DEPLOY_SERVER} \
                        'bash -s' < scripts/health_check.sh ${APP_PORT}
                """
            }
        }
    }
 
    post {
        success {
            echo "✅ Pipeline SUCCEEDED — Build #${BUILD_NUMBER} deployed successfully"
        }
        failure {
            echo "❌ Pipeline FAILED — Build #${BUILD_NUMBER} failed. Check logs above."
            // Rollback: re-deploy previous image tag
            sh """
                PREV_BUILD=$((${BUILD_NUMBER} - 1))
                ssh -o StrictHostKeyChecking=no \
                    -i ${DEPLOY_SSH_KEY} \
                    ec2-user@${DEPLOY_SERVER} \
                    'bash -s' < scripts/deploy.sh ${DOCKER_HUB_REPO} \x24{PREV_BUILD} ${CONTAINER_NAME} ${APP_PORT} || true
            """ 
        }
        always {
            sh 'docker image prune -f || true'
            cleanWs()
        }
    }
}