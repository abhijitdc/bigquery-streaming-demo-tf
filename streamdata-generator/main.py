import random
from faker import Faker
from faker.providers import BaseProvider, geo
from google.cloud import pubsub_v1
import time
from ratelimit import limits, sleep_and_retry, RateLimitException
import datetime
import json
import os
import pandas as pd

# Initialize Faker and PubSub
fake = Faker()
fake.add_provider(geo)
publisher = pubsub_v1.PublisherClient()

#DEPRECATED

# Create a custom provider for e-commerce products
class EcommerceProvider(BaseProvider):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Load product data from CSV into a Pandas DataFrame
        self.product_data = pd.read_csv("products.csv")
        # Create a product dictionary for fast access
        self.product_dict = self._create_product_dict()

    def _create_product_dict(self):
        """Creates a dictionary for quick lookup of products by ID."""
        product_dict = {}
        for index, row in self.product_data.iterrows():
            product_dict[row["product_id"]] = row.to_dict()
        return product_dict

    def product_category(self):
        """Returns a random product category."""
        categories = self.product_data["category"].unique().tolist()
        return self.random_element(categories)

    def get_random_product_id(self, category):
      """Returns a random product_id from a category"""
      category_products = self.product_data[self.product_data["category"] == category]
      return self.random_element(category_products["product_id"].tolist())


    def product_name(self, product_id):
        """Returns a product name based on product ID."""
        if product_id in self.product_dict:
            return self.product_dict[product_id]["name"]
        else:
            return None

    def product_id(self,category):
      """Returns a random product id based on the category"""
      return self.get_random_product_id(category)

    def product_price(self, product_id):
        """Returns a product price based on product ID."""
        if product_id in self.product_dict:
            return self.product_dict[product_id]["price"]
        else:
            return None

    def product_description(self, product_id):
        """Returns a product description based on product ID."""
        if product_id in self.product_dict:
            return self.product_dict[product_id]["description"]
        else:
            return None


# Add the custom provider to Faker
fake.add_provider(EcommerceProvider)
topic_name = os.environ.get("PUBSUB_TOPIC", "fake-txn-topic")
if topic_name is None:
    raise ValueError("Please set the environment variable PUBSUB_TOPIC")

# Do the same for project id
project_id = os.environ.get("GOOGLE_CLOUD_PROJECT", "bq-agent-demo")
if project_id is None:
    raise ValueError("Please set the environment variable GOOGLE_CLOUD_PROJECT")

topic_path = publisher.topic_path(project_id, topic_name)

# Read MIN_TPS and MAX_TPS from environment variables or use defaults
MIN_TPS = int(os.environ.get("MIN_TPS", 5))
MAX_TPS = int(os.environ.get("MAX_TPS", 1500))


# Generate and publish fake transactions data using Faker Providers
def generate_transaction():
    category = fake.product_category()
    product_id = fake.product_id(category)
    # Get location data
    latitude, longitude,city,country,timezone = fake.location_on_land()
    transaction = {
        "user_id": str(random.randint(10000, 99999)),
        "order_timestamp": fake.date_time_this_year().isoformat(),
        "product_category": category,
        "product_name": fake.product_name(product_id),
        "product_id": product_id,
        "product_price": fake.product_price(product_id),
        "product_description": fake.product_description(product_id),
        "city": city,
        "country": country,
        "latitude": latitude,
        "longitude": longitude,
        "timezone": timezone,
        "payment_method": random.choice(["credit_card", "debit_card", "paypal"]),
        "status": random.choice(["pending", "completed", "failed"]),
        "currency": random.choice(["USD", "EUR", "GBP", "JPY", "CAD"]),
        "device": fake.user_agent(),
        "ip_address": fake.ipv4(),
        "user_agent": fake.user_agent(),
        # add the message creation time
        "created_at": datetime.datetime.now().isoformat(),
    }
    return transaction



def publish_message(message, current_tps):
    """Publishes a message to Pub/Sub with rate limiting."""
    @sleep_and_retry
    @limits(calls=current_tps, period=1)
    def _publish():
        future = publisher.publish(topic_path, data=message)
        # print(f"Published message ID: {future.result()}")
    _publish()


while True:
    transaction = generate_transaction()
    # Convert the transaction to JSON
    import json

    transaction_json = json.dumps(transaction)

    # send the JSON object to pubsub
    message = transaction_json.encode("utf-8")

    try:
        # Introduce randomness in TPS
        current_tps = random.randint(MIN_TPS, MAX_TPS)
        publish_message(message, current_tps)
        # print(f"Current TPS: {current_tps}") # Uncomment to see the current TPS
    except RateLimitException as e:
        print(f"Rate limit exceeded: {e}")
        time.sleep(1)  # Wait for 1 second before retrying
    except Exception as e:
        print(f"Error publishing message: {e}")
        time.sleep(1)  # Wait for 1 second before retrying