import requests


def send_to_ts(data):
    url = 'http://192.168.37.145:41752/python'
    requests.post(url, json=data)