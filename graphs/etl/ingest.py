import os
import openbb
from neo4j import GraphDatabase
from dotenv import load_dotenv
import logging

# Set up basic logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# Load environment variables from a .env file if it exists
load_dotenv()

class Neo4jIngestor:
    """A class to manage the connection to Neo4j and ingest data."""

    def __init__(self, uri, user, password):
        """Initialize the Neo4j driver."""
        try:
            self._driver = GraphDatabase.driver(uri, auth=(user, password))
            logging.info("Successfully connected to Neo4j.")
        except Exception as e:
            logging.error(f"Failed to connect to Neo4j: {e}")
            self._driver = None

    def close(self):
        """Close the Neo4j driver connection."""
        if self._driver is not None:
            self._driver.close()
            logging.info("Neo4j connection closed.")

    def ingest_stock_data(self, ticker):
        """Fetch historical stock data from OpenBB and ingest it into Neo4j."""
        if self._driver is None:
            logging.error("No active Neo4j connection. Aborting ingestion.")
            return

        logging.info(f"Fetching data for ticker: {ticker}")
        try:
            # Fetch historical OHLCV data using OpenBB SDK
            stock_data = openbb.stocks.load(ticker, start_date="2023-01-01")
            if stock_data.empty:
                logging.warning(f"No data returned for ticker: {ticker}")
                return
        except Exception as e:
            logging.error(f"Failed to fetch data from OpenBB for {ticker}: {e}")
            return

        logging.info(f"Ingesting {len(stock_data)} data points for {ticker}...")
        # Use a session for transactional queries
        with self._driver.session() as session:
            # Ensure the Asset node exists
            session.run("MERGE (a:Asset {ticker: $ticker}) ON CREATE SET a.name = $name, a.type = 'Equity'", 
                        ticker=ticker, name=stock_data.attrs.get('name', ticker))

            # Unwind the list of data points and create OHLCV nodes and relationships
            # This is much more efficient than running a query for each row
            cypher_query = """
            UNWIND $ohlcv_data as row
            MERGE (a:Asset {ticker: $ticker})
            MERGE (o:OHLCV {asset_ticker: $ticker, timestamp: datetime(row.date)})
            SET
                o.open = row.open,
                o.high = row.high,
                o.low = row.low,
                o.close = row.close,
                o.volume = row.volume
            MERGE (a)-[:HAS_PRICE_DATA]->(o)
            """
            
            # Convert DataFrame to a list of dictionaries for the query parameter
            ohlcv_list = [
                {
                    "date": record.Index.to_pydatetime().isoformat(),
                    "open": record.Open,
                    "high": record.High,
                    "low": record.Low,
                    "close": record.Close,
                    "volume": record.Volume
                }
                for record in stock_data.itertuples()
            ]

            try:
                session.run(cypher_query, ticker=ticker, ohlcv_data=ohlcv_list)
                logging.info(f"Successfully ingested data for {ticker}.")
            except Exception as e:
                logging.error(f"Failed during Neo4j data ingestion for {ticker}: {e}")


def main():
    """Main function to run the ETL process."""
    # Configuration - fetch from environment variables with sensible defaults for local dev
    NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:8687")
    NEO4J_USER = os.getenv("NEO4J_USER", "neo4j")
    NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "password")

    ingestor = Neo4jIngestor(NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD)

    # List of tickers to ingest data for
    tickers_to_ingest = ["AAPL", "MSFT", "GOOG"]

    for ticker in tickers_to_ingest:
        ingestor.ingest_stock_data(ticker)

    ingestor.close()

if __name__ == "__main__":
    main()
