// ═══════════════════════════════════════════════════════════
// DEVSECOPS PIPELINE — LIVE VULNERABILITY COUNTER
// Counts REAL vulnerabilities from actual Trivy scan output
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
                    echo "📁 Terraform Files Found:"
                    echo "──────────────────────────────────────────"
                    ls -la terraform/
                    echo ""
                    echo "✅ Checkout complete"
                    echo ""
                '''
            }
        }


        // ═════════════════════════════════════════
        // STAGE 2: TRIVY LIVE SECURITY SCAN
        // ═════════════════════════════════════════
        stage('Stage 2: Trivy IaC Security Scan') {
            steps {
                echo '╔══════════════════════════════════════════╗'
                echo '║      STAGE 2: TRIVY SECURITY SCAN        ║'
                echo '╚══════════════════════════════════════════╝'

                sh '''
                    echo ""
                    echo "🔧 Scanner Details:"
                    echo "──────────────────────────────────────────"
                    trivy --version
                    echo "──────────────────────────────────────────"
                    echo ""

                    echo "══════════════════════════════════════════════════════"
                    echo "        🔍 SCANNING TERRAFORM DIRECTORY...           "
                    echo "══════════════════════════════════════════════════════"
                    echo "  Target    : terraform/"
                    echo "  Scan Type : IaC Misconfiguration Check"
                    echo "  Severities: CRITICAL, HIGH, MEDIUM, LOW"
                    echo "══════════════════════════════════════════════════════"
                    echo ""

                    # ─────────────────────────────────────────────────────
                    # RUN TRIVY — Save output to file AND show in console
                    # Fixed syntax: trivy config then pipe to tee
                    # ─────────────────────────────────────────────────────
                    echo "📋 RAW TRIVY SCAN OUTPUT:"
                    echo "──────────────────────────────────────────────────────"

                    trivy config \
                        --severity CRITICAL,HIGH,MEDIUM,LOW \
                        --format table \
                        terraform/ 2>&1 | tee trivy-table-report.txt

                    echo "──────────────────────────────────────────────────────"
                    echo ""

                    # ─────────────────────────────────────────────────────
                    # RUN TRIVY AGAIN in JSON format for counting
                    # ─────────────────────────────────────────────────────
                    trivy config \
                        --severity CRITICAL,HIGH,MEDIUM,LOW \
                        --format json \
                        terraform/ > trivy-json-report.json 2>/dev/null || true

                    # ─────────────────────────────────────────────────────
                    # LIVE COUNT — Parse actual JSON output from Trivy
                    # Uses python3 (available in Jenkins) to parse JSON
                    # This gives REAL counts from actual scan results
                    # ─────────────────────────────────────────────────────
                    echo "══════════════════════════════════════════════════════"
                    echo "         📊 LIVE VULNERABILITY COUNT                  "
                    echo "══════════════════════════════════════════════════════"

                    python3 - << 'PYEOF'
import json
import sys

try:
    with open('trivy-json-report.json', 'r') as f:
        content = f.read().strip()
        if not content:
            print("  ⚠️  No scan output found")
            sys.exit(0)
        data = json.loads(content)
except Exception as e:
    print(f"  ⚠️  Could not parse report: {e}")
    sys.exit(0)

# Count vulnerabilities by severity
counts = {'CRITICAL': 0, 'HIGH': 0, 'MEDIUM': 0, 'LOW': 0}
vuln_details = []

results = data.get('Results', [])

for result in results:
    misconfigs = result.get('Misconfigurations', [])
    filename = result.get('Target', 'unknown')

    for m in misconfigs:
        severity = m.get('Severity', 'UNKNOWN').upper()
        if severity in counts:
            counts[severity] += 1

        vuln_details.append({
            'severity': severity,
            'id':       m.get('ID', 'N/A'),
            'title':    m.get('Title', 'N/A'),
            'desc':     m.get('Description', 'N/A'),
            'file':     filename,
            'resource': m.get('CauseMetadata', {}).get('Resource', 'N/A'),
            'startline': m.get('CauseMetadata', {}).get('StartLine', 'N/A'),
            'endline':   m.get('CauseMetadata', {}).get('EndLine', 'N/A'),
            'resolution': m.get('Resolution', 'N/A'),
        })

