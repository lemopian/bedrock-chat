
# Function to log messages with timestamps
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
}

# Function to log errors and exit
log_error_and_exit() {
    local message="$1"
    local error_output="$2"
    log_message "ERROR" "$message"
    if [[ -n "$error_output" ]]; then
        echo "Error details:"
        echo "$error_output"
    fi
    exit 1
}

echo ""
echo "==========================================================================="
echo "  ⚠️  Heads Up: A Brand-New Era Begins with v3.x!                              "
echo "---------------------------------------------------------------------------"
echo "  🚨 v3.x is NOT compatible with v2.x or any earlier versions.              "
echo "     Carefully read the migration guide before proceeding:                 "
echo "     https://github.com/aws-samples/bedrock-chat/blob/v3/docs/migration/V2_TO_V3.md"
echo ""
echo "  ❗ This upgrade is significant. To prevent DATA LOSS (especially custom bots),"
echo "     follow the steps outlined in the guide step-by-step.                 "
echo ""
echo "  ✅ This script is safe ONLY IF you're:                                    "
echo "     - A new user starting with v3.x                                       "
echo "     - Or already upgraded to v3.x                                         "
echo ""
echo "  📌 Otherwise, STOP now and read the migration guide above first!         "
echo "---------------------------------------------------------------------------"
echo "  🌟 Let's begin your v3.x journey — the future awaits!                    "
echo "==========================================================================="
echo ""

# Load environment variables from .env file if it exists
if [[ -f .env ]]; then
    log_message "INFO" "Loading environment variables from .env file..."
    export $(cat .env | xargs)
    log_message "SUCCESS" "Environment variables loaded from .env file"
else
    log_message "WARNING" ".env file not found - using system environment variables"
fi

# while true; do
#     read -p "Are you ready to explore the world of v3.x? (y/N): " answer
#     case ${answer:0:1} in
#         y|Y )
#             log_message "INFO" "User confirmed. Starting deployment for v3.x..."
#             break
#             ;;
#         n|N )
#             log_message "INFO" "User declined. Exiting deployment."
#             echo "Whoa, hold on! This script is only for v3.x users. Please refer to the migration guide if you're coming from an older version."
#             exit 1
#             ;;
#         * )
#             echo "Let's keep it simple. Please enter y or n."
#             ;;
#     esac
# done

# Default parameters
ALLOW_SELF_REGISTER="true"
ENABLE_LAMBDA_SNAPSTART="false"
IPV4_RANGES=""
IPV6_RANGES=""
DISABLE_IPV6="false"
ALLOWED_SIGN_UP_EMAIL_DOMAINS=""
BEDROCK_REGION="us-east-1"
CDK_JSON_OVERRIDE="{}"
REPO_URL="https://github.com/aws-samples/bedrock-chat.git"
VERSION="v3"

log_message "INFO" "Parsing command-line arguments..."

# Parse command-line arguments for customization
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --disable-self-register) 
            ALLOW_SELF_REGISTER="false"
            log_message "INFO" "Self-registration disabled"
            ;;
        --enable-lambda-snapstart) 
            ENABLE_LAMBDA_SNAPSTART="true"
            log_message "INFO" "Lambda SnapStart enabled"
            ;;
        --disable-ipv6) 
            DISABLE_IPV6="true"
            log_message "INFO" "IPv6 disabled"
            ;;
        --ipv4-ranges) 
            IPV4_RANGES="$2"
            log_message "INFO" "IPv4 ranges set to: $IPV4_RANGES"
            shift 
            ;;
        --ipv6-ranges) 
            IPV6_RANGES="$2"
            log_message "INFO" "IPv6 ranges set to: $IPV6_RANGES"
            shift 
            ;;
        --bedrock-region) 
            BEDROCK_REGION="$2"
            log_message "INFO" "Bedrock region set to: $BEDROCK_REGION"
            shift 
            ;;
        --allowed-signup-email-domains) 
            ALLOWED_SIGN_UP_EMAIL_DOMAINS="$2"
            log_message "INFO" "Allowed signup email domains set to: $ALLOWED_SIGN_UP_EMAIL_DOMAINS"
            shift 
            ;;
        --cdk-json-override) 
            CDK_JSON_OVERRIDE="$2"
            log_message "INFO" "CDK JSON override provided"
            shift 
            ;;
        --repo-url) 
            REPO_URL="$2"
            log_message "INFO" "Repository URL set to: $REPO_URL"
            shift 
            ;;
        --version) 
            VERSION="$2"
            log_message "INFO" "Version set to: $VERSION"
            shift 
            ;;
        *) 
            log_error_and_exit "Unknown parameter: $1" ""
            ;;
    esac
    shift
done

log_message "INFO" "Configuration summary:"
log_message "INFO" "  - Allow Self Register: $ALLOW_SELF_REGISTER"
log_message "INFO" "  - Enable Lambda SnapStart: $ENABLE_LAMBDA_SNAPSTART"
log_message "INFO" "  - Disable IPv6: $DISABLE_IPV6"
log_message "INFO" "  - IPv4 Ranges: ${IPV4_RANGES:-'(none)'}"
log_message "INFO" "  - IPv6 Ranges: ${IPV6_RANGES:-'(none)'}"
log_message "INFO" "  - Bedrock Region: $BEDROCK_REGION"
log_message "INFO" "  - Allowed Signup Email Domains: ${ALLOWED_SIGN_UP_EMAIL_DOMAINS:-'(none)'}"
log_message "INFO" "  - Repository URL: $REPO_URL"
log_message "INFO" "  - Version: $VERSION"

