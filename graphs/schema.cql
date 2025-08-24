/*
----------------------------------------------------------------------
-- Neo4j Graph Schema for MLOps-DRL Portfolio Management
-- 
-- Author: Gemini
-- Version: 2.0
-- Description: A comprehensive schema for a hedge fund / investment bank
--              grade system, integrating market data, blockchain events,
--              ML predictions, and compliance/audit trails.
----------------------------------------------------------------------
*/


/*
----------------------------------------------------------------------
-- SECTION 1: CONSTRAINTS & UNIQUENESS
--
-- Enforces data integrity by ensuring key identifiers for entities
-- are unique across the graph. Neo4j automatically creates backing
-- indexes for properties with uniqueness constraints, ensuring fast
-- lookups.
----------------------------------------------------------------------
*/

-- Core Financial Entities
CREATE CONSTRAINT asset_ticker IF NOT EXISTS FOR (a:Asset) REQUIRE a.ticker IS UNIQUE;
CREATE CONSTRAINT transaction_id IF NOT EXISTS FOR (t:Transaction) REQUIRE t.transactionId IS UNIQUE;
CREATE CONSTRAINT order_id IF NOT EXISTS FOR (o:Order) REQUIRE o.orderId IS UNIQUE;
CREATE CONSTRAINT portfolio_id IF NOT EXISTS FOR (p:Portfolio) REQUIRE p.portfolioId IS UNIQUE;
CREATE CONSTRAINT account_id IF NOT EXISTS FOR (a:Account) REQUIRE a.accountId IS UNIQUE;
CREATE CONSTRAINT trader_id IF NOT EXISTS FOR (t:Trader) REQUIRE t.traderId IS UNIQUE;

-- Blockchain Entities
CREATE CONSTRAINT wallet_address IF NOT EXISTS FOR (w:Wallet) REQUIRE w.address IS UNIQUE;
CREATE CONSTRAINT contract_address IF NOT EXISTS FOR (c:SmartContract) REQUIRE c.address IS UNIQUE;
CREATE CONSTRAINT onchain_tx_hash IF NOT EXISTS FOR (otx:OnChainTransaction) REQUIRE otx.tx_hash IS UNIQUE;
CREATE CONSTRAINT blockchain_name IF NOT EXISTS FOR (b:Blockchain) REQUIRE b.name IS UNIQUE;

-- Market Data & Event Entities
CREATE CONSTRAINT market_event_id IF NOT EXISTS FOR (e:MarketEvent) REQUIRE e.eventId IS UNIQUE;

-- ML & Audit Entities
CREATE CONSTRAINT ml_model_id IF NOT EXISTS FOR (m:MLModel) REQUIRE m.modelId IS UNIQUE;
CREATE CONSTRAINT data_source_name IF NOT EXISTS FOR (ds:DataSource) REQUIRE ds.name IS UNIQUE;


/*
----------------------------------------------------------------------
-- SECTION 2: INDEXES FOR QUERY PERFORMANCE
--
-- Creates indexes on properties that are frequently used in `WHERE`
-- clauses, `ORDER BY`, or `JOIN` operations (lookups) but are not
-- necessarily unique. This is critical for high-performance queries,
-- especially on time-series data.
----------------------------------------------------------------------
*/

-- Composite index for fast retrieval of price data for a specific asset over time.
CREATE INDEX ohlcv_asset_timestamp IF NOT EXISTS FOR (n:OHLCV) ON (n.asset_ticker, n.timestamp);

-- Composite index for technical indicators.
CREATE INDEX indicator_asset_timestamp IF NOT EXISTS FOR (n:Indicator) ON (n.asset_ticker, n.name, n.timestamp);

-- Index for fast lookup of assets by type (e.g., 'Equity', 'Derivative').
CREATE INDEX asset_type IF NOT EXISTS FOR (a:Asset) ON (a.type);

-- Index for looking up on-chain transactions by block number.
CREATE INDEX onchain_tx_block_number IF NOT EXISTS FOR (otx:OnChainTransaction) ON (otx.block_number);

-- Index for finding orders by their status.
CREATE INDEX order_status IF NOT EXISTS FOR (o:Order) ON (o.status);

-- Index for market events by type and time.
CREATE INDEX market_event_type_timestamp IF NOT EXISTS FOR (e:MarketEvent) ON (e.type, e.g.timestamp);


/*
----------------------------------------------------------------------
-- SECTION 3: EXAMPLE DATA (MERGE PATTERNS)
--
-- This section demonstrates how to create nodes and relationships using
-- MERGE, which prevents creating duplicate nodes if they already exist.
-- This serves as living documentation for developers and ETL scripts.
----------------------------------------------------------------------
*/

-- Create Blockchains
MERGE (eth:Blockchain {name: 'Ethereum'});
MERGE (sep:Blockchain {name: 'Sepolia'});

