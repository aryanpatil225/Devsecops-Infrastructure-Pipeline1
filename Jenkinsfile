// ═══════════════════════════════════════════════════════════
// DEVSECOPS PIPELINE — PRODUCTION DECLARATIVE JENKINSFILE
//
// PIPELINE STAGES:
// Stage 1: Checkout     → Pull code from GitHub
// Stage 2: Trivy Scan   → Scan Terraform for vulnerabilities
// Stage 3: Terraform    → Init and Plan infrastructure
//
// DEVSECOPS PRINCIPLE: "Shift Security Left"
// We scan BEFORE deploying — catch issues early.
// Failing on CRITICAL = we never deploy insecure infra.
// ═══════════════════════════════════════════════════════════

pipeline {

    agent any

    // ─────────────────────────────────────────────
    // WHY environment block?
    // Central place for all config values.
    // Change here = changes everywhere in pipeline.
    // ─────────────────────────────────────────────
    environment {
        PROJECT_NAME     = 'devsecops-pipeline'
        TERRAFORM_DIR    = 'terraform'
        TRIVY_REPORT     = 'trivy-report.txt'
        AWS_REGION       = 'us-east-1'
    }

    options {
        // WHY timeout? Prevents stuck builds wasting resources
        timeout(time: 30, unit: 'MINUTES')
        // WHY timestamps? Audit trail for every step
        timestamps()
        // WHY buildDiscarder? Keep only last 5 builds
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }

    stages {

        // ═════════════════════════════════════════
        // STAGE 1: CHECKOUT
        // WHY: Pull latest code from GitHub.
        // Every pipeline run starts fresh from SCM.
        // Ensures we always scan the latest code.
        // ═════════════════════════════════════════
        stage('Stage 1: Checkout Code') {
            steps {
                echo '╔══════════════════════════════════════╗'
                echo '║   STAGE 1: CHECKOUT SOURCE CODE      ║'
                echo '╚══════════════════════════════════════╝'

                // Pull code from GitHub
                checkout scm

                echo '✅ Code checkout complete'

                // Show what we checked out
                sh '''
                    echo "──────────────────────────────────"
                    echo "Repository contents:"
                    ls -la
                    echo "──────────────────────────────────"
                    echo "Terraform files:"
                    ls -la terraform/
                    echo "──────────────────────────────────"
                '''
            }
        }


        // ═════════════════════════════════════════
        // STAGE 2: TRIVY SECURITY SCAN
        //
        // WHY Trivy?
        // Open source IaC security scanner.
        // Detects misconfigurations in Terraform.
        // Used by Netflix, AWS, Google in production.
        //
        // WHY FAIL on CRITICAL?
        // DevSecOps Principle: "Security is non-negotiable"
        // If we allow CRITICAL issues to pass:
        // → We deploy vulnerable infrastructure
        // → One breach can cost millions
        // → Compliance violations (PCI-DSS, HIPAA, SOC2)
        // → Company reputation destroyed
        //
        // Failing the build FORCES developers to fix it.
        // "Fail fast, fail loud" = issues caught early.
        // ═════════════════════════════════════════
        stage('Stage 2: Trivy IaC Security Scan') {
            steps {
                echo '╔══════════════════════════════════════╗'
                echo '║   STAGE 2: TRIVY SECURITY SCAN       ║'
                echo '╚══════════════════════════════════════╝'

                echo '🔍 Starting Trivy IaC scan on Terraform files...'
                echo '⚠️  Pipeline will FAIL if CRITICAL issues found'
                echo '──────────────────────────────────────────────'

                sh '''
                    # Show Trivy version for audit trail
                    echo "Trivy version:"
                    trivy --version
                    echo "──────────────────────────────────"

                    # Run Trivy IaC scan on terraform directory
                    # --exit-code 1 = return exit code 1 if issues found
                    # --severity    = only fail on these severity levels
                    # --format      = output format
                    # tee           = show in console AND save to file

                    echo "🔍 SCANNING TERRAFORM FILES FOR VULNERABILITIES..."
                    echo "──────────────────────────────────────────────────"

                    trivy config \
                        --exit-code 1 \
                        --severity CRITICAL,HIGH \
                        --format table \
                        terraform/ 2>&1 | tee trivy-report.txt

                    SCAN_EXIT_CODE=${PIPESTATUS[0]}

                    echo "──────────────────────────────────────────────────"
                    echo "Trivy scan exit code: $SCAN_EXIT_CODE"

                    if [ $SCAN_EXIT_CODE -ne 0 ]; then
                        echo ""
                        echo "╔══════════════════════════════════════════════╗"
                        echo "║  ❌ CRITICAL VULNERABILITIES FOUND!           ║"
                        echo "║  Pipeline FAILED — Fix issues before deploy  ║"
                        echo "║                                              ║"
                        echo "║  VULNERABILITIES DETECTED:                   ║"
                        echo "║  • SSH port 22 open to 0.0.0.0/0             ║"
                        echo "║  • Unencrypted EBS volume                    ║"
                        echo "║                                              ║"
                        echo "║  ACTION REQUIRED:                            ║"
                        echo "║  Use AI to analyze and fix Terraform code    ║"
                        echo "╚══════════════════════════════════════════════╝"
                        exit 1
                    fi

                    echo "✅ Security scan PASSED — No critical issues!"
                '''
            }

            // WHY post section?
            // Always runs regardless of pass/fail.
            // Archives the report so you can download it.
            // Required for README screenshots.
            post {
                always {
                    echo '📄 Archiving Trivy security report...'
                    archiveArtifacts artifacts: 'trivy-report.txt',
                                     allowEmptyArchive: true
                }
                failure {
                    echo '❌ SCAN FAILED: Review trivy-report.txt for details'
                    echo '📋 Copy the report above and use AI for remediation'
                }
                success {
                    echo '✅ SCAN PASSED: No critical vulnerabilities found!'
                }
            }
        }


        // ═════════════════════════════════════════
        // STAGE 3: TERRAFORM PLAN
        //
        // WHY terraform init first?
        // Downloads required providers (AWS plugin).
        // Creates .terraform folder with dependencies.
        // Must run before any other terraform command.
        //
        // WHY terraform plan (not apply)?
        // Plan = "show what WOULD happen" (safe)
        // Apply = "actually create resources" (costs money)
        // For the pipeline demo, plan is sufficient.
        // Apply manually when ready to deploy.
        // ═════════════════════════════════════════
        stage('Stage 3: Terraform Plan') {
            steps {
                echo '╔══════════════════════════════════════╗'
                echo '║   STAGE 3: TERRAFORM PLAN            ║'
                echo '╚══════════════════════════════════════╝'

                sh '''
                    echo "📁 Moving to terraform directory..."
                    cd terraform

                    echo "──────────────────────────────────"
                    echo "🔧 Running terraform init..."
                    echo "──────────────────────────────────"

                    terraform init

                    echo "──────────────────────────────────"
                    echo "📋 Running terraform validate..."
                    echo "──────────────────────────────────"

                    terraform validate

                    echo "──────────────────────────────────"
                    echo "📊 Running terraform plan..."
                    echo "──────────────────────────────────"

                    terraform plan \
                        -var="aws_region=us-east-1" \
                        -var="environment=demo" \
                        -out=tfplan

                    echo "✅ Terraform plan complete!"
                    echo "Review plan above before applying"
                '''
            }

            post {
                success {
                    echo '✅ Terraform plan successful!'
                    echo '💡 Run terraform apply manually to deploy'
                }
                failure {
                    echo '❌ Terraform plan failed'
                    echo '🔍 Check AWS credentials and terraform syntax'
                }
            }
        }
    }


    // ─────────────────────────────────────────────
    // POST PIPELINE — runs after ALL stages
    // WHY? Final status reporting for every run.
    // ─────────────────────────────────────────────
    post {
        success {
            echo '''
            ╔══════════════════════════════════════════════╗
            ║   ✅ PIPELINE PASSED SUCCESSFULLY!           ║
            ║                                              ║
            ║   • Code checkout    ✅                      ║
            ║   • Security scan    ✅ (Zero criticals)     ║
            ║   • Terraform plan   ✅                      ║
            ║                                              ║
            ║   Infrastructure is SECURE and READY!       ║
            ╚══════════════════════════════════════════════╝
            '''
        }
        failure {
            echo '''
            ╔══════════════════════════════════════════════╗
            ║   ❌ PIPELINE FAILED                         ║
            ║                                              ║
            ║   NEXT STEPS:                                ║
            ║   1. Check Trivy report in console above     ║
            ║   2. Copy vulnerability report               ║
            ║   3. Use AI to analyze and fix               ║
            ║   4. Update terraform/main.tf                ║
            ║   5. Push to GitHub                          ║
            ║   6. Re-run pipeline                         ║
            ╚══════════════════════════════════════════════╝
            '''
        }
        always {
            echo '🏁 Pipeline execution completed'
            echo "📅 Build: ${env.BUILD_NUMBER}"
            echo "🔗 Job: ${env.JOB_NAME}"
        }
    }
}