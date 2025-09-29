from Crypto.Cipher import AES
from Crypto.Util.Padding import pad
from Crypto.Random import get_random_bytes
import socket
import secrets
import time

# Diffie-Hellman parameters
PRIME = 2**521 - 1
GENERATOR = 5

def diffie_hellman_private_key():
    return secrets.randbelow(PRIME)

def diffie_hellman_public_key(private_key):
    return pow(GENERATOR, private_key, PRIME)

def diffie_hellman_shared_key(their_public_key, private_key):
    return pow(their_public_key, private_key, PRIME)

def encrypt_message(key, plaintext):
    iv = get_random_bytes(16)
    cipher = AES.new(key[:32], AES.MODE_CBC, iv)
    ciphertext = cipher.encrypt(pad(plaintext.encode(), AES.block_size))
    return iv + ciphertext

# Diffie-Hellman key exchange
private_key = diffie_hellman_private_key()
print(f"Generated private key: {private_key}")

public_key = diffie_hellman_public_key(private_key)
print(f"Generated public key: {public_key}")

# Networking
server_address = ('localhost', 12345)
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
print("Connecting to server...")
sock.connect(server_address)
print("Connected to server!")

try:
    # Send public key
    print("Sending public key to reader.py...")
    sock.sendall(str(public_key).encode())

    # Receive public key
    their_public_key = int(sock.recv(4096).decode())
    print(f"Received public key from reader.py: {their_public_key}")

    shared_key = diffie_hellman_shared_key(their_public_key, private_key)
    print(f"Computed shared key: {shared_key}")

    aes_key = shared_key.to_bytes((shared_key.bit_length() + 7) // 8, byteorder='big')
    print(f"Derived AES key (first 32 bytes): {aes_key[:32].hex()}")

    # Send numbers from 1 to 25 in a loop
    count = 1
    while True:
        message = str(count)
        encrypted_message = encrypt_message(aes_key, message)
        print(f"Encrypting message: {message}")
        print(f"Encrypted message (IV + Ciphertext): {encrypted_message.hex()}")

        sock.sendall(encrypted_message)
        print(f"Sent encrypted message: {message}")

        count += 1
        if count > 25:
            count = 1

        time.sleep(1)  # Delay for 1 second between messages
except Exception as e:
    print(f"An error occurred: {e}")
finally:
    print("Exiting sender.py...")
