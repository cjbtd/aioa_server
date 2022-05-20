from typing import Any


# import json
# import base64
#
# encoding = 'utf-8'
#
#
# def encrypt(data: Any) -> str:
#     return base64.encodebytes(json.dumps([data]).encode(encoding)).decode(encoding)[::-1]
#
#
# def decrypt(data: str) -> Any:
#     return json.loads(base64.decodebytes(data[::-1].encode(encoding)))[0]


def encrypt(data: Any) -> Any:
    return data


def decrypt(data: Any) -> Any:
    return data
