import time
from web3 import Web3
import json
import threading
from fastapi import FastAPI, HTTPException, Query

app = FastAPI()
web3 = Web3(Web3.HTTPProvider("https://base-mainnet.g.alchemy.com/v2/DgCC_Y9VlT6v0mEB3D8IxmtFQXbdGBZq"))

if web3.is_connected():
    print("Connected to Ethereum node")
else:
    raise ConnectionError("Failed to connect to Ethereum node")

contract_address = "0xeA87ae93Fa0019a82A727bfd3eBd1cFCa8f64f1D"

with open("abi.json", "r") as abi_file:
    contract_abi = json.load(abi_file)

contract = web3.eth.contract(address=contract_address, abi=contract_abi)

event_signature_hash = "0x788dbc1b7152732178210e7f4d9d010ef016f9eafbe66786bd7169f56e0c353a"

events_file = "events.json"

def handle_event(event):
    print(event["topics"][1].hex())
    try:
        with open(events_file, "r") as file:
            events = json.load(file)
    except FileNotFoundError:
        events = []

    events.append(event["topics"][1].hex())
    
    with open(events_file, "w") as file:
        json.dump(events, file, indent=4)

def log_loop(event_filter, poll_interval):
    while True:
        for event in event_filter.get_new_entries():
            handle_event(event)
        time.sleep(poll_interval)

def start_event_listener():
    from_block = "latest"
    event_filter = web3.eth.filter({
        "fromBlock": from_block,
        "toBlock": "latest",
        "address": contract_address,
    })
    print(f"Listening for dispatchId events...")
    try:
        log_loop(event_filter, 2)
    except KeyboardInterrupt:
        print("Stopped listening for events")


@app.get("/check-event")
async def check_event(tx_id: str = Query(..., description="Transaction ID to check in events")):
    try:
        with open("events.json", "r") as file:
            events = json.load(file)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="No events have been stored yet")

    for event in events:
        if tx_id in event["topics"]:
            return {"found": True, "event": event}

    return {"found": False, "message": "Transaction ID not found in events"}

start_event_listener()