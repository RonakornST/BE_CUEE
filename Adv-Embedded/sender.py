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
public_key = diffie_hellman_public_key(private_key)

# Networking
server_address = ('localhost', 12345)
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect(server_address)

try:
    # Send public key
    sock.sendall(str(public_key).encode())

    # Receive public key
    their_public_key = int(sock.recv(4096).decode())
    shared_key = diffie_hellman_shared_key(their_public_key, private_key)
    aes_key = shared_key.to_bytes((shared_key.bit_length() + 7) // 8, byteorder='big')

    # Send numbers from 1 to 25 in a loop
    count = 1
    while True:
        message = str(count)
        encrypted_message = encrypt_message(aes_key, message)
        sock.sendall(encrypted_message)
        print(f"Sent: {message}")
        
        count += 1
        if count > 25:
            count = 1

        time.sleep(1)  # Delay for 1 second between messages
finally:
    sock.close()
