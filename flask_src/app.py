from flask import Flask, jsonify
from utils import find_arbitrage_opportunity

app = Flask(__name__)

@app.route('/arbitrage-opportunities')
def get_arbitrage_opportunities():
    path, exchange_ratio, path_protocols = find_arbitrage_opportunity('WETH')
    # Logic to retrieve arbitrage opportunities
    return jsonify({
        "optimal_path": path,
        "exchange_ratio": exchange_ratio,
        "path_protocols": path_protocols
    })

if __name__ == '__main__':
    app.run(debug=True)
