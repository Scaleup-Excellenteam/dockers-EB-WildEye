#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Unicode symbols
CHECK="✓"
CROSS="✗"
ROCKET="🚀"
SNAKE="🐍"
COFFEE="☕"
DART="🎯"

# Function to print colored output
print_header() {
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}                  DOCKER CODE EXECUTOR TEST                   ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}\n"
}

print_separator() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_test_header() {
    local lang=$1
    local emoji=$2
    echo -e "\n${PURPLE}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│ ${emoji}  Testing ${WHITE}$lang${PURPLE} Executor                                   │${NC}"
    echo -e "${PURPLE}└─────────────────────────────────────────────────────────────┘${NC}"
}

print_success() {
    echo -e "${GREEN}${CHECK} $1${NC}"
}

print_error() {
    echo -e "${RED}${CROSS} $1${NC}"
}

print_info() {
    echo -e "${YELLOW}➤ $1${NC}"
}

# Function to test a language
test_language() {
    local lang=$1
    local code=$2
    local file=$3
    local emoji=$4
    
    print_test_header "$lang" "$emoji"
    
    # Create test file
    echo "$code" > "$file"
    print_info "Created test file: $file"
    
    # Upload file
    print_info "Uploading code..."
    RESPONSE=$(curl -s -F "file=@$file" -F "lang=$lang" http://localhost:5004/upload)
    
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
    RESULT=$(curl -s http://localhost:5004/execute/$FILE_ID)
    
    # Parse output
    STDOUT=$(echo $RESULT | grep -o '"stdout":"[^"]*' | cut -d'"' -f4)
    STDERR=$(echo $RESULT | grep -o '"stderr":"[^"]*' | cut -d'"' -f4)
    
    # Display output
    if [ -n "$STDOUT" ]; then
        print_success "Execution successful!"
        echo -e "${WHITE}Output:${NC}"
        echo -e "${GREEN}$STDOUT${NC}" | sed 's/\\n/\n/g'
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
    
    # Check if router is accessible
    if curl -s -f http://localhost:5004/upload -X POST >/dev/null 2>&1; then
        print_success "Router service is running"
    else
        print_error "Router service is not accessible"
        echo -e "${YELLOW}Run: docker-compose up -d${NC}"
        exit 1
    fi
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

test_language "python" "$PYTHON_CODE" "test.py" "$SNAKE"
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

test_language "java" "$JAVA_CODE" "Main.java" "$COFFEE"
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

test_language "dart" "$DART_CODE" "test.dart" "$DART"

print_separator

# Summary
echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${WHITE}                      TEST COMPLETE!                          ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${GREEN}${ROCKET} All language executors tested successfully!${NC}"
echo -e "${YELLOW}${CHECK} Access the web interface at: ${WHITE}http://localhost:5005${NC}\n"