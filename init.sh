#!/bin/bash

find . -type f -name "*.sh" -print0 | while IFS= read -r -d $'\0' file; do
    chmod +x "$file"

done

./python-venv.sh
