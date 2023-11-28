from flask import Flask, jsonify
from utils import find_arbitrage_opportunity

app = Flask(__name__)

@app.route('/arbitrage-opportunities')
def get_arbitrage_opportunities():
    path, exchange_ratio = find_arbitrage_opportunity('WETH')
    # Logic to retrieve arbitrage opportunities
    return jsonify({
        "optimal_path": path,
        "exchange_ratio": exchange_ratio
    })

if __name__ == '__main__':
    app.run(debug=True)
