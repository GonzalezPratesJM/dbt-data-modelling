# Financial Sentiment DBT Project Setup

This DBT project analyzes financial sentiment from news articles, Reddit posts, and stock data.

## Prerequisites

- Python 3.8+
- DBT Core installed (`pip install dbt-core dbt-postgres`)
- PostgreSQL database access

## Setup Instructions

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd data-modelling
```

### 2. Set Up Environment Variables
Create a `.env` file in the project root with your database credentials:

```bash
# Database Configuration
DB_HOST=your-database-host
DB_USER=your-database-user
DB_PASSWORD=your-database-password
DB_NAME=your-database-name
```

### 3. Configure DBT Profile
Copy the template and configure your database connection:

```bash
cp profiles.yml.template profiles.yml
```

Edit `profiles.yml` to use your actual database credentials or environment variables.

### 4. Install Dependencies
```bash
dbt deps
```

### 5. Run the Project
```bash
# Run all models
dbt run

# Run specific models
dbt run --select staging
dbt run --select intermediate
dbt run --select marts

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

## Project Structure

```
data-modelling/
├── models/
│   ├── staging/          # Raw data transformations
│   ├── intermediate/      # Business logic transformations
│   └── marts/           # Final presentation layer
├── seeds/               # Static data files
├── macros/              # Reusable SQL macros
├── tests/               # Data quality tests
└── dbt_project.yml      # Project configuration
```

## Data Sources

- **News Articles**: Financial news sentiment analysis
- **Reddit Posts**: Social media sentiment from r/wallstreetbets
- **Stock Prices**: Historical price data for analysis

## Models Overview

### Staging Models
- `stg_news_articles`: Cleaned news article data
- `stg_reddit_posts`: Processed Reddit post data
- `stg_stock_prices`: Standardized stock price data

### Intermediate Models
- `int_basic_sentiment`: Basic sentiment scoring
- `int_ticker_extraction`: Stock ticker identification
- `int_time_windows`: Time-based aggregations
- `int_price_movements`: Price change calculations

### Mart Models
- `fact_sentiment_events`: Core fact table
- `dim_stocks`: Stock dimension table
- `mart_ml_features`: Features for machine learning
- `mart_agent_ready`: Data prepared for AI agents

## Testing

The project includes comprehensive data quality tests:

```bash
# Run all tests
dbt test

# Run specific test categories
dbt test --select generic
dbt test --select singular
```

## Documentation

Generate and view project documentation:

```bash
dbt docs generate
dbt docs serve
```

Visit `http://localhost:8080` to view the documentation.

## Contributing

1. Create a feature branch
2. Make your changes
3. Add tests for new models
4. Update documentation
5. Submit a pull request

## Security Notes

- Never commit `profiles.yml` with real credentials
- Use environment variables for sensitive configuration
- The `.gitignore` file prevents accidental commits of sensitive files 