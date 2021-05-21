from brownie import network, web3, Contract
import json

class Arbitrage:

    def __init__(self):
        self.abi, self.bytecode = self.get_abi('build/contracts/Arbitrage.json')

    def get_abi(file):
        truffleFile = json.load(open('build/contracts/Arbitrage.json'))

        abi = truffleFile['abi']
        bytecode = truffleFile['bytecode']
        return abi,bytecode

    def do_arbitrage(self, token0, token1, amount0, amount1):
        if not token0 or not token1 or not amount0 or not amount1:
            return -1 # Invalid parameters
        
        try:
            # Connect Brownie to bsc network
            if not network.is_connected():
                network.connect('bsc-main')

            if not self.abi:
                return -2 # Invalid ABI

            arbiter = Contract.from_abi(self.asset.name, self.asset.address, self.abi)
            arbiter.startArbitrage(token0,token1,amount0,amount1)
            print("Arbitrage Called.")
            return 0
        except Exception:
            return -3 # General Exception

if __name__ == "__main__":

    token_1 = "" # address
    amount_1 = 0

    token_2 = "" # address
    amount_2 = 0

    arbiter = Arbitrage()
    arbiter.do_arbitrage(token_1, token_2, amount_1, amount_2)