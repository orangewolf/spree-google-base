#!/usr/bin/env groovy

node {
    try {
        stage('Checkout') {
            checkout scm
        }
        stage('Build') {
            sh '''#!/bin/bash -l
                set -e
                cd .
                rvm use 2.2.5
                gem install bundler --no-document
                bundle install --deployment
            '''
        }
        stage('Test') {
            sh '''#!/bin/bash -l
                set -e
                cd .
                rvm use 2.2.5
                bundle exec rake test_app
                bundle exec rspec
            '''
        }
        stage('Cleanup') {
            echo 'Cleaning workspace (if successful)'
            step([$class: 'WsCleanup', deleteDirs: true, patterns: [[pattern: '.git/**', type: 'EXCLUDE']]])
        }
    } catch (e) {
        currentBuild.result = "FAILED"
        throw e
    } finally {
        def buildStatus = currentBuild.result ? currentBuild.result : 'SUCCESSFUL'
        def subject = "${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]'"
        def details = "${env.JOB_NAME} - Build # ${env.BUILD_NUMBER} - ${buildStatus}:\n" +
                "\n" +
                "Check console output at $BUILD_URL to view the results."
        emailext recipientProviders: [[$class: 'DevelopersRecipientProvider']],
                subject: subject,
                body: details
    }
}
