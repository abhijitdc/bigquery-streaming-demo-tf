import random
from faker import Faker
from google.cloud import pubsub_v1
import time
from ratelimit import limits, sleep_and_retry, RateLimitException
import datetime

# Initialize Faker and PubSub
fake = Faker()
publisher = pubsub_v1.PublisherClient()
# Take the topic name from environment variable
import os

topic_name = os.environ.get("PUBSUB_TOPIC", "fake-txn-topic")
if topic_name is None:
    raise ValueError("Please set the environment variable PUBSUB_TOPIC")

# Do the same for project id
project_id = os.environ.get("GOOGLE_CLOUD_PROJECT", "bqstream-dademo")
if project_id is None:
    raise ValueError("Please set the environment variable GOOGLE_CLOUD_PROJECT")

topic_path = publisher.topic_path(project_id, topic_name)

# Read TPS from environemnt variable or use default
TPS = int(os.environ.get("TPS", 10))


# Generate and publish fake transactions data using Faker Providers
def generate_transaction():
    transaction = {
        "user_id": fake.uuid4(),
        "timestamp": fake.date_time_this_year().isoformat(),
        "amount": random.uniform(1.0, 1000.0),
        "item": fake.word(),
        "location": fake.city(),
        "payment_method": random.choice(["credit_card", "debit_card", "paypal"]),
        "status": random.choice(["pending", "completed", "failed"]),
        "currency": random.choice(["USD", "EUR", "GBP", "JPY", "CAD"]),
        "country": fake.country(),
        "device": fake.user_agent(),
        "ip_address": fake.ipv4(),
        "user_agent": fake.user_agent(),
        # add the message creation time
        "created_at": datetime.datetime.now().isoformat(),

    }
    return transaction


# chnage the transaction generation to a TPS based on an environment varibale provided
@sleep_and_retry
@limits(calls=TPS, period=1)
def publish_message(message):
    future = publisher.publish(topic_path, data=message)
    print(f"Published message ID: {future.result()}")
    # print(message)


while True:
    transaction = generate_transaction()
    # Convert the transaction to JSON
    import json

    transaction_json = json.dumps(transaction)

    # send the JSON object to pubsub
    message = transaction_json.encode("utf-8")

    try:
        publish_message(message)
    except RateLimitException as e:
        print(f"Rate limit exceeded: {e}")
        time.sleep(1)  # Wait for 1 second before retrying