# Financial Sentiment Analysis DBT Project

A comprehensive DBT project for analyzing financial sentiment from multiple data sources including news articles, Reddit posts, and stock market data.

## 🚀 Quick Start

1. **Clone and Setup**
   ```bash
   git clone <your-repo-url>
   cd data-modelling
   ```

2. **Configure Database**
   ```bash
   cp profiles.yml.template profiles.yml
   cp env.example .env
   # Edit both files with your database credentials
   ```

3. **Install and Run**
   ```bash
   dbt deps
   dbt run
   dbt test
   ```

## 📊 Project Overview

This project transforms raw financial data into actionable insights through a well-structured data pipeline:

- **Data Sources**: News articles, Reddit posts, stock prices
- **Processing**: Sentiment analysis, ticker extraction, time-based aggregations
- **Output**: ML-ready features and agent-optimized datasets

## 🏗️ Architecture

```
Raw Data → Staging → Intermediate → Marts
    ↓         ↓          ↓           ↓
  Sources   Cleaning   Business   Presentation
            & Validation  Logic      Layer
```

### Data Flow

1. **Staging Layer**: Raw data cleaning and validation
2. **Intermediate Layer**: Business logic and transformations
3. **Mart Layer**: Final presentation for consumption

## 📁 Project Structure

```
data-modelling/
├── models/
│   ├── staging/          # Raw data transformations
│   │   ├── stg_news_articles.sql
│   │   ├── stg_reddit_posts.sql
│   │   └── stg_stock_prices.sql
│   ├── intermediate/      # Business logic
│   │   ├── int_basic_sentiment.sql
│   │   ├── int_ticker_extraction.sql
│   │   ├── int_time_windows.sql
│   │   └── int_price_movements.sql
│   └── marts/           # Final presentation
│       ├── fact_sentiment_events.sql
│       ├── dim_stocks.sql
│       ├── mart_ml_features.sql
│       └── mart_agent_ready.sql
├── seeds/               # Static reference data
│   ├── sentiment_keywords.csv
│   └── stock_symbols.csv
├── macros/              # Reusable SQL functions
├── tests/               # Data quality tests
└── dbt_project.yml      # Project configuration
```

## 🔧 Configuration

### Environment Variables

Set up your database connection in `.env`:

```bash
DB_HOST=your-database-host
DB_USER=your-database-user
DB_PASSWORD=your-database-password
DB_NAME=your-database-name
```

### DBT Profile

Configure your database connection in `profiles.yml`:

```yaml
financial_sentiment:
  target: dev
  outputs:
    dev:
      type: postgres
      host: "{{ env_var('DB_HOST') }}"
      user: "{{ env_var('DB_USER') }}"
      password: "{{ env_var('DB_PASSWORD') }}"
      dbname: "{{ env_var('DB_NAME') }}"
```

## 📈 Models

### Staging Models
- **`stg_news_articles`**: Cleaned news article data with sentiment scores
- **`stg_reddit_posts`**: Processed Reddit posts from financial subreddits
- **`stg_stock_prices`**: Standardized stock price data

### Intermediate Models
- **`int_basic_sentiment`**: Sentiment scoring using keyword analysis
- **`int_ticker_extraction`**: Stock ticker identification from text
- **`int_time_windows`**: Time-based aggregations and windows
- **`int_price_movements`**: Price change calculations and volatility

### Mart Models
- **`fact_sentiment_events`**: Core fact table with all sentiment events
- **`dim_stocks`**: Stock dimension with company information
- **`mart_ml_features`**: Features optimized for machine learning
- **`mart_agent_ready`**: Data prepared for AI agent consumption

## 🧪 Testing

Comprehensive data quality tests ensure data integrity:

```bash
# Run all tests
dbt test

# Test specific categories
dbt test --select generic    # Generic tests (not null, unique, etc.)
dbt test --select singular   # Custom SQL tests
```

## 📚 Documentation

Generate and view project documentation:

```bash
dbt docs generate
dbt docs serve
```

Visit `http://localhost:8080` for interactive documentation.

## 🔒 Security

This project follows security best practices:

- ✅ No hardcoded credentials
- ✅ Environment variable configuration
- ✅ Comprehensive `.gitignore`
- ✅ Template files for setup

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For questions or issues:
1. Check the documentation
2. Review existing issues
3. Create a new issue with detailed information

---

**Note**: This project has been cleaned of all sensitive information and is ready for public GitHub upload. 