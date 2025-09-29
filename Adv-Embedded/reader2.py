from Crypto.Cipher import AES
from Crypto.Util.Padding import unpad
import socket
import secrets

# Diffie-Hellman parameters
PRIME = 2**521 - 1
GENERATOR = 5

def diffie_hellman_private_key():
    return secrets.randbelow(PRIME)

def diffie_hellman_public_key(private_key):
    return pow(GENERATOR, private_key, PRIME)

def diffie_hellman_shared_key(their_public_key, private_key):
    return pow(their_public_key, private_key, PRIME)

def decrypt_message(key, ciphertext):
    iv = ciphertext[:16]
    cipher = AES.new(key[:32], AES.MODE_CBC, iv)
    plaintext = unpad(cipher.decrypt(ciphertext[16:]), AES.block_size)
    return plaintext.decode()

# Diffie-Hellman key exchange
private_key = diffie_hellman_private_key()
print(f"Generated private key: {private_key}")

public_key = diffie_hellman_public_key(private_key)
print(f"Generated public key: {public_key}")

# Networking
server_address = ('localhost', 12345)
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind(server_address)
sock.listen(1)

print("Waiting for a connection...")
connection, client_address = sock.accept()
print(f"Connection established with {client_address}!")

try:
    # Receive public key
    their_public_key = int(connection.recv(4096).decode())
    print(f"Received public key from sender.py: {their_public_key}")

    print("Sending public key to sender.py...")
    connection.sendall(str(public_key).encode())

    shared_key = diffie_hellman_shared_key(their_public_key, private_key)
    print(f"Computed shared key: {shared_key}")

    aes_key = shared_key.to_bytes((shared_key.bit_length() + 7) // 8, byteorder='big')
    print(f"Derived AES key (first 32 bytes): {aes_key[:32].hex()}")

    # Continuously receive and decrypt messages
    while True:
        encrypted_message = connection.recv(4096)
        if not encrypted_message:
            continue
        
        print(f"Received encrypted message (IV + Ciphertext): {encrypted_message.hex()}")
        decrypted_message = decrypt_message(aes_key, encrypted_message)
        print(f"Decrypted message: {decrypted_message}")
except Exception as e:
    print(f"An error occurred: {e}")
finally:
    print("Exiting reader.py...")
