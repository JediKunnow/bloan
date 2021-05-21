import json
import sys

truffleFile = json.load(open('build/contracts/Arbitrage.json'))

abi = truffleFile['abi']
bytecode = truffleFile['bytecode']
original_stdout = sys.stdout

with open('abi.json','a') as f:
    sys.stdout = f # Change the standard output to the file we created.
    print(abi)
    sys.stdout = original_stdout