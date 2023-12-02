import requests
import networkx as nx
import numpy as np
import os
from dotenv import load_dotenv
import json
import time
from tqdm import tqdm
from uniswap_pair_fetch import fetch_uniswap_top_pairs, extract_and_format_tokens, convert_pairs, calculate_exchange_prices

# Load environment variables from .env file
load_dotenv()

arbitrage_path = None
arbitrage_ratio = None

def get_spot_price(asset_from, asset_to, state):
    """
    Mock function to get the spot price between two assets.

    :param asset_from: The asset being sold.
    :param asset_to: The asset being bought.
    :param state: The current market state.
    :return: The spot price between asset_from and asset_to.
    """
    return state.get((asset_from, asset_to), 1)

def calculate_revenue(path, G):
    """
    Calculate the revenue from executing trades along a given path.

    :param path: The arbitrage path.
    :param G: The graph representing market pairs.
    :return: The total revenue from executing the arbitrage path.
    """
    revenue = 0
    ratio = 1
    for i in range(len(path) - 1):
        edge = G[path[i]][path[i+1]]
        revenue += edge['weight'] 
        ratio *= np.exp(-edge['weight'])
    
    return revenue, ratio

def convert_cycle_to_path(cycle):
    """
    Convert a cycle into a trading path.

    :param cycle: A list of nodes forming a cycle.
    :return: A list of nodes forming a path.
    """
    # In this mock implementation, we just return the cycle as it is
    return cycle

def build_graph(N, E, state):
    """
    Build the directed graph from the market data.

    :param N: Set of nodes (assets).
    :param E: Set of edges (market pairs).
    :param state: Current state of the market.
    :return: A directed graph representing the market.
    """
    G = nx.DiGraph()

    for edge in E:
        # Calculate the weight of the edge based on the spot price
        spot_price = get_spot_price(edge[0], edge[1], state)
        weight = -np.log(spot_price)
        G.add_edge(edge[0], edge[1], weight=weight)

    return G

def find_all_cycles(G, source, path=[], visited=set()):
    """
    Find all cycles in the graph starting from the source node.

    :param G: Directed graph representing the market.
    :param source: The starting node for cycle search.
    :param path: The current path being explored.
    :param visited: Set of visited nodes to avoid loops.
    :return: List of all cycles starting from source.
    """
    path = path + [source]
    if len(path) > 1 and path[-1] == path[0]:
        # Found a cycle
        return [path]
    cycles = []
    for neighbor in G.neighbors(source):
        if neighbor not in visited or (len(path) > 1 and neighbor == path[0]):
            visited.add(neighbor)
            new_cycles = find_all_cycles(G, neighbor, path, visited)
            for cycle in new_cycles:
                if cycle not in cycles:
                    cycles.append(cycle)
            visited.remove(neighbor)
    return cycles

def get_negative_cycle(G, node):
    """
    Detect a negative cycle in the graph.

    :param G: Directed graph representing the market.
    :return: A list of nodes forming the negative cycle, if any.
    """
    cycle_dict = {}

    # for node in G.nodes():
    best_cycle = None
    best_weight = 0
    if node not in cycle_dict:
        cycle_dict[node] = None

    cycles = find_all_cycles(G, node)
    for cycle in cycles:
        weight = sum(G[cycle[i]][cycle[i+1]]['weight'] for i in range(len(cycle)-1))
        print(cycle, weight)
        if weight < best_weight:
            best_cycle = cycle
            best_weight = weight

    cycle_dict[node] = best_cycle
    return cycle_dict