total = sum(counts.values())

# ── SUMMARY BOX ──────────────────────────────────────
print("")
print("  ┌──────────────────────────────────────────────┐")
print(f"  │   TOTAL VULNERABILITIES FOUND  :  {total:<10}  │")
print("  ├──────────────────────────────────────────────┤")

icon = {'CRITICAL': '🔴', 'HIGH': '🟠', 'MEDIUM': '🟡', 'LOW': '🔵'}
for sev in ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW']:
    c = counts[sev]
    bar = '█' * c if c > 0 else '░ none'
    print(f"  │  {icon[sev]} {sev:<8} : {c}  {bar:<20}  │")

print("  └──────────────────────────────────────────────┘")
print("")

if total == 0:
    print("  ✅ ZERO vulnerabilities found!")
    print("  🟢 Infrastructure is SECURE")
    sys.exit(0)

# ── DETAILED BREAKDOWN ───────────────────────────────
print("══════════════════════════════════════════════════════")
print("       📁 DETAILED VULNERABILITY BREAKDOWN            ")
print("══════════════════════════════════════════════════════")

sev_order = ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW']
num = 1

for sev in sev_order:
    sev_vulns = [v for v in vuln_details if v['severity'] == sev]
    if not sev_vulns:
        continue

    ico = icon[sev]
    print(f"\n  {ico} {sev} VULNERABILITIES ({len(sev_vulns)} found)")
    print("  " + "─" * 60)

    for v in sev_vulns:
        print(f"\n  [{num}] {ico} {v['severity']} — {v['id']}")
        print(f"  ┌─────────────────────────────────────────────────────")
        print(f"  │  Title     : {v['title']}")
        print(f"  │  File      : {v['file']}")
        print(f"  │  Resource  : {v['resource']}")
        print(f"  │  Lines     : {v['startline']} → {v['endline']}")
        print(f"  │  Problem   : {v['desc'][:80]}")
        print(f"  │  Fix       : {v['resolution'][:80]}")
        print(f"  └─────────────────────────────────────────────────────")
        num += 1

# ── REMEDIATION STEPS ────────────────────────────────
print("")
print("══════════════════════════════════════════════════════")
print("              🔧 REMEDIATION STEPS                    ")
print("══════════════════════════════════════════════════════")
print("")
print("  Follow these steps to fix vulnerabilities:")
print("")

step = 1
for sev in sev_order:
    sev_vulns = [v for v in vuln_details if v['severity'] == sev]
    for v in sev_vulns:
        print(f"  STEP {step}: Fix {v['severity']} — {v['id']}")
        print(f"    File    : {v['file']}")
        print(f"    Lines   : {v['startline']} to {v['endline']}")
        print(f"    Action  : {v['resolution'][:70]}")
        print("")
        step += 1

print("  After fixing:")
print("  1. git add terraform/main.tf")
print("  2. git commit -m 'Fix: Remediate security vulnerabilities'")
print("  3. git push origin main")
print("  4. Re-run this Jenkins pipeline")
print("  5. Confirm TOTAL = 0")
print("")

# ── SAVE COUNTS FOR SHELL ────────────────────────────
with open('vuln_counts.txt', 'w') as f:
    for sev, c in counts.items():
        f.write(f"{sev}={c}\\n")