# Validate the template
log_message "INFO" "Validating CloudFormation template..."
validate_output=$(aws cloudformation validate-template --template-body file://deploy.yml 2>&1)
if [[ $? -ne 0 ]]; then
    log_error_and_exit "CloudFormation template validation failed" "$validate_output"
fi
log_message "SUCCESS" "CloudFormation template validation passed"

StackName="CodeBuildForDeploy"

# Deploy the CloudFormation stack
log_message "INFO" "Deploying CloudFormation stack: $StackName"
log_message "INFO" "This may take several minutes..."

deploy_output=$(aws cloudformation deploy \
  --stack-name $StackName \
  --template-file deploy.yml \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    AllowSelfRegister=$ALLOW_SELF_REGISTER \
    EnableLambdaSnapStart=$ENABLE_LAMBDA_SNAPSTART \
    DisableIpv6=$DISABLE_IPV6 \
    Ipv4Ranges="$IPV4_RANGES" \
    Ipv6Ranges="$IPV6_RANGES" \
    AllowedSignUpEmailDomains="$ALLOWED_SIGN_UP_EMAIL_DOMAINS" \
    BedrockRegion="$BEDROCK_REGION" \
    CdkJsonOverride="$CDK_JSON_OVERRIDE" \
    RepoUrl="$REPO_URL" \
    Version="$VERSION" 2>&1)

if [[ $? -ne 0 ]]; then
    log_error_and_exit "CloudFormation stack deployment failed" "$deploy_output"
fi

log_message "SUCCESS" "CloudFormation stack deployment initiated successfully"
echo "Deploy output:"
echo "$deploy_output"

log_message "INFO" "Waiting for the stack creation to complete..."
log_message "INFO" "NOTE: this stack contains CodeBuild project which will be used for CDK deploy."

spin='-\|/'
i=0
start_time=$(date +%s)

while true; do
    status=$(aws cloudformation describe-stacks --stack-name $StackName --query 'Stacks[0].StackStatus' --output text 2>/dev/null)
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    
    if [[ "$status" == "CREATE_COMPLETE" || "$status" == "UPDATE_COMPLETE" ]]; then
        log_message "SUCCESS" "Stack operation completed successfully in ${elapsed}s with status: $status"
        break
    elif [[ "$status" == "DELETE_COMPLETE" ]]; then
        log_message "INFO" "Stack was deleted successfully"
        break
    elif [[ "$status" == "ROLLBACK_COMPLETE" || "$status" == "DELETE_FAILED" || "$status" == "CREATE_FAILED" || "$status" == "UPDATE_FAILED" || "$status" == "ROLLBACK_FAILED" ]]; then
        log_message "ERROR" "Stack operation failed with status: $status after ${elapsed}s"
        
        # Get stack events to show detailed error information
        log_message "INFO" "Fetching stack events for error details..."
        stack_events=$(aws cloudformation describe-stack-events --stack-name $StackName --query 'StackEvents[?ResourceStatus==`CREATE_FAILED` || ResourceStatus==`UPDATE_FAILED`].{Time:Timestamp,Resource:LogicalResourceId,Status:ResourceStatus,Reason:ResourceStatusReason}' --output table 2>&1)
        if [[ $? -eq 0 ]]; then
            echo "Failed stack events:"
            echo "$stack_events"
        else
            log_message "WARNING" "Could not fetch stack events: $stack_events"
        fi
        exit 1
    fi
    
    # Show progress every 30 seconds
    if [[ $((elapsed % 30)) -eq 0 && $elapsed -gt 0 ]]; then
        log_message "INFO" "Still waiting for stack operation... Current status: $status (${elapsed}s elapsed)"
    fi
    
    printf "\r[$(date '+%H:%M:%S')] Waiting for stack... ${spin:i++%${#spin}:1} (${elapsed}s) Status: $status"
    sleep 1
done
echo ""

log_message "INFO" "Retrieving stack outputs..."
outputs=$(aws cloudformation describe-stacks --stack-name $StackName --query 'Stacks[0].Outputs' 2>&1)
if [[ $? -ne 0 ]]; then
    log_error_and_exit "Failed to retrieve stack outputs" "$outputs"
fi

log_message "INFO" "Stack outputs retrieved successfully"
echo "Stack outputs:"
echo "$outputs" | jq '.'

projectName=$(echo $outputs | jq -r '.[] | select(.OutputKey=="ProjectName").OutputValue')

if [[ -z "$projectName" || "$projectName" == "null" ]]; then
    log_error_and_exit "Failed to retrieve the CodeBuild project name from stack outputs" "$outputs"
fi

log_message "INFO" "CodeBuild project name: $projectName"
log_message "INFO" "Starting CodeBuild project..."

buildId=$(aws codebuild start-build --project-name $projectName --query 'build.id' --output text 2>&1)
if [[ $? -ne 0 || -z "$buildId" ]]; then
    log_error_and_exit "Failed to start CodeBuild project" "$buildId"
fi

log_message "SUCCESS" "CodeBuild project started successfully. Build ID: $buildId"
log_message "INFO" "Waiting for the CodeBuild project to complete..."

build_start_time=$(date +%s)
last_status=""

while true; do
    build_info=$(aws codebuild batch-get-builds --ids $buildId --query 'builds[0].{status:buildStatus,phase:currentPhase}' --output json 2>&1)
    if [[ $? -ne 0 ]]; then
        log_message "WARNING" "Failed to get build status: $build_info"
        sleep 10
        continue
    fi
    
    buildStatus=$(echo "$build_info" | jq -r '.status')
    currentPhase=$(echo "$build_info" | jq -r '.phase')
    
    # Log status changes
    if [[ "$buildStatus:$currentPhase" != "$last_status" ]]; then
        current_time=$(date +%s)
        elapsed=$((current_time - build_start_time))
        log_message "INFO" "Build status: $buildStatus, Phase: $currentPhase (${elapsed}s elapsed)"
        last_status="$buildStatus:$currentPhase"
    fi
    
    if [[ "$buildStatus" == "SUCCEEDED" ]]; then
        current_time=$(date +%s)
        elapsed=$((current_time - build_start_time))
        log_message "SUCCESS" "CodeBuild project completed successfully in ${elapsed}s"
        break
    elif [[ "$buildStatus" == "FAILED" || "$buildStatus" == "STOPPED" || "$buildStatus" == "FAULT" || "$buildStatus" == "TIMED_OUT" ]]; then
        current_time=$(date +%s)
        elapsed=$((current_time - build_start_time))
        log_message "ERROR" "CodeBuild project failed with status: $buildStatus after ${elapsed}s"
        
        # Get detailed build information for debugging
        detailed_build=$(aws codebuild batch-get-builds --ids $buildId --query 'builds[0]' --output json 2>&1)
        if [[ $? -eq 0 ]]; then
            echo "Detailed build information:"
            echo "$detailed_build" | jq '{
                buildStatus: .buildStatus,
                statusDetail: .buildStatusDetail,
                phases: .phases,
                artifacts: .artifacts,
                environment: .environment
            }'
        fi
        break
    fi
    sleep 10
