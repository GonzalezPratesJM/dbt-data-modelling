#!/bin/bash

# Setup script for dbt project to consume Supabase data
echo "🚀 Setting up dbt project for Supabase integration..."

# Check if dbt is installed
if ! command -v dbt &> /dev/null; then
    echo "❌ dbt is not installed. Installing dbt..."
    pip install dbt-core dbt-postgres
else
    echo "✅ dbt is already installed"
fi

# Set environment variable for Supabase password
if [ -z "$SUPABASE_DB_PASSWORD" ]; then
    echo "⚠️  SUPABASE_DB_PASSWORD environment variable not set"
    echo "Please set it with: export SUPABASE_DB_PASSWORD='your_supabase_password'"
    echo "You can find your password in Supabase Dashboard > Settings > Database"
    exit 1
fi

echo "✅ Environment variables configured"

# Install dbt dependencies
echo "📦 Installing dbt dependencies..."
dbt deps

# Seed the data
echo "🌱 Seeding data..."
dbt seed

# Run staging models
echo "🔄 Running staging models..."
dbt run --select staging

# Run intermediate models
echo "🔄 Running intermediate models..."
dbt run --select intermediate

# Run marts models
echo "🔄 Running marts models..."
dbt run --select marts

# Run tests
echo "🧪 Running tests..."
dbt test

echo "✅ dbt project setup complete!"
echo ""
echo "📊 Your models are now materialized in Supabase:"
echo "   - Staging: staging.* (views)"
echo "   - Intermediate: intermediate.* (tables)"
echo "   - Marts: marts.* (tables)"
echo ""
echo "🔍 To view your models:"
echo "   - dbt docs generate"
echo "   - dbt docs serve"
echo ""
echo "🔄 To refresh data:"
echo "   - dbt run --select staging+intermediate+marts" 