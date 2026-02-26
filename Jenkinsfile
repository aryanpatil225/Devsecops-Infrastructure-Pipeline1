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

                sh '''#!/bin/bash
                    set +x

                    echo ""
                    echo "  Trivy Version : $(trivy --version 2>/dev/null | head -1)"
                    echo "  Target        : terraform/"
                    echo "  Severity      : CRITICAL, HIGH, MEDIUM, LOW"
                    echo ""
                    echo "========================================================"
                    echo "  FULL TRIVY SCAN REPORT"
                    echo "  Every issue shown with file name and line number"
                    echo "========================================================"
                    echo ""

                    trivy config \
                        --severity CRITICAL,HIGH,MEDIUM,LOW \
                        --format table \
                        terraform/ 2>&1 | tee trivy-table-report.txt

                    trivy config \
                        --severity CRITICAL,HIGH,MEDIUM,LOW \
                        --format json \
                        terraform/ 2>/dev/null > trivy-json-report.json || true

                    SUMMARY_LINE=$(grep "^Failures:" trivy-table-report.txt 2>/dev/null | tail -1)

                    if [ -z "$SUMMARY_LINE" ]; then
                        CRITICAL=0; HIGH=0; MEDIUM=0; LOW=0
                    else
                        CRITICAL=$(echo "$SUMMARY_LINE" | grep -o "CRITICAL: [0-9]*" | grep -o "[0-9]*" || echo "0")
                        HIGH=$(echo "$SUMMARY_LINE" | grep -o "HIGH: [0-9]*" | grep -o "[0-9]*" || echo "0")
                        MEDIUM=$(echo "$SUMMARY_LINE" | grep -o "MEDIUM: [0-9]*" | grep -o "[0-9]*" || echo "0")
                        LOW=$(echo "$SUMMARY_LINE" | grep -o "LOW: [0-9]*" | grep -o "[0-9]*" || echo "0")
                    fi

                    CRITICAL=${CRITICAL:-0}
                    HIGH=${HIGH:-0}
                    MEDIUM=${MEDIUM:-0}
                    LOW=${LOW:-0}
                    TOTAL=$((CRITICAL + HIGH + MEDIUM + LOW))

                    echo ""
                    echo "========================================================"
                    echo "  VULNERABILITY DETAILS TABLE"
                    echo "  Only rows present in current code are shown"
                    echo "  Fix an issue and re-run - that row disappears"
                    echo "========================================================"
                    echo ""
                    echo "  +----------+----------+--------------------+----------------------+----------+"
                    echo "  | AWS ID   | SEVERITY | RESOURCE           | ISSUE                | LINE     |"
                    echo "  +----------+----------+--------------------+----------------------+----------+"

                    grep -q "AWS-0029" trivy-table-report.txt 2>/dev/null && \
                    echo "  | AWS-0029 | CRITICAL | aws_instance       | Secrets in user_data | 235-267  |" && \
                    echo "  +----------+----------+--------------------+----------------------+----------+"

                    grep -q "AWS-0104" trivy-table-report.txt 2>/dev/null && \
                    echo "  | AWS-0104 | CRITICAL | aws_security_group | Unrestricted egress  | 196      |" && \
                    echo "  +----------+----------+--------------------+----------------------+----------+"

                    grep -q "AWS-0028" trivy-table-report.txt 2>/dev/null && \
                    echo "  | AWS-0028 | HIGH     | aws_instance       | IMDSv2 not required  | 216-272  |" && \
                    echo "  +----------+----------+--------------------+----------------------+----------+"

                    grep -q "AWS-0107" trivy-table-report.txt 2>/dev/null && \
                    echo "  | AWS-0107 | HIGH     | aws_security_group | SSH open to world    | 169      |" && \
                    echo "  +----------+----------+--------------------+----------------------+----------+"

                    grep -q "AWS-0131" trivy-table-report.txt 2>/dev/null && \
                    echo "  | AWS-0131 | HIGH     | aws_instance       | EBS not encrypted    | 231      |" && \
                    echo "  +----------+----------+--------------------+----------------------+----------+"

                    grep -q "AWS-0164" trivy-table-report.txt 2>/dev/null && \
                    echo "  | AWS-0164 | HIGH     | aws_subnet         | Public IP assigned   | 94       |" && \
                    echo "  +----------+----------+--------------------+----------------------+----------+"

                    grep -q "AWS-0178" trivy-table-report.txt 2>/dev/null && \
                    echo "  | AWS-0178 | MEDIUM   | aws_vpc            | Flow Logs missing    | 42-50    |" && \
                    echo "  +----------+----------+--------------------+----------------------+----------+"

                    echo ""
                    echo "========================================================"
                    echo "  LIVE VULNERABILITY COUNT"
                    echo "  Updates automatically every pipeline run"
                    echo "========================================================"
                    echo ""
                    echo "  +--------------------------------+-------+"
                    echo "  | SEVERITY                       | COUNT |"
                    echo "  +--------------------------------+-------+"
                    printf "  | CRITICAL  (Must fix to pass)   |  %-4s |\n" "$CRITICAL"
                    echo "  +--------------------------------+-------+"
                    printf "  | HIGH      (Fix before prod)    |  %-4s |\n" "$HIGH"
                    echo "  +--------------------------------+-------+"
                    printf "  | MEDIUM    (Recommended fix)    |  %-4s |\n" "$MEDIUM"
                    echo "  +--------------------------------+-------+"
                    printf "  | LOW       (Minor risk)         |  %-4s |\n" "$LOW"
                    echo "  +--------------------------------+-------+"
                    printf "  | TOTAL                          |  %-4s |\n" "$TOTAL"
                    echo "  +--------------------------------+-------+"
                    echo ""

                    echo "========================================================"
                    echo "  PIPELINE DECISION"
                    echo "========================================================"
                    echo ""

                    if [ "$CRITICAL" -gt 0 ]; then
                        echo "  STATUS  : FAILED"
                        echo "  REASON  : $CRITICAL CRITICAL issue(s) found"
                        echo "  POLICY  : Zero CRITICAL tolerance"
                        echo ""
                        echo "  +---------------------------------------------+"
                        echo "  |   BUILD FAILED - DO NOT DEPLOY TO AWS      |"
                        echo "  |   Fix CRITICAL issues and re-run pipeline   |"
                        echo "  +---------------------------------------------+"
                        exit 1
                    else
                        echo "  STATUS  : PASSED"
                        echo "  REASON  : Zero CRITICAL issues found"
                        echo "  TOTAL   : $TOTAL remaining (non-critical)"
                        echo ""
                        echo "  +---------------------------------------------+"
                        echo "  |   BUILD PASSED - SAFE TO DEPLOY TO AWS     |"
                        echo "  +---------------------------------------------+"
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
                    echo '  SCAN FAILED - Fix vulnerabilities and re-run'
                }
                success {
                    echo '  SCAN PASSED - Zero critical vulnerabilities'
                }
            }
        }


        stage('Stage 3: Terraform Plan') {
            steps {
                echo '========================================'
                echo '   STAGE 3: TERRAFORM PLAN'
                echo '========================================'
                sh '''#!/bin/bash
                    set +x
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
  +---------------------------------------------+
  |         FULL PIPELINE PASSED                |
  |                                             |
  |  Stage 1 - Checkout       : DONE           |
  |  Stage 2 - Trivy Scan     : 0 CRITICAL     |
  |  Stage 3 - Terraform Plan : DONE           |
  |                                             |
  |  Infrastructure is secure and ready        |
  +---------------------------------------------+
            '''
        }
        failure {
            echo '''
  +---------------------------------------------+
  |         PIPELINE FAILED                     |
  |                                             |
  |  1. Scroll up to Stage 2 output            |
  |  2. Check VULNERABILITY DETAILS TABLE      |
  |  3. Check LIVE COUNT SUMMARY table         |
  |  4. Fix terraform/main.tf in VS Code       |
  |  5. git add . and commit and push          |
  |  6. Re-run - count updates automatically   |
  +---------------------------------------------+
            '''
        }
        always {
            echo "  Build  : #${env.BUILD_NUMBER}"
            echo "  Job    : ${env.JOB_NAME}"
            echo "  Result : ${currentBuild.currentResult}"
        }
    }
}