-- Create Data Sources for Auditing
MERGE (ds_bloomberg:DataSource {name: 'Bloomberg'});
MERGE (ds_blockchain:DataSource {name: 'EthereumNode'});

-- Create Core Entities
MERGE (a_btc:Asset {ticker: 'BTC', type: 'Crypto', name: 'Bitcoin'});
MERGE (a_eth:Asset {ticker: 'ETH', type: 'Crypto', name: 'Ethereum'});
MERGE (a_aapl:Asset {ticker: 'AAPL', type: 'Equity', isin: 'US0378331005'});

MERGE (p_alpha:Portfolio {portfolioId: 'DRL-ALPHA-01', name: 'DRL Alpha Strategy', strategy: 'DeepRL-v1.2'});
MERGE (t_john:Trader {traderId: 'JDOE', name: 'John Doe'});
MERGE (acc_main:Account {accountId: 'ACC-MAIN-001', name: 'Main Trading Account'});

-- Create Blockchain Entities
MERGE (w_trader:Wallet {address: '0xTraderWalletAddress...'});
MERGE (w_exchange:Wallet {address: '0xExchangeWalletAddress...'});
MERGE (sc_aave:SmartContract {address: '0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9', name: 'AAVE Token'});

-- Create ML Model Node
MERGE (ml_ppo:MLModel {modelId: 'PPO-v1.2.3', name: 'PPO_6_layer_LSTM', parameters: '{\'lr\': 0.001}'});

-- Create Relationships
MERGE (p_alpha)-[:MANAGED_BY]->(t_john);
MERGE (t_john)-[:OPERATES_ON]->(acc_main);
MERGE (p_alpha)-[:HOLDS {weight: 0.45, entry_price: 60000, position_size: 10.5}]->(a_btc);
MERGE (sc_aave)-[:DEPLOYED_ON]->(eth);
MERGE (t_john)-[:CONTROLS]->(w_trader);

-- Example of a Market Order and its Execution
MERGE (o1:Order {orderId: 'ORD-20250823-001', type: 'MARKET', side: 'BUY', asset: 'AAPL', size: 100, timestamp: datetime(), status: 'FILLED'});
MERGE (tx1:Transaction {transactionId: 'TXN-20250823-001', price: 175.50, size: 100, fees: 1.00, timestamp: datetime()});
MERGE (t_john)-[:PLACED]->(o1);
MERGE (o1)-[:EXECUTED_AS]->(tx1);
MERGE (tx1)-[:FOR_PORTFOLIO]->(p_alpha);

-- Example of an On-Chain Transaction with Auditing
MERGE (otx1:OnChainTransaction {tx_hash: '0x...unique_tx_hash...', block_number: 18000000, timestamp: datetime(), value: 5.0, gas_used: 21000});
MERGE (otx1)-[:TRANSFER_FROM]->(w_exchange);
MERGE (otx1)-[:TRANSFER_TO]->(w_trader);
MERGE (audit_otx1:Audit {ingestion_timestamp: datetime()});
MERGE (otx1)-[:INGESTED_VIA]->(audit_otx1);
MERGE (audit_otx1)-[:SOURCED_FROM]->(ds_blockchain);

-- Example of Market Data with Auditing
MERGE (ohlcv1:OHLCV {asset_ticker: 'AAPL', timestamp: datetime(), open: 175.25, high: 176.00, low: 175.00, close: 175.50, volume: 95000000});
MERGE (audit_ohlcv1:Audit {ingestion_timestamp: datetime()});
MERGE (ohlcv1)-[:INGESTED_VIA]->(audit_ohlcv1);
MERGE (audit_ohlcv1)-[:SOURCED_FROM]->(ds_bloomberg);
MERGE (a_aapl)-[:HAS_PRICE_DATA]->(ohlcv1);

-- Example of a Technical Indicator
MERGE (indic1:Indicator {asset_ticker: 'AAPL', name: 'SMA_50', timestamp: datetime(), value: 172.80});
MERGE (a_aapl)-[:HAS_INDICATOR]->(indic1);

-- Example of a Market Event
MERGE (event1:MarketEvent {eventId: 'EVT-20250823-AAPL-01', type: 'NEWS', timestamp: datetime(), source: 'Reuters', sentiment_score: 0.85, summary: 'Apple announces new product...'});
MERGE (event1)-[:AFFECTS]->(a_aapl);

-- Example of an ML Prediction
MERGE (pred1:Prediction {timestamp: datetime(), predicted_value: 178.00, horizon: '24h'});
MERGE (pred1)-[:GENERATED_BY]->(ml_ppo);
MERGE (pred1)-[:PREDICTS_FOR]->(a_aapl);


-- End of Schema --