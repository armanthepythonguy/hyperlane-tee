import json
from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import PlainTextResponse, JSONResponse
from evidence_api.tdx.quote import TdxQuote, AttestationKeyType, TeeType, TdxQuoteTeeTcbSvn, TdxQuoteTeeTcbSvn, TdxQuoteTeeTcbSvn, TdxQuoteTeeTcbSvn
from dstack_sdk import AsyncTappdClient
import hashlib
from typing import Union

app = FastAPI()

def sha384_hex(input: Union[str, bytes]) -> str:
    if isinstance(input, str):
        input = input.encode()
    return hashlib.sha384(input).hexdigest()

@app.get("/check-event")
async def check_event(tx_id: str = Query(..., description="Transaction ID to check in events")):

    client = AsyncTappdClient()

    try:
        with open("events.json", "r") as file:
            events = json.load(file)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="No events have been stored yet")

    payload = "false"

    if tx_id in events:
            payload = tx_id


    quoted = await client.tdx_quote(payload)

    print(payload, hashlib.sha512(bytes.fromhex(hashlib.sha384(payload.encode()).hexdigest())).hexdigest(), quoted.quote.encode())

    return JSONResponse(content={"quote": str(quoted.quote.encode())})
