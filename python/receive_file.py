import os
import socket
import re

def sanitize_file_path(file_path):
    """ Replace slashes with underscores and remove leading underscores. """
    return re.sub(r'^_+', '', file_path.replace('/', '_'))

def create_file_in_directory(directory, file_name, content):
        """ Create a file with given content in the specified directory. """
        file_name = file_name.split('\0')[0]
        os.makedirs(directory, exist_ok=True)
        file_path = os.path.join(directory, file_name)
        with open(file_path, 'wb') as file:
            file.write(content)

# Server settings
host = '0.0.0.0'  # Listening on all interfaces
port = 12345      # Non-privileged port

# Creating a socket
with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
    s.bind((host, port))
    s.listen()

    while True:
        print("Waiting for a connection for file path...")
        conn, addr = s.accept()
        client_ip = addr[0]
        #print(f"Connected to {addr} for file path")

        # First connection - Receive the file path
        file_path = conn.recv(1024).decode('utf-8')
        sanitized_path = sanitize_file_path(file_path)
        #print(f"File path received: {file_path}")
        conn.close()

        #print("Waiting for a connection for file content...")
        conn, addr = s.accept()
        #print(f"Connected to {addr} for file content")

        # Second connection - Receive the file content
        try:
            file_content = conn.recv(999999)
            #print(f"File content received")

            # Create folder and file
            create_file_in_directory(client_ip, sanitized_path, file_content)
            #print(f"File saved: {client_ip}/{sanitized_path}")
            conn.close()
        except:
            #print("error, skipping")
            continue
