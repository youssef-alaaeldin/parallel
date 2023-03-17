import numpy as np
import cv2
from matplotlib import pyplot as plt
from multiprocessing import Pool, cpu_count
import time
from flask import Flask, jsonify, request
import base64
import json

app = Flask(__name__)

def histogram_equalization(img_chunk):
    original_img = cv2.cvtColor(img_chunk, cv2.COLOR_BGR2GRAY)
    r, c = original_img.shape
    histogram = np.zeros((256,), dtype=int)

    for i in range(r):
        for j in range(c):
            z = original_img[i, j]
            histogram[z] += 1

    histogram = histogram / (r * c)

    transfer_function = np.zeros((256,), dtype=float)
    sum = 0
    for i in range(len(histogram)):
        a = histogram[i]
        if i == 0:
            sum = a
        else:
            j = i - 1
            b = transfer_function[j]
            sum = a + b
        transfer_function[i] = sum

    histo_image = transfer_function * 255
    equalized_img = np.zeros((r, c), dtype=int)
    for i in range(r):
        for j in range(c):
            equalized_img[i, j] = histo_image[original_img[i, j]]

    equalized_histogram = np.zeros((256,), dtype=int)
    for i in range(r):
        for j in range(c):
            z = equalized_img[i, j]
            equalized_histogram[z] += 1

    return equalized_img, histogram, equalized_histogram

@app.route('/', methods=['GET' , 'POST'])
def index():
    # decode base64 encoded image string
    img_str = request.json['img']
    img_decoded = base64.b64decode(img_str)
    
    # convert image string to numpy array
    nparr = np.frombuffer(img_decoded, np.uint8)
    img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
    
    # perform histogram equalization in parallel
    num_cores = cpu_count()
    rows_per_chunk = img.shape[0] // num_cores
    img_chunks = [img[i:i+rows_per_chunk] for i in range(0, img.shape[0], rows_per_chunk)]
    with Pool(num_cores) as p:
        results = p.map(histogram_equalization, img_chunks)

    equalized_imgs = []
    histograms = []
    equalized_histograms = []
    for result in results:
        equalized_imgs.append(result[0])
        histograms.append(result[1])
        equalized_histograms.append(result[2])

    equalized_img = np.concatenate(equalized_imgs)
    histogram = np.concatenate(histograms)
    equalized_histogram = np.concatenate(equalized_histograms)

    # convert equalized image to base64 encoded string
    _, buffer = cv2.imencode('.jpg', equalized_img)
    equalized_img_str = base64.b64encode(buffer).decode()
    
    global response
    if(request.method == 'POST'):
        request_data = request.data
        request_data = json.loads(request_data.decode('utf-8'))
        
    # return equalized image and histogram as JSON response
    responses = {
        'equalized_img': equalized_img_str,
        'histogram': histogram.tolist(),
        'equalized_histogram': equalized_histogram.tolist()
    }
    return jsonify(responses)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
