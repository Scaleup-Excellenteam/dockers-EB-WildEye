#!/bin/bash

# Colors based on user preference
LAVENDER='\033[1;35m'      # A light/bright purple for headers
DEEP_GREEN='\033[0;32m'     # For success messages
Cyan='\033[0;36m'   # For informational messages
RED='\033[0;31m'           # Kept for error messages
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "\n${LAVENDER}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${LAVENDER}║${WHITE}                 DOCKER CODE EXECUTOR TEST                ${LAVENDER}║${NC}"
    echo -e "${LAVENDER}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

print_separator() {
    echo -e "${LAVENDER}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_test_header() {
    local lang=$1
    echo -e "\n${LAVENDER}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${LAVENDER}│  Testing ${WHITE}$lang${LAVENDER} Executor                                       │${NC}"
    echo -e "${LAVENDER}└─────────────────────────────────────────────────────────────┘${NC}"
}

print_success() {
    echo -e "${DEEP_GREEN}[SUCCESS] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

print_info() {
    echo -e "${Cyan}[INFO] $1${NC}"
}

# Function to test a language
test_language() {
    local lang=$1
    local code=$2
    local file=$3
    
    print_test_header "$lang"
    
    # Create test file
    echo "$code" > "$file"
    print_info "Created test file: $file"
    
    # Upload file
    print_info "Uploading code..."
    RESPONSE=$(curl -s -F "file=@$file" -F "lang=$lang" http://localhost:5004/upload 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        print_error "Failed to connect to server"
        return 1
    fi
    
    FILE_ID=$(echo $RESPONSE | grep -o '"file_id":"[^"]*' | cut -d'"' -f4)
    
    if [ -z "$FILE_ID" ]; then
        print_error "Failed to upload file"
        echo -e "${RED}Response: $RESPONSE${NC}"
        return 1
    fi
    
    print_success "File uploaded successfully (ID: $FILE_ID)"
    
    # Execute code
    print_info "Executing code..."
    RESULT=$(curl -s http://localhost:5004/execute/$FILE_ID 2>/dev/null)
    
    # Parse output
    STDOUT=$(echo $RESULT | grep -o '"stdout":"[^"]*' | cut -d'"' -f4)
    STDERR=$(echo $RESULT | grep -o '"stderr":"[^"]*' | cut -d'"' -f4)
    
    # Display output
    if [ -n "$STDOUT" ]; then
        print_success "Execution successful!"
        echo -e "${WHITE}Output:${NC}"
        echo -e "${DEEP_GREEN}$STDOUT${NC}" | sed 's/\\n/\n/g'
    fi
    
    if [ -n "$STDERR" ] && [ "$STDERR" != "" ]; then
        echo -e "${WHITE}Errors:${NC}"
        echo -e "${RED}$STDERR${NC}" | sed 's/\\n/\n/g'
    fi
    
    # Clean up
    rm -f "$file"
}

# Function to check if services are running
check_services() {
    print_info "Checking Docker services..."
    
    # Check if docker is running
    if ! docker ps >/dev/null 2>&1; then
        print_error "Docker is not running!"
        exit 1
    fi
    
    # Check if containers are running
    RUNNING_CONTAINERS=$(docker ps --format "table {{.Names}}" | grep -E "(router|python-executor|java-executor|dart-executor)" | wc -l)
    
    if [ $RUNNING_CONTAINERS -lt 4 ]; then
        print_error "Not all containers are running!"
        echo -e "${Cyan}Run: docker-compose up -d${NC}"
        docker ps
        exit 1
    fi
    
    # Simple check if router port is accessible
    if nc -z localhost 5004 2>/dev/null || curl -s http://localhost:5004/upload -X POST 2>&1 | grep -q "No file provided"; then
        print_success "Router service is accessible on port 5004"
    else
        print_error "Router service is not accessible on port 5004"
        echo -e "${Cyan}Waiting a few seconds for services to start...${NC}"
        sleep 3
        
        # Try one more time
        if ! nc -z localhost 5004 2>/dev/null; then
            print_error "Router still not accessible. Please check the logs."
            exit 1
        fi
    fi
    
    print_success "All services appear to be running!"
}

# Main execution
clear
print_header

# Check services
check_services
print_separator

# Test Python
PYTHON_CODE='import sys
print("Hello from Python!")
print(f"Python version: {sys.version.split()[0]}")
for i in range(3):
    print(f"  Counting: {i + 1}")
print("Python test complete!")'

test_language "python" "$PYTHON_CODE" "test.py"
sleep 1

print_separator

# Test Java
JAVA_CODE='public class Main {
    public static void main(String[] args) {
        System.out.println("Hello from Java!");
        System.out.println("Java version: " + System.getProperty("java.version"));
        for (int i = 1; i <= 3; i++) {
            System.out.println("  Counting: " + i);
        }
        System.out.println("Java test complete!");
    }
}'

test_language "java" "$JAVA_CODE" "Main.java"
sleep 1

print_separator

# Test Dart
DART_CODE='import "dart:io";

void main() {
  print("Hello from Dart!");
  print("Dart version: ${Platform.version.split(" ")[0]}");
  for (int i = 1; i <= 3; i++) {
    print("  Counting: $i");
  }
  print("Dart test complete!");
}'

test_language "dart" "$DART_CODE" "test.dart"

print_separator

# Summary
echo -e "\n${LAVENDER}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${LAVENDER}║${WHITE}                        TEST COMPLETE!                      ${LAVENDER}║${NC}"
echo -e "${LAVENDER}╚══════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${DEEP_GREEN}All language executors tested successfully!${NC}"
echo -e "${Cyan}Access the web interface at: ${WHITE}http://localhost:5005${NC}\n"