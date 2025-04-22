#!/bin/bash

find . -type f -name "*.sh" -print0 | while IFS= read -r -d $'\0' file; do
    if [[ ! -x "$file" ]]; then
        chmod +x "$file"
    fi
done

./update_paths.sh
if [[ $? -ne 0 ]]; then
    echo "Error: update_paths.sh failed." >&2  
    exit 1 
fi

# Check for virtual environment and activate or create
if [[ -d "./venv-dft" ]]; then
  echo "Virtual environment found, activating..."
  source ./venv-dft/bin/activate
else
  echo "Virtual environment not found, creating..."
  ./python-venv.sh
  if [[ $? -ne 0 ]]; then
      echo "Error: python-venv.sh failed." >&2
      exit 1
  fi
  source ./venv-dft/bin/activate 
fi
