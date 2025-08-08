# 🚀 dbt Project Setup Guide for Supabase Integration

This guide will help you set up your dbt project to consume data from your Supabase database and materialize staging, intermediate, and marts tables.

## 📋 Prerequisites

1. **Python environment** with pip installed
2. **Supabase database** with the following tables:
   - `news_articles`
   - `stock_prices` 
   - `reddit_posts`
3. **Supabase database password** (found in Supabase Dashboard > Settings > Database)

## 🔧 Step 1: Install dbt

```bash
# Install dbt with PostgreSQL support
pip install dbt-core dbt-postgres
```

## 🔧 Step 2: Set Environment Variables

```bash
# Set your Supabase database password
export SUPABASE_DB_PASSWORD="your_supabase_password_here"

# Verify it's set
echo $SUPABASE_DB_PASSWORD
```

**To find your Supabase password:**
1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to Settings > Database
4. Copy the database password

## 🔧 Step 3: Verify Database Connection

The project is configured to connect to your Supabase database:
- **Host**: `db.wjsvxpvfjrerxiepjrjw.supabase.co`
- **Database**: `postgres`
- **Schema**: `public`
- **User**: `postgres`

## 🔧 Step 4: Run the Setup Script

```bash
# Navigate to the dbt project directory
cd module-8/data-modelling

# Run the setup script
./setup_dbt.sh
```

Or run the commands manually:

```bash
# Install dependencies
dbt deps

# Seed the data
dbt seed

# Run all models
dbt run

# Run tests
dbt test
```

## 📊 What Gets Created

### **Staging Layer (Views)**
- `staging.stg_news_articles` - Cleaned news data
- `staging.stg_stock_prices` - Processed stock data  
- `staging.stg_reddit_posts` - Processed Reddit data

### **Intermediate Layer (Tables)**
- `intermediate.int_basic_sentiment` - Basic sentiment analysis
- `intermediate.int_ticker_extraction` - Stock ticker extraction
- `intermediate.int_price_movements` - Price analysis
- `intermediate.int_time_windows` - Time-based aggregations

### **Marts Layer (Tables)**
- `marts.dim_stocks` - Stock dimension table
- `marts.fact_sentiment_events` - Sentiment events
- `marts.mart_ml_features` - ML-ready features
- `marts.mart_agent_ready` - Agent consumption layer

## 🔍 Verify the Setup

### **Check Models in Supabase**
1. Go to your Supabase Dashboard
2. Navigate to Table Editor
3. You should see the new schemas: `staging`, `intermediate`, `marts`

### **Generate Documentation**
```bash
# Generate documentation
dbt docs generate

# Serve documentation locally
dbt docs serve
```

### **Check Model Status**
```bash
# List all models
dbt ls

# Check model status
dbt run --dry-run
```

## 🔄 Refreshing Data

### **Full Refresh**
```bash
# Refresh all models
dbt run --full-refresh
```

### **Selective Refresh**
```bash
# Refresh only staging models
dbt run --select staging

# Refresh only intermediate models  
dbt run --select intermediate

# Refresh only marts models
dbt run --select marts
```

### **Incremental Updates**
```bash
# Run only new/changed models
dbt run
```

## 🧪 Testing

### **Run All Tests**
```bash
dbt test
```

### **Run Specific Tests**
```bash
# Test staging models
dbt test --select staging

# Test intermediate models
dbt test --select intermediate

# Test marts models
dbt test --select marts
```

## 📈 Monitoring

### **Check Model Performance**
```bash
# Show model execution times
dbt run --profiles-dir . --target dev
```

### **View Model Dependencies**
```bash
# Generate dependency graph
dbt ls --select +model_name
```

## 🛠️ Troubleshooting

### **Connection Issues**
```bash
# Test database connection
dbt debug
```

### **Model Errors**
```bash
# Check model compilation
dbt compile

# Run with verbose logging
dbt run --verbose
```

### **Permission Issues**
- Ensure your Supabase user has CREATE, SELECT, INSERT permissions
- Check Row Level Security (RLS) settings

## 📊 Data Flow

```
Raw Supabase Tables → Staging (Views) → Intermediate (Tables) → Marts (Tables)
     ↓                    ↓                    ↓                    ↓
  news_articles    stg_news_articles   int_basic_sentiment   dim_stocks
  stock_prices     stg_stock_prices    int_ticker_extraction fact_sentiment_events
  reddit_posts     stg_reddit_posts    int_price_movements  mart_ml_features
                                                             mart_agent_ready
```

## 🎯 Next Steps

1. **Verify data quality** by running tests
2. **Monitor model performance** in Supabase
3. **Set up automated runs** with dbt Cloud or cron
4. **Integrate with your sentiment agent** using the marts tables

## 📞 Support

If you encounter issues:

1. **Check logs**: `dbt run --verbose`
2. **Verify connection**: `dbt debug`
3. **Check Supabase logs**: Dashboard > Logs
4. **Review model dependencies**: `dbt ls --select +model_name`

## 🚀 Advanced Usage

### **Custom Materialization**
```sql
-- In your model file
{{ config(materialized='table') }}
```

### **Incremental Models**
```sql
-- For large tables
{{ config(materialized='incremental') }}
```

### **Snapshots**
```bash
# Track changes over time
dbt snapshot
```

---

**🎉 Your dbt project is now ready to consume data from Supabase and materialize staging, intermediate, and marts tables!** 