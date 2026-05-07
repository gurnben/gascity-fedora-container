#!/usr/bin/env bash
set -euo pipefail

# Smoke test hook — runs build and test commands before a dog agent
# can close its bead. Detects the project type and runs the appropriate
# build/test commands.

failed=0

if [ -f "go.mod" ]; then
    echo "Running Go build and tests..."
    go build ./... || failed=1
    go test ./... || failed=1
elif [ -f "package.json" ]; then
    echo "Running Node build and tests..."
    if grep -q '"build"' package.json; then
        npm run build || failed=1
    fi
    if grep -q '"test"' package.json; then
        npm test || failed=1
    fi
elif [ -f "Cargo.toml" ]; then
    echo "Running Rust build and tests..."
    cargo build || failed=1
    cargo test || failed=1
elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "requirements.txt" ]; then
    echo "Running Python tests..."
    if command -v pytest &>/dev/null; then
        python -m pytest || failed=1
    elif [ -f "Makefile" ] && grep -q "^test:" Makefile; then
        make test || failed=1
    fi
elif [ -f "Makefile" ]; then
    echo "Running Makefile build and tests..."
    make build 2>/dev/null || true
    if grep -q "^test:" Makefile; then
        make test || failed=1
    fi
fi

if [ "$failed" -ne 0 ]; then
    echo "SMOKE TEST FAILED — fix the issues before completing."
    exit 1
fi

echo "Smoke test passed."
exit 0
