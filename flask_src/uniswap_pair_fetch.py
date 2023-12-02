import requests
import json


def fetch_uniswap_top_pairs():
    url = "https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v2"
    query = """
    {
      pairs(first: 150, orderBy: reserveUSD, orderDirection: desc) {
        id
        token0 {
          id
          symbol
          decimals
        }
        token1 {
          id
          symbol
          decimals
        }
        reserve0
        reserve1
      }
    }
    """
    response = requests.post(url, json={'query': query})
    if response.status_code == 200:
        return json.loads(response.text)['data']['pairs']
    else:
        raise Exception("Query failed to run by returning code of {}. {}".format(response.status_code, query))

def extract_and_format_tokens(data, output_file_path):
    formatted_tokens = {}
    for pair in data:
        if pair['token0']['symbol'] == 'USD' or pair['token1']['symbol'] == 'USD':
            continue
        for token in ['token0', 'token1']:
            symbol = pair[token]['symbol']
            if symbol not in formatted_tokens:
                formatted_tokens[symbol] = {
                    'address': pair[token]['id'],
                    'decimals': pair[token]['decimals']
                }

    with open(output_file_path, 'w') as outfile:
        json.dump(formatted_tokens, outfile, indent=4)

def convert_pairs(pairs_data, output_file_path):
    transformed_pairs = []
    for pair in pairs_data:
        if pair['token0']['symbol'] == 'USD' or pair['token1']['symbol'] == 'USD':
            continue
        transformed_pair = {
            "pair": pair["token0"]["symbol"]+"-"+pair["token1"]["symbol"],
            "token1_symbol": pair["token0"]["symbol"],
            "token2_symbol": pair["token1"]["symbol"]
        }

        transformed_pair_inv = {
            "pair": pair["token1"]["symbol"]+"-"+pair["token0"]["symbol"],
            "token1_symbol": pair["token1"]["symbol"],
            "token2_symbol": pair["token0"]["symbol"]
        }
        transformed_pairs.append(transformed_pair)
        transformed_pairs.append(transformed_pair_inv)

    with open(output_file_path, 'w') as file:
        json.dump(transformed_pairs, file, indent=4)


import json

def calc_ratio(amountIn, reserveIn, reserveOut, decimalIn, decimalOut):
    amountInWithFee = amountIn * 997
    numerator = amountInWithFee * reserveOut
    denominator = reserveIn * 1000 + amountInWithFee
    amountOut = numerator / denominator
    return amountOut

def calculate_exchange_prices(pairs):
    results = {}
    for pair in pairs:
        if float(pair['reserve0']) > 0 and float(pair['reserve1']) > 0:
            exchange_price_token0_to_token1 = calc_ratio(1, float(pair['reserve0']), float(pair['reserve1']), int(pair['token0']['decimals']), int(pair['token1']['decimals']))
            exchange_price_token1_to_token0 = calc_ratio(1, float(pair['reserve1']), float(pair['reserve0']), int(pair['token1']['decimals']), int(pair['token0']['decimals']))
            # exchange_price_token0_to_token1 = float(pair['token1Price']) / float(pair['token0Price'])
            # exchange_price_token1_to_token0 = float(pair['token0Price']) / float(pair['token1Price'])

            results[(pair['token0']['symbol'], pair['token1']['symbol'])] = exchange_price_token0_to_token1
            results[(pair['token1']['symbol'], pair['token0']['symbol'])] = exchange_price_token1_to_token0
            print(f"Pair {pair['token0']['symbol']}/{pair['token1']['symbol']}: 1 {pair['token0']['symbol']} = {exchange_price_token0_to_token1} {pair['token1']['symbol']}, 1 {pair['token1']['symbol']} = {exchange_price_token1_to_token0} {pair['token0']['symbol']}")
    return results