done

log_message "INFO" "Retrieving build details and logs..."
buildDetail=$(aws codebuild batch-get-builds --ids $buildId --query 'builds[0].logs.{groupName: groupName, streamName: streamName}' --output json 2>&1)
if [[ $? -ne 0 ]]; then
    log_error_and_exit "Failed to get build details" "$buildDetail"
fi

logGroupName=$(echo $buildDetail | jq -r '.groupName')
logStreamName=$(echo $buildDetail | jq -r '.streamName')

log_message "INFO" "Build Log Group Name: $logGroupName"
log_message "INFO" "Build Log Stream Name: $logStreamName"

if [[ "$logGroupName" != "null" && "$logStreamName" != "null" ]]; then
    log_message "INFO" "Fetching complete CDK deployment logs..."
    logs=$(aws logs get-log-events --log-group-name "$logGroupName" --log-stream-name "$logStreamName" --output json 2>&1)
    if [[ $? -ne 0 ]]; then
        log_message "ERROR" "Failed to fetch CDK deployment logs: $logs"
    else
        log_message "SUCCESS" "CDK deployment logs retrieved successfully"
        echo ""
        echo "==================== BUILD LOGS ===================="
        echo "$logs" | jq -r '.events[].message'
        echo "===================================================="
        echo ""
        
        # Extract frontend URL from logs
        frontendUrl=$(echo "$logs" | jq -r '.events[].message' | grep -o 'FrontendURL = [^ ]*' | cut -d' ' -f3 | tr -d '\n,')
        
        if [[ -n "$frontendUrl" && "$frontendUrl" != "null" ]]; then
            log_message "SUCCESS" "Deployment completed successfully!"
            log_message "SUCCESS" "Frontend URL: $frontendUrl"
            echo ""
            echo "🎉 Deployment Summary:"
            echo "   - Frontend URL: $frontendUrl"
            echo "   - Build ID: $buildId"
            echo "   - Logs: CloudWatch Logs Group '$logGroupName', Stream '$logStreamName'"
        else
            log_message "WARNING" "Deployment may have completed, but Frontend URL was not found in logs"
            echo "Please check the CloudWatch logs manually:"
            echo "   - Log Group: $logGroupName"
            echo "   - Log Stream: $logStreamName"
        fi
    fi
else
    log_message "WARNING" "Build logs information is not available"
    echo "Please check the CodeBuild console for build logs."
fi

# Final status check
if [[ "$buildStatus" == "SUCCEEDED" ]]; then
    log_message "SUCCESS" "🎉 Deployment completed successfully!"
    exit 0
else
    log_message "ERROR" "❌ Deployment failed. Please review the logs above for details."
    exit 1
fi
