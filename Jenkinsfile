pipeline {

    agent any

    options {
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }

    stages {

        // ─────────────────────────────────────
        // STAGE 1: CHECKOUT
        // ─────────────────────────────────────
        stage('Stage 1: Checkout Code') {
            steps {
                echo '========================================'
                echo '   STAGE 1: CHECKOUT SOURCE CODE'
                echo '========================================'

                checkout scm

                sh '''
                    echo ""
                    echo "Project Files:"
                    ls -la
                    echo ""
                    echo "Terraform Files:"
                    ls -la terraform/
                    echo ""
                    echo "Checkout complete"
                '''
            }
        }


        // ─────────────────────────────────────
        // STAGE 2: TRIVY SECURITY SCAN
        // ─────────────────────────────────────
        stage('Stage 2: Trivy IaC Security Scan') {
            steps {
                echo '========================================'
                echo '   STAGE 2: TRIVY SECURITY SCAN'
                echo '========================================'

                sh '''
                    echo ""
                    echo "Trivy Version:"
                    trivy --version
                    echo ""
                    echo "=================================================="
                    echo "   SCANNING terraform/ for vulnerabilities..."
                    echo "=================================================="
                    echo ""

                    # Run Trivy table scan - shows human readable output
                    trivy config \
                        --severity CRITICAL,HIGH,MEDIUM,LOW \
                        --format table \
                        terraform/ 2>&1 | tee trivy-table-report.txt

                    echo ""
                    echo "=================================================="

                    # Run Trivy JSON scan - for counting
                    trivy config \
                        --severity CRITICAL,HIGH,MEDIUM,LOW \
                        --format json \
                        terraform/ > trivy-json-report.json 2>/dev/null || true

                    echo ""
                    echo "=================================================="
                    echo "      LIVE VULNERABILITY COUNT                    "
                    echo "=================================================="

                    # Count each severity from JSON output
                    CRITICAL=$(grep -o '"Severity":"CRITICAL"' trivy-json-report.json | wc -l | tr -d ' ')
                    HIGH=$(grep -o '"Severity":"HIGH"' trivy-json-report.json | wc -l | tr -d ' ')
                    MEDIUM=$(grep -o '"Severity":"MEDIUM"' trivy-json-report.json | wc -l | tr -d ' ')
                    LOW=$(grep -o '"Severity":"LOW"' trivy-json-report.json | wc -l | tr -d ' ')

                    CRITICAL=${CRITICAL:-0}
                    HIGH=${HIGH:-0}
                    MEDIUM=${MEDIUM:-0}
                    LOW=${LOW:-0}

                    TOTAL=$((CRITICAL + HIGH + MEDIUM + LOW))

                    echo ""
                    echo "  +------------------------------------------+"
                    echo "  |   TOTAL VULNERABILITIES FOUND : $TOTAL    |"
                    echo "  +------------------------------------------+"
                    echo "  |  CRITICAL : $CRITICAL issue(s)            |"
                    echo "  |  HIGH     : $HIGH issue(s)                |"
                    echo "  |  MEDIUM   : $MEDIUM issue(s)              |"
                    echo "  |  LOW      : $LOW issue(s)                 |"
                    echo "  +------------------------------------------+"
                    echo ""
                    echo "  NOTE: This count updates automatically."
                    echo "  Fix a vulnerability -> re-run -> count drops."
                    echo ""
                    echo "=================================================="
                    echo "   PIPELINE DECISION                             "
                    echo "=================================================="
                    echo ""

                    if [ "$CRITICAL" -gt 0 ]; then
                        echo "  STATUS : FAILED"
                        echo "  REASON : $CRITICAL CRITICAL issue(s) found"
                        echo "  ACTION : Fix CRITICAL issues in terraform/main.tf"
                        echo "  NEXT   : Push fix to GitHub and re-run pipeline"
                        echo ""
                        echo "  BUILD FAILED - DO NOT DEPLOY"
                        echo "  Fix issues shown in scan above"
                        exit 1
                    else
                        echo "  STATUS : PASSED"
                        echo "  REASON : Zero CRITICAL issues found"
                        echo "  TOTAL  : $TOTAL remaining issue(s)"
                        echo ""
                        echo "  BUILD PASSED - Safe to proceed"
                    fi
                '''
            }

            post {
                always {
                    archiveArtifacts artifacts: 'trivy-table-report.txt',
                                     allowEmptyArchive: true
                    archiveArtifacts artifacts: 'trivy-json-report.json',
                                     allowEmptyArchive: true
                }
                failure {
                    echo 'SCAN FAILED - Fix vulnerabilities shown above'
                    echo 'Then push to GitHub and re-run pipeline'
                }
                success {
                    echo 'SCAN PASSED - Zero critical vulnerabilities'
                }
            }
        }


        // ─────────────────────────────────────
        // STAGE 3: TERRAFORM PLAN
        // Runs only if Stage 2 passes
        // ─────────────────────────────────────
        stage('Stage 3: Terraform Plan') {
            steps {
                echo '========================================'
                echo '   STAGE 3: TERRAFORM PLAN'
                echo '========================================'

                sh '''
                    cd terraform

                    echo "Running terraform init..."
                    echo "------------------------------------------"
                    terraform init -no-color

                    echo ""
                    echo "Running terraform validate..."
                    echo "------------------------------------------"
                    terraform validate -no-color

                    echo ""
                    echo "Running terraform plan..."
                    echo "------------------------------------------"
                    terraform plan \
                        -var="aws_region=us-east-1" \
                        -var="environment=demo" \
                        -no-color

                    echo ""
                    echo "Terraform plan complete"
                '''
            }

            post {
                success {
                    echo 'Terraform plan successful'
                }
                failure {
                    echo 'Terraform plan failed - check AWS credentials'
                }
            }
        }
    }


    post {
        success {
            echo '''
            ==========================================
              PIPELINE PASSED
              Stage 1 Checkout          - OK
              Stage 2 Trivy Scan        - OK (0 Critical)
              Stage 3 Terraform Plan    - OK
              Infrastructure is secure and ready
            ==========================================
            '''
        }
        failure {
            echo '''
            ==========================================
              PIPELINE FAILED
              NEXT STEPS:
              1. Check Stage 2 scan output above
              2. See exact file and line numbers
              3. Fix terraform/main.tf in VS Code
              4. git add . and git commit and git push
              5. Re-run pipeline
              6. Count will update automatically
            ==========================================
            '''
        }
        always {
            echo "Build Number : ${env.BUILD_NUMBER}"
            echo "Job Name     : ${env.JOB_NAME}"
            echo "Result       : ${currentBuild.currentResult}"
        }
    }
}