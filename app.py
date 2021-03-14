#!/usr/bin/env python3

from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/', methods=['GET'])
def total_distance():
    distance1 = request.args.get('distance1', default=0, type=float)
    distance2 = request.args.get('distance2', default=0, type=float)
    distance1_unit = request.args.get('distance1_unit', default='m', type=str)
    distance2_unit = request.args.get('distance2_unit', default='m', type=str)
    return_unit = request.args.get('return_unit', default='m', type=str)

    if distance1_unit != 'm' or distance2_unit != 'm' or return_unit != 'm':
        return jsonify(
            message = 'unit non supported',
            supported_units = 'm',
        ), 409
    
    total_distance = distance1 + distance2

    return jsonify(
        distances = [
            f"{distance1} {distance1_unit}",
            f"{distance2} {distance2_unit}",
        ],
        total_distance = f"{total_distance} {return_unit}"
    )
