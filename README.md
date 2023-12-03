# Arbitrage Bot - Optimal Path Finding

## Setup Steps
1. Create a venv for Python backend with `python -m venv arbitrage_flask_env`
2. Activate the venv with `source arbitrage_flask_env/bin/activate`
3. Install required pip packages with `pip install -r requirements.txt`
4. `cd flask_src` && start up the backend with `flask run`, the flask server is default to run on port 5000 with url of http://127.0.0.1:5000/

### flask_src
All backend algorithm logic happens here:
- Python backend to retrieve market asset pair swap price information, processed result is sent to endpoint `arbitrage-opportunities`
- Build graph to apply **Bellman-Ford Algorithm** to find the optimal negative weight cycle to detect possible arbitrage opportunities for various kinds of assets
- Implement an endpoint API that frontend can interact with to actually perform the arbitrage trading via smart contract
- Current experiment is with **UniswapV2 Queries** with **GraphQL** for swap price retrieval

### hardhat_src
All DeFi related trading behaviors happen here:
- This is where DeFi transaction happens. Once backend alogrithm is implemented, JavaScript files can use `axios` to call backend API to retrieve trading operations needed, and trigger smart contract trades
- It's the same framework as our Labs, which we are already familiar with and can ask questions if we encounter any. I believe TAs are familiar with this framework.
- Navigate to this folder and use command `npx hardhat test` to run all-in-one test in local environment



