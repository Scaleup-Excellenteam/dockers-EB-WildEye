#!/bin/bash
# test_project.sh - Test script for Multi-Language Code Execution System (WSL-optimized)

echo "🚀 Testing Multi-Language Code Execution System (WSL)"
echo "===================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# WSL-specific checks
print_status "Checking WSL environment..."

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    print_error "Docker command not found!"
    echo "Please make sure Docker Desktop is installed and WSL integration is enabled."
    echo "Go to Docker Desktop → Settings → Resources → WSL Integration"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    print_error "docker-compose command not found!"
    echo "Please install docker-compose in WSL or use 'docker compose' instead."
    exit 1
fi

# Test Docker connectivity
print_status "Testing Docker connectivity..."
if ! docker info &> /dev/null; then
    print_error "Cannot connect to Docker daemon!"
    echo "Please make sure Docker Desktop is running and WSL integration is enabled."
    exit 1
fi

print_success "Docker is accessible from WSL"

# Stop any existing containers
print_status "Stopping any existing containers..."
docker-compose down > /dev/null 2>&1

# Build and start containers
print_status "Building and starting Docker containers..."
echo "This might take a few minutes on first run..."
docker-compose up --build -d

if [ $? -ne 0 ]; then
    print_error "Failed to start Docker containers!"
    echo "Please check the error messages above."
    echo "Common WSL issues:"
    echo "  1. Make sure Docker Desktop is running"
    echo "  2. Enable WSL integration in Docker Desktop settings"
    echo "  3. Check if Windows firewall is blocking Docker"
    exit 1
fi

# Wait for services to start
print_status "Waiting for services to start..."
echo "Waiting 20 seconds for containers to fully initialize..."
sleep 20

# Check if containers are running
print_status "Checking container status..."
docker-compose ps

echo ""
echo "🧪 Starting Tests..."
echo "==================="

# Test function with proper JSON escaping
test_language() {
    local lang=$1
    local code=$2
    local description=$3
    
    echo ""
    print_status "Testing $description..."
    
    # Create properly escaped JSON using printf and sed
    local json_payload=$(printf '{"lang": "%s", "code": "%s"}' "$lang" "$(echo "$code" | sed 's/\\/\\\\/g; s/"/\\"/g')")
    
    # Use localhost for WSL (should work with Docker Desktop)
    response=$(curl -s -X POST http://localhost:5004/execute \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        --connect-timeout 10 \
        --max-time 20)
    
    curl_exit_code=$?
    
    if [ $curl_exit_code -eq 0 ]; then
        # Check if response is valid JSON and contains our expected fields
        if echo "$response" | python3 -m json.tool &> /dev/null; then
            stdout=$(echo "$response" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('stdout', ''))" 2>/dev/null)
            stderr=$(echo "$response" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('stderr', ''))" 2>/dev/null)
            
            if [ -n "$stdout" ]; then
                print_success "$description working!"
                echo "Output: $stdout"
            elif [ -n "$stderr" ]; then
                print_warning "$description has errors:"
                echo "Error: $stderr"
            else
                print_error "$description returned empty response"
                echo "Raw response: $response"
            fi
        else
            print_error "$description returned invalid JSON"
            echo "Raw response: $response"
        fi
    else
        print_error "$description connection failed! (curl exit code: $curl_exit_code)"
        if [ $curl_exit_code -eq 7 ]; then
            echo "Connection refused - check if containers are running and ports are accessible"
        elif [ $curl_exit_code -eq 28 ]; then
            echo "Timeout - service might be starting slowly"
        fi
    fi
}

# Test Python
test_language "python" "print('Hello from Python!'); print('Test successful!')" "Python Executor"

# Test Java with proper escaping
test_language "java" "public class Test { public static void main(String[] args) { System.out.println(\"Hello from Java!\"); System.out.println(\"Test successful!\"); } }" "Java Executor"

# Test Dart
test_language "dart" "void main() { print('Hello from Dart!'); print('Test successful!'); }" "Dart Executor"

echo ""
echo "🔍 Additional Diagnostics..."
echo "============================"

# Check individual service health
print_status "Checking router connectivity..."

# Test router health
curl -s --connect-timeout 5 http://localhost:5004/ > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_success "Router is responding on port 5004"
else
    print_error "Router is not responding on port 5004"
    print_status "Checking if port is bound..."
    netstat -an 2>/dev/null | grep :5004 || echo "Port 5004 not found in netstat"
fi

# Check logs for errors
print_status "Checking for errors in logs..."
error_logs=$(docker-compose logs 2>&1 | grep -E -i "(error|exception|failed)" | head -5)
if [ -n "$error_logs" ]; then
    print_warning "Found some errors in logs:"
    echo "$error_logs"
else
    print_success "No obvious errors in logs"
fi

echo ""
echo "📋 Test Summary"
echo "==============="
print_status "Containers running:"
docker-compose ps --format "table {{.Name}}\t{{.State}}\t{{.Ports}}" 2>/dev/null || docker-compose ps

echo ""
print_status "WSL/Docker Desktop Tips:"
echo "  • If tests fail, try restarting Docker Desktop"
echo "  • Check Docker Desktop → Settings → Resources → WSL Integration"
echo "  • Windows Defender Firewall might block Docker ports"
echo ""
print_status "Useful commands:"
echo "  docker-compose logs [service-name]  # View detailed logs"
echo "  docker-compose down                 # Stop the system"
echo "  docker-compose up --build          # Rebuild and restart"
echo ""
print_success "🎉 Test complete! All systems functional!"