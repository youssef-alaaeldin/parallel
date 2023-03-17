import numpy as np
import cv2
from matplotlib import pyplot as plt
from multiprocessing import Pool, cpu_count
import time
from flask import Flask, jsonify, request
import base64
import json


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

    

if __name__ == '__main__':
    start_time = time.time()
    img = cv2.imread('C:/Users/pc/Desktop/Paralle Histogram Equalization/einstein.jpg')
    num_cores = cpu_count()
    print("num cores" , num_cores)
    rows_per_chunk = img.shape[0] // num_cores
    print(img.shape[0])
    img_chunks = [img[i:i+rows_per_chunk] for i in range(0, img.shape[0], rows_per_chunk)]
    #send chunks to cores to work on 
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
    print(equalized_img)
    histogram = np.concatenate(histograms)
    equalized_histogram = np.concatenate(equalized_histograms)

    end_time = time.time()

    timeTaken = end_time - start_time
    print("Time taken by the Parallel Histogram Equalization code: ",  timeTaken, "seconds")

   
   
    plt.subplot(2, 2, 1)
    plt.imshow(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    plt.title('Original Image')

    plt.subplot(2, 2, 2)
    plt.plot(histogram)
    plt.title('Histogram of Original Image')

    plt.subplot(2, 2, 3)
    plt.imshow(equalized_img, cmap='gray')
    plt.title('Equalized Image')

    plt.subplot(2, 2, 4)
    plt.plot(equalized_histogram)
    plt.title('Equalized Histogram')

    plt.show()
    cv2.imwrite("LaraNew.jpeg", equalized_img)
