from flask import Flask, render_template
import threading
import os

app = Flask(__name__)

@app.route('/')
def index():
    return render_template("index.html")

def run_flask_app():
    app.run(port=3000)

def run_script(script_name):
    os.system(f"python {script_name}")

if __name__ == "__main__":
    # Lancer le serveur Flask dans un thread
    flask_thread = threading.Thread(target=run_flask_app)
    flask_thread.start()

    # Lancer receive_file.py dans un autre thread
    receive_file_thread = threading.Thread(target=run_script, args=("python/receive_file.py",))
    receive_file_thread.start()

    # Lancer send_key.py dans un autre thread
    send_key_thread = threading.Thread(target=run_script, args=("python/send_key.py",))
    send_key_thread.start()
