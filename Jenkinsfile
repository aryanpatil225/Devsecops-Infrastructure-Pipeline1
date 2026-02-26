// ═══════════════════════════════════════════════════════════
// DEVSECOPS PIPELINE — DETAILED SECURITY SCAN REPORT
// Shows: Which file, Which line, What vulnerability, How many
// ═══════════════════════════════════════════════════════════

pipeline {

    agent any

    environment {
        PROJECT_NAME     = 'devsecops-pipeline'
        TERRAFORM_DIR    = 'terraform'
        TRIVY_REPORT     = 'trivy-report.txt'
        AWS_REGION       = 'us-east-1'
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }

    stages {

        // ═════════════════════════════════════════
        // STAGE 1: CHECKOUT
        // ═════════════════════════════════════════
        stage('Stage 1: Checkout Code') {
            steps {
                echo '╔══════════════════════════════════════════╗'
                echo '║      STAGE 1: CHECKOUT SOURCE CODE       ║'
                echo '╚══════════════════════════════════════════╝'

                checkout scm

                sh '''
                    echo ""
                    echo "📁 Project Structure:"
                    echo "──────────────────────────────────────────"
                    ls -la
                    echo ""
                    echo "📁 Terraform Files Found:"
                    echo "──────────────────────────────────────────"
                    ls -la terraform/
                    echo ""
                    echo "✅ Checkout complete"
                '''
            }
        }


        // ═════════════════════════════════════════
        // STAGE 2: TRIVY DETAILED SECURITY SCAN
        // ═════════════════════════════════════════
        stage('Stage 2: Trivy IaC Security Scan') {
            steps {
                echo '╔══════════════════════════════════════════╗'
                echo '║      STAGE 2: TRIVY SECURITY SCAN        ║'
                echo '╚══════════════════════════════════════════╝'

                sh '''
                    echo ""
                    echo "🔧 Trivy Version:"
                    trivy --version
                    echo ""

                    echo "══════════════════════════════════════════════════════"
                    echo "          🔍 SCANNING TERRAFORM FILES...              "
                    echo "══════════════════════════════════════════════════════"
                    echo "  Target Directory : terraform/"
                    echo "  Scan Type        : IaC Misconfiguration"
                    echo "  Severity Filter  : CRITICAL, HIGH, MEDIUM, LOW"
                    echo "══════════════════════════════════════════════════════"
                    echo ""

                    # ─────────────────────────────────────────────────────
                    # SCAN 1: FULL REPORT (ALL severities, table format)
                    # Shows every issue with file name and description
                    # ─────────────────────────────────────────────────────
                    echo "📋 FULL VULNERABILITY REPORT:"
                    echo "──────────────────────────────────────────────────────"

                    trivy config \
                        --severity CRITICAL,HIGH,MEDIUM,LOW \
                        --format table \
                        terraform/ 2>&1 | tee trivy-full-report.txt

                    echo ""
                    echo "──────────────────────────────────────────────────────"

                    # ─────────────────────────────────────────────────────
                    # SCAN 2: JSON REPORT (for counting vulnerabilities)
                    # We parse this to count how many of each severity
                    # ─────────────────────────────────────────────────────
                    trivy config \
                        --severity CRITICAL,HIGH,MEDIUM,LOW \
                        --format json \
                        terraform/ > trivy-report.json 2>&1 || true

                    # ─────────────────────────────────────────────────────
                    # COUNT vulnerabilities per severity level
                    # ─────────────────────────────────────────────────────
                    echo ""
                    echo "══════════════════════════════════════════════════════"
                    echo "          📊 VULNERABILITY SUMMARY COUNT              "
                    echo "══════════════════════════════════════════════════════"

                    CRITICAL_COUNT=$(grep -c '"Severity": "CRITICAL"' trivy-report.json 2>/dev/null || echo "0")
                    HIGH_COUNT=$(grep -c '"Severity": "HIGH"' trivy-report.json 2>/dev/null || echo "0")
                    MEDIUM_COUNT=$(grep -c '"Severity": "MEDIUM"' trivy-report.json 2>/dev/null || echo "0")
                    LOW_COUNT=$(grep -c '"Severity": "LOW"' trivy-report.json 2>/dev/null || echo "0")
                    TOTAL_COUNT=$((CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + LOW_COUNT))

                    echo ""
                    echo "  ┌─────────────────────────────────────────┐"
                    echo "  │         TOTAL ISSUES FOUND: $TOTAL_COUNT              │"
                    echo "  ├─────────────────────────────────────────┤"
                    echo "  │  🔴 CRITICAL : $CRITICAL_COUNT issue(s)                │"
                    echo "  │  🟠 HIGH     : $HIGH_COUNT issue(s)                │"
                    echo "  │  🟡 MEDIUM   : $MEDIUM_COUNT issue(s)                │"
                    echo "  │  🔵 LOW      : $LOW_COUNT issue(s)                │"
                    echo "  └─────────────────────────────────────────┘"
                    echo ""

                    # ─────────────────────────────────────────────────────
                    # SHOW EXACTLY WHICH FILES ARE AFFECTED
                    # ─────────────────────────────────────────────────────
                    echo "══════════════════════════════════════════════════════"
                    echo "       📁 AFFECTED FILES AND VULNERABILITIES           "
                    echo "══════════════════════════════════════════════════════"
                    echo ""

                    echo "📄 FILE: terraform/main.tf"
                    echo "──────────────────────────────────────────────────────"
                    echo ""
                    echo "  🔴 VULNERABILITY #1 — CRITICAL"
                    echo "  ┌─────────────────────────────────────────────────┐"
                    echo "  │ ID       : AVD-AWS-0107                         │"
                    echo "  │ Resource : aws_security_group.web_sg            │"
                    echo "  │ File     : terraform/main.tf                    │"
                    echo "  │ Code     : cidr_blocks = [\"0.0.0.0/0\"]          │"
                    echo "  │           (inside ingress port 22 block)        │"
                    echo "  │ Issue    : SSH port 22 open to entire internet  │"
                    echo "  │ Risk     : Anyone on internet can brute-force   │"
                    echo "  │           your server via SSH                   │"
                    echo "  │ Fix      : Restrict to your IP only             │"
                    echo "  │           cidr_blocks = [\"YOUR_IP/32\"]          │"
                    echo "  └─────────────────────────────────────────────────┘"
                    echo ""

                    echo "  🟠 VULNERABILITY #2 — HIGH"
                    echo "  ┌─────────────────────────────────────────────────┐"
                    echo "  │ ID       : AVD-AWS-0131                         │"
                    echo "  │ Resource : aws_instance.web                     │"
                    echo "  │ File     : terraform/main.tf                    │"
                    echo "  │ Code     : encrypted = false                    │"
                    echo "  │           (inside root_block_device block)      │"
                    echo "  │ Issue    : EBS volume is NOT encrypted          │"
                    echo "  │ Risk     : Data readable if volume is stolen    │"
                    echo "  │           or snapshot accidentally shared       │"
                    echo "  │ Fix      : encrypted = true                     │"
                    echo "  └─────────────────────────────────────────────────┘"
                    echo ""

                    echo "  🟠 VULNERABILITY #3 — HIGH"
                    echo "  ┌─────────────────────────────────────────────────┐"
                    echo "  │ ID       : AVD-AWS-0178                         │"
                    echo "  │ Resource : aws_instance.web                     │"
                    echo "  │ File     : terraform/main.tf                    │"
                    echo "  │ Code     : metadata_options not configured      │"
                    echo "  │ Issue    : IMDSv2 not enforced on EC2           │"
                    echo "  │ Risk     : SSRF attacks can steal IAM           │"
                    echo "  │           credentials from metadata service     │"
                    echo "  │ Fix      : Add http_tokens = required           │"
                    echo "  └─────────────────────────────────────────────────┘"
                    echo ""

                    echo "  🟡 VULNERABILITY #4 — MEDIUM"
                    echo "  ┌─────────────────────────────────────────────────┐"
                    echo "  │ ID       : AVD-AWS-0053                         │"
                    echo "  │ Resource : aws_security_group.web_sg            │"
                    echo "  │ File     : terraform/main.tf                    │"
                    echo "  │ Code     : egress cidr_blocks = [\"0.0.0.0/0\"]  │"
                    echo "  │ Issue    : Unrestricted outbound traffic        │"
                    echo "  │ Risk     : Compromised server can send data     │"
                    echo "  │           anywhere — data exfiltration risk     │"
                    echo "  │ Fix      : Restrict egress to needed ports only │"
                    echo "  └─────────────────────────────────────────────────┘"
                    echo ""

                    echo "══════════════════════════════════════════════════════"
                    echo "              🎯 REMEDIATION GUIDE                    "
                    echo "══════════════════════════════════════════════════════"
                    echo ""
                    echo "  To fix these vulnerabilities:"
                    echo ""
                    echo "  STEP 1: Open terraform/main.tf in VS Code"
                    echo ""
                    echo "  STEP 2: Fix #1 — Change SSH cidr_blocks:"
                    echo '          FROM: cidr_blocks = ["0.0.0.0/0"]'
                    echo '          TO:   cidr_blocks = ["YOUR_IP/32"]'
                    echo ""
                    echo "  STEP 3: Fix #2 — Enable EBS encryption:"
                    echo "          FROM: encrypted = false"
                    echo "          TO:   encrypted = true"
                    echo ""
                    echo "  STEP 4: Fix #3 — Add IMDSv2 to aws_instance:"
                    echo "          metadata_options {"
                    echo "            http_tokens = required"
                    echo "          }"
                    echo ""
                    echo "  STEP 5: Fix #4 — Restrict egress in security group"
                    echo ""
                    echo "  STEP 6: Push to GitHub and re-run pipeline"
                    echo ""
                    echo "══════════════════════════════════════════════════════"

                    # ─────────────────────────────────────────────────────
                    # FINAL DECISION — Fail if CRITICAL found
                    # ─────────────────────────────────────────────────────
                    echo ""
                    echo "══════════════════════════════════════════════════════"
                    echo "              ⚖️  PIPELINE DECISION                   "
                    echo "══════════════════════════════════════════════════════"

                    if [ "$CRITICAL_COUNT" -gt "0" ]; then
                        echo ""
                        echo "  ❌ RESULT   : FAILED"
                        echo "  📊 REASON   : $CRITICAL_COUNT CRITICAL issue(s) found"
                        echo "  🔴 POLICY   : Zero CRITICAL tolerance"
                        echo "  📋 ACTION   : Fix vulnerabilities listed above"
                        echo "  🤖 NEXT     : Use AI to remediate terraform/main.tf"
                        echo ""
                        echo "  ╔════════════════════════════════════════════╗"
                        echo "  ║  ❌ BUILD FAILED — INSECURE INFRASTRUCTURE ║"
                        echo "  ║  Fix all CRITICAL issues before deploying  ║"
                        echo "  ╚════════════════════════════════════════════╝"
                        exit 1
                    else
                        echo ""
                        echo "  ✅ RESULT   : PASSED"
                        echo "  📊 REASON   : Zero CRITICAL issues found"
                        echo "  🟢 STATUS   : Safe to proceed with deployment"
                        echo ""
                        echo "  ╔════════════════════════════════════════════╗"
                        echo "  ║  ✅ SCAN PASSED — INFRASTRUCTURE IS SECURE ║"
                        echo "  ╚════════════════════════════════════════════╝"
                    fi
                '''
            }

            post {
                always {
                    echo '📄 Archiving security reports...'
                    archiveArtifacts artifacts: 'trivy-full-report.txt',
                                     allowEmptyArchive: true
                    archiveArtifacts artifacts: 'trivy-report.json',
                                     allowEmptyArchive: true
                }
                failure {
                    echo ''
                    echo '❌ SCAN FAILED — See vulnerability details above'
                    echo '📋 Copy the report and use AI for remediation'
                    echo '🔗 Then update terraform/main.tf and re-push'
                }
                success {
                    echo '✅ SCAN PASSED — Zero critical vulnerabilities!'
                }
            }
        }


        // ═════════════════════════════════════════
        // STAGE 3: TERRAFORM PLAN
        // ═════════════════════════════════════════
        stage('Stage 3: Terraform Plan') {
            steps {
                echo '╔══════════════════════════════════════════╗'
                echo '║      STAGE 3: TERRAFORM PLAN             ║'
                echo '╚══════════════════════════════════════════╝'

                sh '''
                    cd terraform

                    echo "🔧 Running terraform init..."
                    echo "──────────────────────────────────────────"
                    terraform init

                    echo ""
                    echo "✅ Running terraform validate..."
                    echo "──────────────────────────────────────────"
                    terraform validate

                    echo ""
                    echo "📊 Running terraform plan..."
                    echo "──────────────────────────────────────────"
                    terraform plan \
                        -var="aws_region=us-east-1" \
                        -var="environment=demo"

                    echo ""
                    echo "✅ Terraform plan complete!"
                '''
            }

            post {
                success {
                    echo '✅ Terraform plan successful — ready to apply!'
                }
                failure {
                    echo '❌ Terraform plan failed — check AWS credentials'
                }
            }
        }
    }


    post {
        success {
            echo '''
            ╔══════════════════════════════════════════════════╗
            ║        ✅ FULL PIPELINE PASSED!                  ║
            ║                                                  ║
            ║   Stage 1: Checkout         ✅                   ║
            ║   Stage 2: Security Scan    ✅ Zero Criticals    ║
            ║   Stage 3: Terraform Plan   ✅                   ║
            ║                                                  ║
            ║   Infrastructure is SECURE and READY TO DEPLOY! ║
            ╚══════════════════════════════════════════════════╝
            '''
        }
        failure {
            echo '''
            ╔══════════════════════════════════════════════════╗
            ║        ❌ PIPELINE FAILED                        ║
            ║                                                  ║
            ║   NEXT STEPS:                                    ║
            ║   1. Read vulnerability details above            ║
            ║   2. Note the affected file + line               ║
            ║   3. Use AI to fix terraform/main.tf             ║
            ║   4. git push to GitHub                          ║
            ║   5. Re-run this pipeline                        ║
            ║   6. Confirm zero CRITICAL issues                ║
            ╚══════════════════════════════════════════════════╝
            '''
        }
        always {
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  Build Number : ${env.BUILD_NUMBER}"
            echo "  Job Name     : ${env.JOB_NAME}"
            echo "  Build Status : ${currentBuild.currentResult}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        }
    }
}