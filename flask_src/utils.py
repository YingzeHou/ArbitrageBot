import requests
import networkx as nx
import numpy as np

def get_spot_price(asset_from, asset_to, state):
    """
    Mock function to get the spot price between two assets.

    :param asset_from: The asset being sold.
    :param asset_to: The asset being bought.
    :param state: The current market state.
    :return: The spot price between asset_from and asset_to.
    """
    return state.get((asset_from, asset_to), 1)

def calculate_revenue(path, G, state):
    """
    Calculate the revenue from executing trades along a given path.

    :param path: The arbitrage path.
    :param G: The graph representing market pairs.
    :param state: The current market state.
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

def get_negative_cycle(G):
    """
    Detect a negative cycle in the graph.

    :param G: Directed graph representing the market.
    :return: A list of nodes forming the negative cycle, if any.
    """
    cycle_dict = {}

    for node in G.nodes():
        best_cycle = None
        best_weight = 0
        if node not in cycle_dict:
            cycle_dict[node] = None

        cycles = find_all_cycles(G, node)
        for cycle in cycles:
            weight = sum(G[cycle[i]][cycle[i+1]]['weight'] for i in range(len(cycle)-1))
            if weight < best_weight:
                best_cycle = cycle
                best_weight = weight

        cycle_dict[node] = best_cycle

    print(cycle_dict)
    return cycle_dict

def negative_cycle_arbitrage_detection(N, E, state):
    """
    Main function to detect and exploit negative cycle arbitrage opportunities.

    :param N: Set of nodes (assets).
    :param E: Set of edges (market pairs).
    :param state: Initial state of the market.
    :return: A dictionary to find the optimal arbitrage result of an asset
    """
    exchange_dict = {}
    G = build_graph(N, E, state)
    cycle_dict = get_negative_cycle(G)
    
    for src in cycle_dict:
        if src[0] not in exchange_dict:
            exchange_dict[src] = 1

        path = convert_cycle_to_path(cycle_dict[src])
        revenue, ratio = calculate_revenue(path, G, state)
        print(f'{path} ratio: {ratio}')
        if ratio>exchange_dict[src]:
            exchange_dict[src] = ratio

    return exchange_dict

def fetch_1inch_exchange_prices(from_token, to_token, api_key):
    base_url = "https://api.1inch.dev/swap/v5.2/1/quote"
    headers = {
        'accept': 'application/json',
        'Authorization': f'Bearer {api_key}'
    }
    params = {
        "src": from_token,
        "dst": to_token,
        "amount": 10**6,  # Example amount, typically 1 token
        "includeTokensInfo": True,
        "includeGas": True
    }
    try:
        response = requests.get(base_url, headers=headers, params=params)
        data = response.json()
        print(data)
        if 'toAmount' in data:
            return int(data['toAmount']) / 10**18
    except requests.exceptions.RequestException as e:
        print(f"Error fetching price for pair {from_token} - {to_token}: {e}")
        return None

if __name__ == '__main__':
    N = ['USD', 'EUR', 'JPY', 'CNY']  # Example set of assets
    E = [('USD', 'EUR'), ('USD', 'CNY'), ('EUR', 'JPY'), ('CNY', 'JPY'), ('JPY', 'USD')]  # Example set of market pairs
    state = {('USD', 'EUR'): 0.9, ('USD', 'CNY'): 7.29, ('EUR', 'JPY'): 162, ('CNY', 'JPY'): 20.8, ('JPY', 'USD'): 0.008}  # Initial state (mock values)
    exchange_dict = negative_cycle_arbitrage_detection(N, E, state, 0)
    print(exchange_dict)