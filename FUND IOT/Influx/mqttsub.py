"""
Consumer File
Listen to the subscribed topic, store data in the database, 
and feed streaming data to the real-time prediction algorithm.
"""

# Importing relevant modules
import os
from dotenv import load_dotenv
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import ASYNCHRONOUS
import paho.mqtt.client as mqtt
import json
import requests


 
# MQTT broker config
MQTT_BROKER_URL = "172.20.10.3"
MQTT_PUBLISH_TOPIC = "@msg/sensor2broker"
print("connecting to MQTT Broker", MQTT_BROKER_URL)
mqttc = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
mqttc.connect(MQTT_BROKER_URL,1883)

# REST API endpoint for predicting output ->>>> dashboard
predict_url = os.environ.get('PREDICT_URL')
 
def on_connect(client, userdata, flags, rc, properties):
    """ The callback for when the client connects to the broker."""
    print("Connected with result code "+str(rc))
 
# Subscribe to a topic
mqttc.subscribe(MQTT_PUBLISH_TOPIC)
 
def on_message(client, userdata, msg):
    """ The callback for when a PUBLISH message is received from the server."""
    print(msg.topic+" "+str(msg.payload))

    # Write data in InfluxDB
    #payload = json.loads(msg.payload) ###### this line make bug with our sensor data format
    #write_to_influxdb(payload)

    # POST data to predict the output label
    #json_data = json.dumps(payload)
    #post_to_predict(json_data)


## MQTT logic - Register callbacks and start MQTT client
mqttc.on_connect = on_connect
mqttc.on_message = on_message
mqttc.loop_forever()