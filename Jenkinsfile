pipeline {
    agent {
        label "ec2-jdk11"
    }

    options {
        ansiColor('xterm')
    }

    environment {
        HOME = pwd()
        //RP_TOKEN = credentials('test-report-portal-access-uuid')
        VERSION = "2.38"
        INSTANCE_NAME = "${VERSION}_smoke"
        INSTANCE_DOMAIN = "https://whoami.im.radnov.test.c.dhis2.org"
        //GIT_URL = "https://github.com/radnov/e2e-cy"
        ALLURE_REPORT_DIR_PATH = "./allure"
        ALLURE_RESULTS_DIR = "./allure-results"
        ALLURE_REPORT_DIR = "allure-report-$VERSION"
        CYPRESS_REPORT_PORTAL_ENABLED="false"
        // CI_BUILD_ID="${BUILD_NUMBER}"
        INSTANCE_HOST = "https://api.im.radnov.test.c.dhis2.org"
        HTTP = "https --verify=no --check-status"
    }

    stages {
        stage('Prepare reports dir') {
            steps {
                script {
                    if (!fileExists("$ALLURE_REPORT_DIR_PATH")) {
                        sh "mkdir -m 777 -p $ALLURE_REPORT_DIR_PATH"
                    }

                    if (fileExists("$ALLURE_RESULTS_DIR")) {
                        dir("$ALLURE_RESULTS_DIR") {
                            deleteDir()
                        }
                    }

                    sh "mkdir -m 777 -p ./$ALLURE_RESULTS_DIR"
                    sh "sudo chown -R jenkins:jenkins ./$ALLURE_RESULTS_DIR"

                    if (fileExists("$ALLURE_REPORT_DIR_PATH/$ALLURE_REPORT_DIR/history")) {
                        sh "cp  -r $ALLURE_REPORT_DIR_PATH/$ALLURE_REPORT_DIR/history ./$ALLURE_RESULTS_DIR/history"
                        sh "cp  -r $ALLURE_REPORT_DIR_PATH/$ALLURE_REPORT_DIR/data ./$ALLURE_RESULTS_DIR/data"
                    }
                }
            }
        }

        stage('Build') {
            steps {
                script {
                    //git url: "${GIT_URL}", branch: 'test'
                    sh 'docker build -t dhis2/cypress-tests:master .'
                }
            }
        }

        stage ('Create DHIS2 instances') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: 'e2e-im-user', passwordVariable: 'PASSWORD', usernameVariable: 'USER_EMAIL')]) {
                        echo "Creating DHIS2 $VERSION instance ..."

                        // move to deploy script?
                        randomInt = new Random().nextInt(9999)
                        INSTANCE_NAME = "e2e-cy-$randomInt"

                        sh "./scripts/launch-dhis2-instance.sh $INSTANCE_NAME whoami $VERSION"
                    }
                }
            }
        }

        stage('Test') {
            environment {
                CYPRESS_BASE_URL = "${INSTANCE_DOMAIN}/${INSTANCE_NAME}"
            }

            steps {
                script {
                    sh "docker-compose up --exit-code-from cypress-tests"
                }
            }

            post {
                always {
                    script {
                        sh 'python3 ./merge_launches.py'
                    }
                }
            }
        }
    }

    post {
        always {
            script {
                sh "sudo chmod -R o+xw ${ALLURE_RESULTS_DIR}"
                allure results: [[path: "${ALLURE_RESULTS_DIR}"]], report: "$ALLURE_REPORT_DIR_PATH/$ALLURE_REPORT_DIR", includeProperties: true
            }
        }

        success {
            script {
                withCredentials([usernamePassword(credentialsId: 'e2e-im-user', passwordVariable: 'PASSWORD', usernameVariable: 'USER_EMAIL')]) {
                    echo "Deleting DHIS2 $VERSION instance ..."

                    sh "./scripts/destroy-dhis2-instance.sh ${INSTANCE_NAME} whoami"
                }
            }
        }
    }
}
