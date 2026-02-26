// ═══════════════════════════════════════════════════════════
// DEVSECOPS PIPELINE — LIVE AUTO-UPDATING VULNERABILITY COUNT
// Uses shell + awk to count from real Trivy JSON output
// No Python needed — works with pure bash
// ═══════════════════════════════════════════════════════════

pipeline {

    agent any

    environment {
        PROJECT_NAME  = 'devsecops-pipeline'
        TERRAFORM_DIR = 'terraform'
        AWS_REGION    = 'us-east-1'
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
                    echo "📁 Terraform Files:"
                    echo "──────────────────────────────────────────"
                    ls -la terraform/
                    echo ""
                    echo "✅ Stage 1 Complete — Code checked out"
                    echo ""
                '''
            }
        }


        // ═════════════════════════════════════════
        // STAGE 2: TRIVY LIVE SECURITY SCAN
        // Counts vulnerabilities dynamically
        // from real Trivy output — updates on fix
        // ═════════════════════════════════════════
        stage('Stage 2: Trivy IaC Security Scan') {
            steps {
                echo '╔══════════════════════════════════════════╗'
                echo '║      STAGE 2: TRIVY SECURITY SCAN        ║'
                echo '╚══════════════════════════════════════════╝'

                sh '''
                    echo ""
                    echo "🔧 Trivy Version: $(trivy --version | head -1)"
                    echo "──────────────────────────────────────────"
                    echo ""

                    # ─────────────────────────────────────────
                    # STEP A: Run Trivy — Table format (human readable)
                    # This shows exact file + line + description
                    # ─────────────────────────────────────────
                    echo "══════════════════════════════════════════════════"
                    echo "   🔍 SCANNING: terraform/ directory              "
                    echo "══════════════════════════════════════════════════"
                    echo ""

                    # Run scan - save output AND show in console
                    trivy config \
                        --severity CRITICAL,HIGH,MEDIUM,LOW \
                        --format table \
                        terraform/ 2>&1 | tee trivy-table-report.txt

                    echo ""
                    echo "══════════════════════════════════════════════════"
                    echo ""

                    # ─────────────────────────────────────────
                    # STEP B: Run Trivy — JSON format (for counting)
                    # ─────────────────────────────────────────
                    trivy config \
                        --severity CRITICAL,HIGH,MEDIUM,LOW \
                        --format json \
                        terraform/ > trivy-json-report.json 2>/dev/null || true

                    # ─────────────────────────────────────────
                    # STEP C: COUNT using grep + awk on JSON
                    # This is the LIVE count from THIS scan
                    # When you fix a vuln → count drops automatically
                    # ─────────────────────────────────────────

                    # Count each severity from actual JSON output
                    CRITICAL_COUNT=$(grep -o '"Severity":"CRITICAL"' trivy-json-report.json 2>/dev/null | wc -l | tr -d ' ')
                    HIGH_COUNT=$(grep -o '"Severity":"HIGH"' trivy-json-report.json 2>/dev/null | wc -l | tr -d ' ')
                    MEDIUM_COUNT=$(grep -o '"Severity":"MEDIUM"' trivy-json-report.json 2>/dev/null | wc -l | tr -d ' ')
                    LOW_COUNT=$(grep -o '"Severity":"LOW"' trivy-json-report.json 2>/dev/null | wc -l | tr -d ' ')

                    # If counts are empty set to 0
                    CRITICAL_COUNT=${CRITICAL_COUNT:-0}
                    HIGH_COUNT=${HIGH_COUNT:-0}
                    MEDIUM_COUNT=${MEDIUM_COUNT:-0}
                    LOW_COUNT=${LOW_COUNT:-0}

                    TOTAL=$((CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT + LOW_COUNT))

                    # ─────────────────────────────────────────
                    # STEP D: PRINT LIVE SUMMARY BOX
                    # This number changes EVERY run based on
                    # what is actually in your Terraform code
                    # ─────────────────────────────────────────
                    echo "══════════════════════════════════════════════════"
                    echo "         📊 LIVE VULNERABILITY COUNT              "
                    echo "         (Updates automatically each run)         "
                    echo "══════════════════════════════════════════════════"
                    echo ""
                    echo "  ┌────────────────────────────────────────────┐"
                    printf "  │  %-10s TOTAL ISSUES FOUND : %-6s      │\n" "" "$TOTAL"
                    echo "  ├────────────────────────────────────────────┤"
                    printf "  │  🔴 CRITICAL  : %-3s issues               │\n" "$CRITICAL_COUNT"
                    printf "  │  🟠 HIGH      : %-3s issues               │\n" "$HIGH_COUNT"
                    printf "  │  🟡 MEDIUM    : %-3s issues               │\n" "$MEDIUM_COUNT"
                    printf "  │  🔵 LOW       : %-3s issues               │\n" "$LOW_COUNT"
                    echo "  └────────────────────────────────────────────┘"
                    echo ""

                    # ─────────────────────────────────────────
                    # STEP E: SHOW EACH VULNERABILITY DETAIL
                    # Parsed directly from the table report above
                    # Only shows what currently EXISTS in code
                    # ─────────────────────────────────────────
                    echo "══════════════════════════════════════════════════"
                    echo "    📁 VULNERABILITIES BY FILE & LINE NUMBER      "
                    echo "══════════════════════════════════════════════════"
                    echo ""

                    # Extract and display from the table report
                    # Show AWS ID, severity, file, line number
                    if grep -q "CRITICAL\|HIGH\|MEDIUM\|LOW" trivy-table-report.txt 2>/dev/null; then

                        # Show CRITICAL issues with details
                        if [ "$CRITICAL_COUNT" -gt 0 ]; then
                            echo "  🔴 CRITICAL ISSUES ($CRITICAL_COUNT found):"
                            echo "  ──────────────────────────────────────────────"
                            grep -A2 "(CRITICAL)" trivy-table-report.txt 2>/dev/null | \
                                grep -v "^--$" | \
                                sed 's/^/  /' || true
                            echo ""
                        fi

                        # Show HIGH issues with details
                        if [ "$HIGH_COUNT" -gt 0 ]; then
                            echo "  🟠 HIGH ISSUES ($HIGH_COUNT found):"
                            echo "  ──────────────────────────────────────────────"
                            grep -A2 "(HIGH)" trivy-table-report.txt 2>/dev/null | \
                                grep -v "^--$" | \
                                sed 's/^/  /' || true
                            echo ""
                        fi

                        # Show MEDIUM issues with details
                        if [ "$MEDIUM_COUNT" -gt 0 ]; then
                            echo "  🟡 MEDIUM ISSUES ($MEDIUM_COUNT found):"
                            echo "  ──────────────────────────────────────────────"
                            grep -A2 "(MEDIUM)" trivy-table-report.txt 2>/dev/null | \
                                grep -v "^--$" | \
                                sed 's/^/  /' || true
                            echo ""
                        fi

                        # Show LOW issues
                        if [ "$LOW_COUNT" -gt 0 ]; then
                            echo "  🔵 LOW ISSUES ($LOW_COUNT found):"
                            echo "  ──────────────────────────────────────────────"
                            grep -A2 "(LOW)" trivy-table-report.txt 2>/dev/null | \
                                grep -v "^--$" | \
                                sed 's/^/  /' || true
                            echo ""
                        fi

                    else
                        echo "  ✅ No vulnerabilities found in any file!"
                    fi

                    # ─────────────────────────────────────────
                    # STEP F: SHOW EXACT FILE + LINE REFERENCES
                    # So developer knows EXACTLY what to fix
                    # ─────────────────────────────────────────
                    echo "══════════════════════════════════════════════════"
                    echo "    📍 EXACT LOCATION OF VULNERABLE CODE          "
                    echo "══════════════════════════════════════════════════"
                    echo ""

                    # Extract file:line references from report
                    grep -E "main\.tf:[0-9]+" trivy-table-report.txt 2>/dev/null | \
                        sort -u | \
                        sed 's/^/  📄 /' || true

                    echo ""

                    # ─────────────────────────────────────────
                    # STEP G: REMEDIATION GUIDE
                    # Shows only for issues that still exist
                    # ─────────────────────────────────────────
                    if [ "$TOTAL" -gt 0 ]; then
                        echo "══════════════════════════════════════════════════"
                        echo "    🔧 HOW TO FIX — REMEDIATION GUIDE            "
                        echo "══════════════════════════════════════════════════"
                        echo ""

                        if grep -q "AWS-0029\|sensitive data\|user.data" trivy-table-report.txt 2>/dev/null; then
                            echo "  🔴 FIX CRITICAL: Sensitive data in user_data"
                            echo "     File   : terraform/main.tf"
                            echo "     Problem: Credentials/secrets found in user_data block"
                            echo "     Fix    : Remove all secrets from user_data"
                            echo "              Use IAM roles instead of hardcoded keys"
                            echo ""
                        fi

                        if grep -q "AWS-0104\|egress\|unrestricted egress" trivy-table-report.txt 2>/dev/null; then
                            echo "  🔴 FIX CRITICAL: Unrestricted outbound traffic"
                            echo "     File   : terraform/main.tf"
                            echo "     Problem: egress cidr_blocks = [\"0.0.0.0/0\"]"
                            echo "     Fix    : Restrict egress to specific ports/IPs"
                            echo '             cidr_blocks = ["10.0.0.0/16"]'
                            echo ""
                        fi

                        if grep -q "AWS-0107\|SSH\|unrestricted ingress" trivy-table-report.txt 2>/dev/null; then
                            echo "  🟠 FIX HIGH: SSH open to entire internet"
                            echo "     File   : terraform/main.tf line ~169"
                            echo "     Problem: ingress port 22 cidr_blocks = [\"0.0.0.0/0\"]"
                            echo "     Fix    : Remove SSH ingress rule entirely"
                            echo "              Use AWS Systems Manager Session Manager instead"
                            echo ""
                        fi

                        if grep -q "AWS-0131\|encrypted.*false\|not encrypted" trivy-table-report.txt 2>/dev/null; then
                            echo "  🟠 FIX HIGH: EBS volume not encrypted"
                            echo "     File   : terraform/main.tf line ~231"
                            echo "     Problem: encrypted = false"
                            echo "     Fix    : encrypted = true"
                            echo ""
                        fi

                        if grep -q "AWS-0028\|IMDS\|metadata" trivy-table-report.txt 2>/dev/null; then
                            echo "  🟠 FIX HIGH: IMDSv2 not enforced"
                            echo "     File   : terraform/main.tf (aws_instance block)"
                            echo "     Problem: metadata_options not configured"
                            echo "     Fix    : Add inside aws_instance resource:"
                            echo "              metadata_options {"
                            echo "                http_tokens = \"required\""
                            echo "              }"
                            echo ""
                        fi

                        if grep -q "AWS-0164\|public IP\|map_public_ip" trivy-table-report.txt 2>/dev/null; then
                            echo "  🟠 FIX HIGH: Subnet auto-assigns public IPs"
                            echo "     File   : terraform/main.tf line ~94"
                            echo "     Problem: map_public_ip_on_launch = true"
                            echo "     Fix    : map_public_ip_on_launch = false"
                            echo ""
                        fi

                        if grep -q "AWS-0178\|Flow Logs\|flow logs" trivy-table-report.txt 2>/dev/null; then
                            echo "  🟡 FIX MEDIUM: VPC Flow Logs not enabled"
                            echo "     File   : terraform/main.tf (aws_vpc block)"
                            echo "     Problem: No aws_flow_log resource defined"
                            echo "     Fix    : Add aws_flow_log resource to main.tf"
                            echo ""
                        fi

                        echo "  ──────────────────────────────────────────────"
                        echo "  📌 After fixing, run these commands:"
                        echo "     git add terraform/main.tf"
                        echo "     git commit -m 'Fix: Remediate security vulnerabilities'"
                        echo "     git push origin main"
                        echo "  Then re-run this pipeline to verify count = 0"
                        echo ""
                    fi

                    # ─────────────────────────────────────────
                    # STEP H: FINAL PASS / FAIL DECISION
                    # Based on LIVE count from THIS scan
                    # ─────────────────────────────────────────
                    echo "══════════════════════════════════════════════════"
                    echo "              ⚖️  PIPELINE DECISION               "
                    echo "══════════════════════════════════════════════════"
                    echo ""

                    if [ "$CRITICAL_COUNT" -gt 0 ]; then
                        echo "  ❌ STATUS  : FAILED"
                        echo "  📊 REASON  : $CRITICAL_COUNT CRITICAL issue(s) detected"
                        echo "  🔒 POLICY  : Zero CRITICAL tolerance"
                        echo "  📋 ACTION  : Fix CRITICAL issues listed above"
                        echo ""
                        echo "  ╔══════════════════════════════════════════════╗"
                        echo "  ║  ❌ BUILD FAILED — DO NOT DEPLOY             ║"
                        echo "  ║  $CRITICAL_COUNT CRITICAL + $HIGH_COUNT HIGH + $MEDIUM_COUNT MEDIUM + $LOW_COUNT LOW issues   ║"
                        echo "  ╚══════════════════════════════════════════════╝"
                        exit 1
                    elif [ "$HIGH_COUNT" -gt 0 ]; then
                        echo "  ⚠️  STATUS  : WARNING"
                        echo "  📊 REASON  : $HIGH_COUNT HIGH issue(s) detected (no CRITICAL)"
                        echo "  🔒 POLICY  : HIGH issues should be fixed before production"
                        echo ""
                        echo "  ╔══════════════════════════════════════════════╗"
                        echo "  ║  ⚠️  BUILD PASSED WITH WARNINGS              ║"
                        echo "  ║  Fix HIGH issues before production deploy    ║"
                        echo "  ╚══════════════════════════════════════════════╝"
                    else
                        echo "  ✅ STATUS  : PASSED"
                        echo "  📊 REASON  : Zero CRITICAL issues found"
                        echo "  🔒 POLICY  : Security requirements met"
                        echo ""
                        echo "  ╔══════════════════════════════════════════════╗"
                        echo "  ║  ✅ BUILD PASSED — SAFE TO DEPLOY            ║"
                        echo "  ║  Total remaining: $TOTAL issue(s)           ║"
                        echo "  ╚══════════════════════════════════════════════╝"
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
                    echo '❌ SCAN FAILED — Fix vulnerabilities listed above'
                    echo '🤖 Use AI to analyze and fix terraform/main.tf'
                }
                success {
                    echo '✅ SCAN PASSED!'
                }
            }
        }


        // ═════════════════════════════════════════
        // STAGE 3: TERRAFORM PLAN
        // Only runs if Stage 2 passes
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
                    terraform init -no-color

                    echo ""
                    echo "✅ Running terraform validate..."
                    echo "──────────────────────────────────────────"
                    terraform validate -no-color

                    echo ""
                    echo "📊 Running terraform plan..."
                    echo "──────────────────────────────────────────"
                    terraform plan \
                        -var="aws_region=us-east-1" \
                        -var="environment=demo" \
                        -no-color

                    echo ""
                    echo "✅ Terraform plan complete!"
                '''
            }
        }
    }


    post {
        success {
            echo '''
            ╔══════════════════════════════════════════════════════╗
            ║          ✅ FULL PIPELINE PASSED!                    ║
            ║                                                      ║
            ║   Stage 1: Checkout            ✅                    ║
            ║   Stage 2: Trivy Security Scan ✅  Zero Criticals    ║
            ║   Stage 3: Terraform Plan      ✅                    ║
            ║                                                      ║
            ║   Infrastructure SECURE — Ready to deploy!          ║
            ╚══════════════════════════════════════════════════════╝
            '''
        }
        failure {
            echo '''
            ╔══════════════════════════════════════════════════════╗
            ║          ❌ PIPELINE FAILED                          ║
            ║                                                      ║
            ║   WHAT TO DO NOW:                                    ║
            ║   1. Look at Stage 2 output above                    ║
            ║   2. Find the LIVE count box                         ║
            ║   3. Read exact file + line of each issue            ║
            ║   4. Fix terraform/main.tf in VS Code                ║
            ║   5. git add . && git commit && git push             ║
            ║   6. Re-run → count will update automatically        ║
            ╚══════════════════════════════════════════════════════╝
            '''
        }
        always {
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  Build   : #${env.BUILD_NUMBER}"
            echo "  Job     : ${env.JOB_NAME}"
            echo "  Result  : ${currentBuild.currentResult}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        }
    }
}