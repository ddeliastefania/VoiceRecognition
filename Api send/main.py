from flask import Flask, url_for, request, render_template, send_from_directory,jsonify
from markupsafe import escape
from werkzeug.utils import secure_filename, redirect
from search import mp3Save
from O_Coloana import Adresa
import pathlib
import os
import mysql.connector

app = Flask(__name__)

@app.route('/')
def index():

    for root, dirs, files in os.walk(".", topdown=False):
        for name in files:
            print(os.path.join(root, name))
        for name in dirs:
            print(os.path.join(root, name))
    return 'Index Page'
@app.route('/location', methods=['GET','POST'])
def get_location():
    #aici trimiti string
    return request.form['location']

@app.route('/upload', methods=['POST'])
def upload_file():
    # primesc fisiere mp3
    if request.method == 'POST':
        # Audio e cheia(key) dupa care se identifica fisierul pe care vrem sa il uploadam
        f = request.files['Audio']
        # uploads e fisierul in care vrem sa descarcam noul fisier,
        # iar secure_... e pentu a pastra denumirea fisierului
        f.save('uploads/' + secure_filename(f.filename))
        return "Succes"
    return "Failure"

@app.route('/download', methods=['GET'])
def download_file():
    #trimit fisiere mp3
    if request.method == 'GET':
        #downloads e path-ul de unde isi ia fisierele iar "Bad_W...." e fisierul din folder
        return send_from_directory('downloads', 'Bad_Wolves_-_Zombie_lyrics.mp3', as_attachment=True)
    return "Failure"

@app.route('/communicate', methods=['POST', 'GET'])
def communicate():
    if request.method == 'POST':
        # Audio e cheia(key) dupa care se identifica fisierul pe care vrem sa il uploadam
        f = request.files['Audio']
        # uploads e fisierul in care vrem sa descarcam noul fisier,
        # iar secure_... e pentu a pastra denumirea fisierului
        print(secure_filename(f.filename))
        f.save('uploads/' + secure_filename(f.filename))
        output = mp3Save("uploads/mesaj.wav")
        print(output)
        # output = 'intrebare1.mp3'
        return 'Success!'
        # return redirect(url_for('uploaded_file',
        #                         filename=secure_filename(f.filename)))
    if request.method == 'GET':
        return send_from_directory('', 'output.mp3', as_attachment=True)
    return "Failure"

@app.route('/send_location',methods=['POST'])
def send_location():
    json_data = request.json
    #print(json_data,'asta')
    longitudine = json_data['longitudine']
    latitudine = json_data['latitudine']
    coordinate = latitudine + ', ' + longitudine
    retValue = Adresa(coordinate)
    print(retValue)
    return coordinate




if __name__ == '__main__':
    app.run(debug=True)