PYEOF

                    # ─────────────────────────────────────────────────────
                    # READ COUNTS and make PASS/FAIL decision
                    # ─────────────────────────────────────────────────────
                    echo "══════════════════════════════════════════════════════"
                    echo "              ⚖️  PIPELINE DECISION                   "
                    echo "══════════════════════════════════════════════════════"

                    # Read critical count from file written by python
                    if [ -f vuln_counts.txt ]; then
                        CRITICAL_COUNT=$(grep "^CRITICAL=" vuln_counts.txt | cut -d= -f2 | tr -d '[:space:]')
                        HIGH_COUNT=$(grep "^HIGH=" vuln_counts.txt | cut -d= -f2 | tr -d '[:space:]')
                        MEDIUM_COUNT=$(grep "^MEDIUM=" vuln_counts.txt | cut -d= -f2 | tr -d '[:space:]')
                        LOW_COUNT=$(grep "^LOW=" vuln_counts.txt | cut -d= -f2 | tr -d '[:space:]')
                    else
                        CRITICAL_COUNT=0
                        HIGH_COUNT=0
                        MEDIUM_COUNT=0
                        LOW_COUNT=0
                    fi

                    echo ""
                    echo "  Live Count at Decision Point:"
                    echo "  🔴 CRITICAL : ${CRITICAL_COUNT}"
                    echo "  🟠 HIGH     : ${HIGH_COUNT}"
                    echo "  🟡 MEDIUM   : ${MEDIUM_COUNT}"
                    echo "  🔵 LOW      : ${LOW_COUNT}"
                    echo ""

                    if [ "${CRITICAL_COUNT}" -gt "0" ] 2>/dev/null; then
                        echo "  ╔══════════════════════════════════════════════════╗"
                        echo "  ║  ❌ BUILD FAILED                                 ║"
                        echo "  ║  Reason : ${CRITICAL_COUNT} CRITICAL issue(s) detected    ║"
                        echo "  ║  Policy : Zero CRITICAL tolerance enforced       ║"
                        echo "  ║  Action : Fix issues shown above, then re-push   ║"
                        echo "  ╚══════════════════════════════════════════════════╝"
                        exit 1
                    else
                        echo "  ╔══════════════════════════════════════════════════╗"
                        echo "  ║  ✅ SCAN PASSED                                  ║"
                        echo "  ║  Result : Zero CRITICAL vulnerabilities found    ║"
                        echo "  ║  Status : Safe to proceed to Terraform Plan      ║"
                        echo "  ╚══════════════════════════════════════════════════╝"
                    fi
                '''
            }

            post {
                always {
                    sh 'ls -la trivy-*.txt trivy-*.json vuln_counts.txt 2>/dev/null || true'
                    archiveArtifacts artifacts: 'trivy-table-report.txt',
                                     allowEmptyArchive: true
                    archiveArtifacts artifacts: 'trivy-json-report.json',
                                     allowEmptyArchive: true
                }
                failure {
                    echo '❌ SCAN FAILED — Fix vulnerabilities listed above'
                    echo '📋 Use AI to analyze and remediate terraform/main.tf'
                }
                success {
                    echo '✅ SCAN PASSED — Zero CRITICAL vulnerabilities!'
                }
            }
        }


        // ═════════════════════════════════════════
        // STAGE 3: TERRAFORM PLAN
        // Only runs if Trivy scan passes
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
                    echo "──────────────────────────────────────────"
                    echo "  Run terraform apply to deploy to AWS"
                '''
            }

            post {
                success {
                    echo '✅ Terraform plan successful!'
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
            ╔══════════════════════════════════════════════════════╗
            ║          ✅ FULL PIPELINE PASSED!                    ║
            ║                                                      ║
            ║   Stage 1: Checkout            ✅                    ║
            ║   Stage 2: Trivy Security Scan ✅  Zero Criticals    ║
            ║   Stage 3: Terraform Plan      ✅                    ║
            ║                                                      ║
            ║   Infrastructure is SECURE and READY TO DEPLOY!     ║
            ╚══════════════════════════════════════════════════════╝
            '''
        }
        failure {
            echo '''
            ╔══════════════════════════════════════════════════════╗
            ║          ❌ PIPELINE FAILED                          ║
            ║                                                      ║
            ║   NEXT STEPS:                                        ║
            ║   1. Read vulnerability details in Stage 2 above     ║
            ║   2. Note exact file + line numbers shown            ║
            ║   3. Use AI to fix terraform/main.tf                 ║
            ║   4. git add . && git commit && git push             ║
            ║   5. Re-run pipeline                                 ║
            ║   6. Verify TOTAL count = 0                          ║
            ╚══════════════════════════════════════════════════════╝
            '''
        }
        always {
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "  Build Number : ${env.BUILD_NUMBER}"
            echo "  Job Name     : ${env.JOB_NAME}"
            echo "  Result       : ${currentBuild.currentResult}"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        }
    }
}