#!/bin/bash

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="${SCRIPT_DIR}/venv-dft"
REQUIREMENTS_FILE="${SCRIPT_DIR}/requirement.txt"

# Print banner
echo -e "${BLUE}==============================================${NC}"
echo -e "${BLUE}  Setting up Python Virtual Environment${NC}"
echo -e "${BLUE}  for Graphene DFT Calculations${NC}"
echo -e "${BLUE}==============================================${NC}"

# Check if Python 3 is installed
echo -e "\n${YELLOW}Checking dependencies...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is not installed or not in PATH.${NC}"
    echo -e "Please install Python 3.6 or higher before continuing."
    exit 1
fi

# Check Python version
PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
echo -e "Found Python version: ${GREEN}${PYTHON_VERSION}${NC}"

# Check for pip
if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
    echo -e "${RED}Error: pip is not installed.${NC}"
    echo -e "Please install pip before continuing."
    exit 1
fi

# Check for venv module
if ! python3 -c "import venv" &> /dev/null; then
    echo -e "${RED}Error: Python venv module is not available.${NC}"
    echo -e "Please install the Python venv package for your distribution."
    echo -e "For example, on Ubuntu/Debian: sudo apt-get install python3-venv"
    exit 1
fi

# Check if requirements file exists
if [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo -e "${RED}Error: Requirements file not found at ${REQUIREMENTS_FILE}${NC}"
    exit 1
fi

# Function to create and activate virtual environment
setup_venv() {
    # Check if venv exists
    if [ ! -d "$VENV_DIR" ]; then
        echo -e "\n${YELLOW}Creating virtual environment at ${VENV_DIR}...${NC}"
        python3 -m venv "$VENV_DIR"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error: Failed to create virtual environment.${NC}"
            exit 1
        fi
        echo -e "${GREEN}Virtual environment created successfully.${NC}"
    else
        echo -e "\n${YELLOW}Virtual environment already exists at ${VENV_DIR}${NC}"
    fi

    # Activate virtual environment
    echo -e "\n${YELLOW}Activating virtual environment...${NC}"
    source "${VENV_DIR}/bin/activate"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to activate virtual environment.${NC}"
        exit 1
    fi
    
    # Verify activation
    if [[ "$VIRTUAL_ENV" != "$VENV_DIR" ]]; then
        echo -e "${RED}Error: Virtual environment activation failed.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Virtual environment activated: $(which python)${NC}"
}

# Function to install requirements
install_requirements() {
    echo -e "\n${YELLOW}Upgrading pip...${NC}"
    pip install --upgrade pip
    
    echo -e "\n${YELLOW}Installing required packages...${NC}"
    echo -e "Requirements from: ${REQUIREMENTS_FILE}"
    
    # Display packages to be installed
    echo -e "\nPackages to be installed:"
    cat "$REQUIREMENTS_FILE" | sed 's/^/  - /'
    echo ""
    
    # Install requirements
    pip install -r "$REQUIREMENTS_FILE"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Failed to install required packages.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Required packages installed successfully.${NC}"
    
    # List installed packages with versions for verification
    echo -e "\n${YELLOW}Installed packages:${NC}"
    pip list | grep -E "$(cat $REQUIREMENTS_FILE | tr '\n' '|' | sed 's/|$//')"
}

# Main execution
setup_venv
install_requirements

echo -e "\n${GREEN}Setup complete!${NC}"
echo -e "${YELLOW}---------------------------------------${NC}"
echo -e "${YELLOW}To activate this environment later, run:${NC}"
echo -e "  source ${VENV_DIR}/bin/activate"
echo -e "${YELLOW}To deactivate, run:${NC}"
echo -e "  deactivate"
echo -e "${YELLOW}---------------------------------------${NC}"

