#!/bin/bash
# Script generated w/ gemini

# Usage: ./update_constraints.sh <AIRFLOW_VERSION> <PYTHON_VERSION>
AIRFLOW_VERSION=$1
PYTHON_VERSION=$2

# Check for required arguments
if [ -z "$AIRFLOW_VERSION" ] || [ -z "$PYTHON_VERSION" ]; then
    echo "❌ Error: Missing parameters."
    echo "Usage: $0 <AIRFLOW_VERSION> <PYTHON_VERSION>"
    echo "Example: $0 3.3.0 3.14"
    exit 1
fi

# Define paths (assuming the script is in a subdirectory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PYPROJECT_FILE="$PROJECT_ROOT/pyproject.toml"

# Constraints URL
CONSTRAINTS_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-no-providers-${PYTHON_VERSION}.txt"

echo "🔍 Target file: $PYPROJECT_FILE"
echo "🌐 Fetching constraints for: Airflow $AIRFLOW_VERSION | Python $PYTHON_VERSION"

# Check if pyproject.toml exists
if [ ! -f "$PYPROJECT_FILE" ]; then
    echo "❌ Error: $PYPROJECT_FILE not found."
    exit 1
fi

echo "📥 Downloading constraints..."
# Fetch constraints, filter versions, wrap in quotes, and join with commas
NEW_CONSTRAINTS=$(curl -sSL "$CONSTRAINTS_URL" | grep '==' | sed 's/.*/"&"/' | paste -sd "," -)

if [ -z "$NEW_CONSTRAINTS" ]; then
    echo "❌ Error: Could not retrieve constraints from the URL."
    echo "Please verify the Airflow or Python version on the official Airflow GitHub repo."
    exit 1
fi

# Update the file using Perl (handles long strings better than sed)
perl -i -pe "s|constraint-dependencies = \[.*?\]|constraint-dependencies = [$NEW_CONSTRAINTS]|g" "$PYPROJECT_FILE"

if [ $? -eq 0 ]; then
    echo "✅ pyproject.toml updated successfully."
else
    echo "❌ Error: Failed to write to the file."
    exit 1
fi
