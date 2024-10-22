import hashlib

def generate_hashes(word):
    hashes = {
        'MD5': hashlib.md5(word.encode()).hexdigest(),
        'SHA-1': hashlib.sha1(word.encode()).hexdigest(),
        'SHA-256': hashlib.sha256(word.encode()).hexdigest(),
        'SHA-512': hashlib.sha512(word.encode()).hexdigest(),
    }
    return hashes

# Get user input
word = input("Enter your word: ")

# Generate and print hashes
hashes = generate_hashes(word)
for hash_type, hash_value in hashes.items():
    print(f"{hash_type}: {hash_value}")
