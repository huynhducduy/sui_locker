#!/bin/bash

# SuiLocker Contracts Deployment Script
# Usage: ./scripts/deploy.sh [network] [gas-budget]
# Example: ./scripts/deploy.sh testnet 20000000

set -e # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
NETWORK=${1:-testnet}
GAS_BUDGET=${2:-200000000}

echo -e "${BLUE}🚀 SuiLocker Contracts Deployment Script${NC}"
echo -e "${BLUE}==========================================${NC}"

# Function to print colored output
print_status() {
	echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
	echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
	echo -e "${RED}❌ $1${NC}"
}

print_info() {
	echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if sui CLI is installed
if ! command -v sui &>/dev/null; then
	print_error "Sui CLI is not installed. Please install it first."
	echo "Install with: cargo install --locked --git https://github.com/MystenLabs/sui.git --branch mainnet sui"
	exit 1
fi

print_status "Sui CLI found: $(sui --version)"

# Validate network parameter
case $NETWORK in
mainnet | testnet | devnet | local)
	print_info "Deploying to network: $NETWORK"
	;;
*)
	print_error "Invalid network: $NETWORK. Use: mainnet, testnet, devnet, or local"
	exit 1
	;;
esac

# Check if we're in the right directory
if [[ ! -f "Move.toml" ]]; then
	print_error "Move.toml not found. Please run this script from the project root directory."
	exit 1
fi

# Switch to the specified network
print_info "Switching to $NETWORK network..."
if ! sui client switch --env "$NETWORK"; then
	print_warning "Network $NETWORK not configured. Setting it up..."

	case $NETWORK in
	mainnet)
		sui client new-env --alias mainnet --rpc https://fullnode.mainnet.sui.io:443
		;;
	testnet)
		sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443
		;;
	devnet)
		sui client new-env --alias devnet --rpc https://fullnode.devnet.sui.io:443
		;;
	local)
		sui client new-env --alias local --rpc http://127.0.0.1:9000
		;;
	esac

	sui client switch --env "$NETWORK"
fi

print_status "Active network: $(sui client active-env)"

# Check wallet
ACTIVE_ADDRESS=$(sui client active-address)
print_info "Active address: $ACTIVE_ADDRESS"

# Build the contracts
print_info "Building contracts..."
if sui move build; then
	print_status "Build successful"
else
	print_error "Build failed. Please check your code."
	exit 1
fi

# Run tests
print_info "Running tests..."
if sui move test; then
	print_status "All tests passed"
else
	print_error "Tests failed. Please fix issues before deploying."
	exit 1
fi

# Create deployment timestamp
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Deploy the contracts
print_info "Deploying contracts with gas budget: $GAS_BUDGET"
print_info "This may take a few moments..."

DEPLOY_OUTPUT=$(sui client publish --gas-budget "$GAS_BUDGET" 2>&1)
DEPLOY_EXIT_CODE=$?

if [[ $DEPLOY_EXIT_CODE -eq 0 ]]; then
	print_status "Deployment successful!"

	echo "$DEPLOY_OUTPUT"

	# Extract important information from deployment output
	TRANSACTION_DIGEST=$(echo "$DEPLOY_OUTPUT" | grep -o "Transaction Digest: [A-Za-z0-9]*" | cut -d' ' -f3)
	PACKAGE_ID=$(echo "$DEPLOY_OUTPUT" | grep -A5 "Published Objects" | grep "PackageID: [A-Za-z0-9]*" | cut -d' ' -f5)
	GLOBAL_STATE=$(echo "$DEPLOY_OUTPUT" | grep -B5 "GlobalState" | grep "ObjectID: [A-Za-z0-9]*" | cut -d' ' -f5)

	# Create deployment info file
	DEPLOYMENT_FILE="deployment-$NETWORK-$(date +%Y%m%d-%H%M%S).json"

	cat >"$DEPLOYMENT_FILE" <<EOF
{
  "network": "$NETWORK",
  "package_id": "$PACKAGE_ID",
  "global_registry_tracker_id": "$GLOBAL_STATE",
  "transaction_digest": "$TRANSACTION_DIGEST",
  "deployed_at": "$TIMESTAMP",
  "deployer": "$ACTIVE_ADDRESS",
  "gas_budget": $GAS_BUDGET
}
EOF

	print_status "Deployment information saved to: $DEPLOYMENT_FILE"

	echo ""
	echo -e "${GREEN}🎉 Deployment Summary${NC}"
	echo -e "${GREEN}=====================${NC}"
	echo -e "Network:                 $NETWORK"
	echo -e "Package ID:              $PACKAGE_ID"
	echo -e "Global State: $GLOBAL_STATE"
	echo -e "Transaction Digest:      $TRANSACTION_DIGEST"
	echo -e "Deployer:               $ACTIVE_ADDRESS"
	echo -e "Deployed at:            $TIMESTAMP"
	echo ""

	# Test the deployment
	print_info "Testing deployment..."
	if sui client object "$PACKAGE_ID" >/dev/null 2>&1; then
		print_status "Package verification successful"
	else
		print_warning "Package verification failed - this might be a timing issue"
	fi

	if sui client object "$GLOBAL_STATE" >/dev/null 2>&1; then
		print_status "Global State verification successful"
	else
		print_warning "Global State verification failed - this might be a timing issue"
	fi

	echo ""
	print_info "Next steps:"
	echo "1. Save the Package ID and Global State ID"
	echo "2. Update your application configuration"
	echo "3. Start creating vaults and entries (registry will be automatically created)"
	echo ""
	print_status "Deployment completed successfully! 🎉"

else
	print_error "Deployment failed!"
	echo "$DEPLOY_OUTPUT"

	# Common failure scenarios
	if echo "$DEPLOY_OUTPUT" | grep -q "InsufficientGas"; then
		print_warning "Try increasing the gas budget: ./scripts/deploy.sh $NETWORK 30000000"
	elif echo "$DEPLOY_OUTPUT" | grep -q "DependencyVerificationFailed"; then
		print_warning "Try with skip dependency verification: sui client publish --gas-budget $GAS_BUDGET --skip-dependency-verification"
	fi

	exit 1
fi
