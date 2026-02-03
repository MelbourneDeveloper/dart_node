#!/bin/bash
# Run data package tests
set -e
cd "$(dirname "$0")/../too_many_cooks_data"

dart test