def negative_cycle_arbitrage_detection(N, E, state, node):
    """
    Main function to detect and exploit negative cycle arbitrage opportunities.

    :param N: Set of nodes (assets).
    :param E: Set of edges (market pairs).
    :param state: Initial state of the market.
    :return: A dictionary to find the optimal arbitrage result of an asset
    """
    exchange_dict = {}
    G = build_graph(N, E, state)
    cycle_dict = get_negative_cycle(G, node)
    
    best_path = []
    for src in cycle_dict:
        if src[0] not in exchange_dict:
            exchange_dict[src] = 1

        path = convert_cycle_to_path(cycle_dict[src])
        if path:
            revenue, ratio = calculate_revenue(path, G)
            print(f'{path} ratio: {ratio}')
            if ratio>exchange_dict[src]:
                exchange_dict[src] = ratio
                best_path = path

    return exchange_dict, best_path

def fetch_price(from_token, to_token, api_key, token_dict):
    base_url = "https://api.1inch.dev/swap/v5.2/1/quote"
    headers = {'accept': 'application/json', 'Authorization': f'Bearer {api_key}'}

    params = {
        "src": token_dict[from_token]['address'],
        "dst": token_dict[to_token]['address'],
        "amount": 1*10**int(token_dict[from_token]['decimals']),  # Example amount, typically 1 token
        "protocols": 'UNISWAP_V2',
        "includeTokensInfo": True,
        "includeGas": True,
        "includeProtocols": True
    }

    try:
        response = requests.get(base_url, headers=headers, params=params)
        if response.status_code==200:
            data = response.json()
            return (from_token, to_token), (int(data['toAmount']) / (1*10**int(token_dict[to_token]['decimals']))), data['protocols'][0][0][0]['name']
        return (from_token, to_token), 0, "NOT EXIST"
    except Exception as e:
        print(f"Error with pair {from_token}-{to_token}: {e}")
        return None
    
def fetch_all_prices(token_pairs, api_key, token_dict, E):
    results = {}
    protocols = {}
    for i in tqdm(range(len(token_pairs))):
        time.sleep(1)
        pair = token_pairs[i]
        curr_dex, curr_price, dex_protocol = fetch_price(pair['token1_symbol'], pair['token2_symbol'], api_key, token_dict)
        if dex_protocol == 'NOT EXIST':
            E.remove(curr_dex)
        else:
            results[curr_dex] = curr_price
            protocols[curr_dex] = dex_protocol
    return results

def find_arbitrage_opportunity(token_to_arbitrage):
    global arbitrage_path, arbitrage_ratio
    if arbitrage_path != None:
        return arbitrage_path, arbitrage_ratio
    api_key = os.getenv('ONEINCH_PRIVATE_KEY')  # Replace with your actual API key
    if not api_key:
        raise ValueError("Private key not set in .env file")

    print('======================================= Fetch Uniswap Pairs =======================================')
    top_pairs = fetch_uniswap_top_pairs()

    print('======================================= Output Required Files =======================================')
    extract_and_format_tokens(top_pairs, "./data/uniswap_auto_tokens.json")
    convert_pairs(top_pairs, "./data/uniswap_auto_pairs.json")

    tokens = json.load(open('./data/uniswap_auto_tokens.json'))
    pairs =  json.load(open('./data/uniswap_auto_pairs.json'))

    N = []
    for token in tokens:
        N.append(token)
    
    E = []
    for pair in pairs:
        E.append((pair['token1_symbol'], pair['token2_symbol']))

    print('======================================= Initialize the Prices =======================================')
    initial_state = calculate_exchange_prices(top_pairs)
    time.sleep(1)
    print('======================================= Start Finding Arbitrage Opportunity =======================================')
    exchange_dict, best_path = negative_cycle_arbitrage_detection(N, E, initial_state, token_to_arbitrage)
    arbitrage_path = best_path
    arbitrage_ratio =  exchange_dict[token_to_arbitrage]

    best_token_path = []
    for node in best_path:
        best_token_path.append((node, tokens[node]['address'], tokens[node]['decimals']))

    arbitrage_path = best_token_path

    print('======================================= Returning to API =======================================')
    return best_token_path, exchange_dict[token_to_arbitrage]



