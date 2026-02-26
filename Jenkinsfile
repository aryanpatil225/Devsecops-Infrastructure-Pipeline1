pipeline {

    agent any

    options {
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }

    stages {

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


        stage('Stage 2: Trivy IaC Security Scan') {
            steps {
                echo '========================================'
                echo '   STAGE 2: TRIVY SECURITY SCAN'
                echo '========================================'

                sh '''
                    echo ""
                    echo "Trivy Version:"
                    trivy --version | head -1
                    echo ""
                    echo "=================================================="
                    echo "   SCANNING terraform/ for vulnerabilities"
                    echo "=================================================="
                    echo ""

                    # ── TABLE SCAN (human readable in console) ──────────
                    trivy config \
                        --severity CRITICAL,HIGH,MEDIUM,LOW \
                        --format table \
                        terraform/ 2>&1 | tee trivy-table-report.txt

                    echo ""

                    # ── JSON SCAN (for live counting) ────────────────────
                    trivy config \
                        --severity CRITICAL,HIGH,MEDIUM,LOW \
                        --format json \
                        terraform/ 2>/dev/null > trivy-json-report.json || true

                    echo ""
                    echo "=================================================="
                    echo "   LIVE VULNERABILITY COUNT"
                    echo "   (Changes automatically when you fix issues)"
                    echo "=================================================="
                    echo ""

                    # ── LIVE COUNT ────────────────────────────────────────
                    # Read directly from the TABLE report summary line
                    # Trivy prints: Failures: 7 (LOW: 0, MEDIUM: 1, HIGH: 4, CRITICAL: 2)
                    # We extract numbers from that exact line

                    SUMMARY_LINE=$(grep "^Failures:" trivy-table-report.txt 2>/dev/null | tail -1)

                    echo "  Raw summary from Trivy: $SUMMARY_LINE"
                    echo ""

                    if [ -z "$SUMMARY_LINE" ]; then
                        # No failures line = zero issues
                        CRITICAL=0
                        HIGH=0
                        MEDIUM=0
                        LOW=0
                    else
                        # Extract each count from: Failures: 7 (LOW: 0, MEDIUM: 1, HIGH: 4, CRITICAL: 2)
                        CRITICAL=$(echo "$SUMMARY_LINE" | grep -o "CRITICAL: [0-9]*" | grep -o "[0-9]*" || echo "0")
                        HIGH=$(echo "$SUMMARY_LINE" | grep -o "HIGH: [0-9]*" | grep -o "[0-9]*" || echo "0")
                        MEDIUM=$(echo "$SUMMARY_LINE" | grep -o "MEDIUM: [0-9]*" | grep -o "[0-9]*" || echo "0")
                        LOW=$(echo "$SUMMARY_LINE" | grep -o "LOW: [0-9]*" | grep -o "[0-9]*" || echo "0")
                    fi

                    # Default to 0 if empty
                    CRITICAL=${CRITICAL:-0}
                    HIGH=${HIGH:-0}
                    MEDIUM=${MEDIUM:-0}
                    LOW=${LOW:-0}
                    TOTAL=$((CRITICAL + HIGH + MEDIUM + LOW))

                    # ── PRINT LIVE COUNT BOX ──────────────────────────────
                    echo "  +--------------------------------------------+"
                    echo "  |        LIVE VULNERABILITY SUMMARY          |"
                    echo "  +--------------------------------------------+"
                    printf "  |  TOTAL FOUND      :  %-3s                  |\n" "$TOTAL"
                    echo "  +--------------------------------------------+"
                    printf "  |  CRITICAL         :  %-3s                  |\n" "$CRITICAL"
                    printf "  |  HIGH             :  %-3s                  |\n" "$HIGH"
                    printf "  |  MEDIUM           :  %-3s                  |\n" "$MEDIUM"
                    printf "  |  LOW              :  %-3s                  |\n" "$LOW"
                    echo "  +--------------------------------------------+"
                    echo "  |  Fix an issue -> push -> re-run pipeline   |"
                    echo "  |  Count will drop automatically each time   |"
                    echo "  +--------------------------------------------+"
                    echo ""

                    # ── PASS / FAIL DECISION ──────────────────────────────
                    echo "=================================================="
                    echo "   PIPELINE DECISION"
                    echo "=================================================="
                    echo ""

                    if [ "$CRITICAL" -gt 0 ]; then
                        echo "  STATUS  : FAILED"
                        echo "  REASON  : $CRITICAL CRITICAL issue(s) found"
                        echo "  POLICY  : Zero CRITICAL tolerance"
                        echo "  ACTION  : Fix CRITICAL issues in terraform/main.tf"
                        echo "  NEXT    : git push and re-run pipeline"
                        echo ""
                        echo "  BUILD FAILED - DO NOT DEPLOY"
                        exit 1
                    else
                        echo "  STATUS  : PASSED"
                        echo "  REASON  : Zero CRITICAL issues found"
                        echo "  TOTAL   : $TOTAL remaining issue(s)"
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


        stage('Stage 3: Terraform Plan') {
            steps {
                echo '========================================'
                echo '   STAGE 3: TERRAFORM PLAN'
                echo '========================================'
                sh '''
                    cd terraform

                    echo "Running terraform init..."
                    terraform init -no-color

                    echo ""
                    echo "Running terraform validate..."
                    terraform validate -no-color

                    echo ""
                    echo "Running terraform plan..."
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
              Stage 1 Checkout       - OK
              Stage 2 Trivy Scan     - OK (0 Critical)
              Stage 3 Terraform Plan - OK
            ==========================================
            '''
        }
        failure {
            echo '''
            ==========================================
              PIPELINE FAILED
              1. Check Stage 2 scan output above
              2. Fix terraform/main.tf in VS Code
              3. git add . and git commit and git push
              4. Re-run pipeline - count updates live
            ==========================================
            '''
        }
        always {
            echo "Build   : #${env.BUILD_NUMBER}"
            echo "Job     : ${env.JOB_NAME}"
            echo "Result  : ${currentBuild.currentResult}"
        }
    }
}