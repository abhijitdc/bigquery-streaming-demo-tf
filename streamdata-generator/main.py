import random
from faker import Faker
from faker.providers import BaseProvider
from google.cloud import pubsub_v1
import time
from ratelimit import limits, sleep_and_retry, RateLimitException
import datetime
import json
import os

# Initialize Faker and PubSub
fake = Faker()
publisher = pubsub_v1.PublisherClient()
# Take the topic name from environment variable


# Create a custom provider for e-commerce merchandise
class EcommerceProvider(BaseProvider):
    def merchandise_category(self):
        """Returns a random e-commerce merchandise category."""
        categories = [
            "Electronics",
            "Clothing",
            "Books",
            "Home & Garden",
            "Beauty & Personal Care",
            "Toys & Games",
            "Sports & Outdoors",
            "Groceries",
            "Jewelry",
            "Pet Supplies",
            "Automotive",
            "Handmade",
            "Office Products",
            "Health & Wellness",
            "Arts & Crafts",
        ]
        return self.random_element(categories)

    def merchandise_name(self, category=None):
        """Returns a random merchandise name, optionally within a category."""
        if category == "Electronics":
            items = [
                "Wireless Headphones",
                "Smartwatch",
                "Bluetooth Speaker",
                "Laptop",
                "Gaming Console",
                "Smartphone",
                "Tablet",
                "Camera",
                "TV",
                "Drone",
            ]
        elif category == "Clothing":
            items = [
                "T-Shirt",
                "Jeans",
                "Dress",
                "Jacket",
                "Sweater",
                "Hoodie",
                "Shoes",
                "Socks",
                "Hat",
                "Scarf",
            ]
        elif category == "Books":
            items = [
                "Novel",
                "Textbook",
                "Cookbook",
                "Biography",
                "Self-Help Book",
                "Comic Book",
                "Travel Guide",
                "Children's Book",
                "Poetry Collection",
            ]
        elif category == "Home & Garden":
            items = [
                "Couch",
                "Bed",
                "Table",
                "Chair",
                "Lamp",
                "Rug",
                "Pillow",
                "Curtains",
                "Gardening Tools",
                "Plant Pot",
            ]
        elif category == "Beauty & Personal Care":
            items = [
                "Moisturizer",
                "Shampoo",
                "Conditioner",
                "Makeup Kit",
                "Perfume",
                "Soap",
                "Toothpaste",
                "Hairbrush",
                "Sunscreen",
            ]
        elif category == "Toys & Games":
            items = [
                "Action Figure",
                "Board Game",
                "Puzzle",
                "Doll",
                "Stuffed Animal",
                "Building Blocks",
                "Remote Control Car",
                "Video Game",
            ]
        elif category == "Sports & Outdoors":
            items = [
                "Running Shoes",
                "Yoga Mat",
                "Bicycle",
                "Camping Tent",
                "Hiking Backpack",
                "Water Bottle",
                "Sports Ball",
                "Swimsuit",
            ]
        elif category == "Groceries":
            items = [
                "Cereal",
                "Milk",
                "Bread",
                "Fruit",
                "Vegetables",
                "Pasta",
                "Rice",
                "Coffee",
                "Tea",
            ]
        elif category == "Jewelry":
            items = [
                "Necklace",
                "Bracelet",
                "Ring",
                "Earrings",
                "Watch",
                "Brooch",
                "Anklet",
            ]
        elif category == "Pet Supplies":
            items = [
                "Dog Food",
                "Cat Food",
                "Dog Leash",
                "Cat Litter",
                "Pet Bed",
                "Pet Toys",
                "Fish Tank",
            ]
        elif category == "Automotive":
            items = [
                "Car Oil",
                "Tire Inflator",
                "Car Wash Soap",
                "Car Seat Cover",
                "Car Air Freshener",
            ]
        elif category == "Handmade":
            items = [
                "Handmade Pottery",
                "Knitted Scarf",
                "Hand-painted Mug",
                "Handmade Jewelry",
                "Crochet Blanket",
            ]
        elif category == "Office Products":
            items = [
                "Notebook",
                "Pen",
                "Paper",
                "Desk Organizer",
                "Stapler",
                "Printer",
                "Office Chair",
            ]
        elif category == "Health & Wellness":
            items = [
                "Vitamins",
                "Supplements",
                "Essential Oils",
                "Herbal Tea",
                "Weight Scale",
            ]
        elif category == "Arts & Crafts":
            items = ["Paint", "Paintbrushes", "Canvas", "Clay", "Sewing Kit"]

        else:
            items = [
                "Generic Product 1",
                "Generic Product 2",
                "Generic Product 3",
                "Generic Item",
                "Gadget",
            ]

        return self.random_element(items)

    def merchandise_price(self, min_price=1, max_price=1000):
        """Generate a random merchandise price"""
        return round(random.uniform(min_price, max_price), 2)

    def merchandise_description(self, category=None):
        """Returns a short description about an item."""
        if category:
            return f"This is a high quality {self.merchandise_name(category)} for the {category} category"
        else:
            return f"A generic item good for general usage"


# Add the custom provider to Faker
fake.add_provider(EcommerceProvider)
topic_name = os.environ.get("PUBSUB_TOPIC", "fake-txn-topic")
if topic_name is None:
    raise ValueError("Please set the environment variable PUBSUB_TOPIC")

# Do the same for project id
project_id = os.environ.get("GOOGLE_CLOUD_PROJECT", "bqworkflow-dademo")
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
        "merchandise_category": fake.merchandise_category(),
        "merchandise_name": fake.merchandise_name(fake.merchandise_category()),
        "merchandise_price": fake.merchandise_price(),
        "merchandise_description": fake.merchandise_description(
            fake.merchandise_category()
        ),
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
