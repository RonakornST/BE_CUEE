import os
from dotenv import load_dotenv
from influxdb_client import InfluxDBClient, Point, Dialect
from influxdb_client.client.write_api import ASYNCHRONOUS
import paho.mqtt.client as mqtt
import time
import json
import requests
import pandas as pd

# Load environment variables from ".env"
load_dotenv()

# InfluxDB config
BUCKET = 'fullstack-influxdb' #  bucket is a named location where time series data is stored.
url = 'https://iot-group2-service1.iotcloudserve.net/'
token ='Dwj0HPIYScc1zvkB0zHpjxIVIssU_z_-unniio7sOcZl135FZ40ONj9ZX6jgiBWqkwpOQegRAL21Ix1z86SBJw=='
org = 'Chulalongkorn'
print("connecting to",url)

client = InfluxDBClient(

    url= url,
    token= token,
    org= 'Chulalongkorn'
)


write_api = client.write_api()

df = pd.read_csv('test_cases.csv')

for index, value in df['predict'].iteritems():
    # publish the data to MQTT Broker
    datastr = f"Time: {index}, Value: {value}"
    point = Point("sensor_data")\
        .field("predict")
    write_api.write(BUCKET, org, point)


for index, value in df['predict'].iteritems():
    # publish the data to MQTT Broker
    datastr = f"Time: {index}, Value: {value}"
    point = Point("sensor_data")\
        .field("predict")
    write_api.write(BUCKET, org, point)


    # result = mqttc.publish(MQTT_SUBSCRIBE_TOPIC, datastr)
    # status = result[0]
    # if status == 0:
    #     print(f"Send `{datastr}` to topic `{MQTT_SUBSCRIBE_TOPIC}`")
    # else:
    #     print(f"Failed to send message to topic {MQTT_SUBSCRIBE_TOPIC}")
