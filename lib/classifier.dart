import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class Classifier {
  Interpreter _interpreter;
  List<String> _labelList;

  Classifier() {
    _loadModel();
    _loadLabel();
  }

  void _loadModel() async {
    _interpreter = await Interpreter.fromAsset('us_products_V1_1.tflite');

    var inputShape = _interpreter.getInputTensor(0).shape;
    var outputShape = _interpreter.getOutputTensor(0).shape;

    print('Load Model - $inputShape / $outputShape');
  }

  void _loadLabel() async {
    final labelData =
        await rootBundle.loadString('assets/us_products_V1_1.txt');
    final labelList = labelData.split('\n');
    _labelList = labelList;

    print('Load Label');
  }

  Future<img.Image> loadImage(String imagePath) async {
    var originData = File(imagePath).readAsBytesSync();
    var originImage = img.decodeImage(originData);

    return originImage;
  }

  Future<List<dynamic>> runModel(img.Image loadImage) async {
    var modelImage = img.copyResize(loadImage, width: 224, height: 224);
    var modelInput = imageToByteListUint8(modelImage, 224);

    //[1, 100000]
    var outputsForPrediction = [List.generate(100000, (index) => 0.0)];

    _interpreter.run(modelInput.buffer, outputsForPrediction);


    Map<int, double> map = outputsForPrediction[0].asMap();
    var sortedKeys = map.keys.toList()
      ..sort((k1, k2) => map[k2].compareTo(map[k1]));

    List<dynamic> result = [];

    for (var i = 0; i < 10; i++) {
      result.add({
        'label': _labelList[sortedKeys[i]],
        'value': map[sortedKeys[i]],
      });
    }

    return result;
  }

  Uint8List imageToByteListUint8(img.Image image, int inputSize) {
    var convertedBytes = Uint8List(1 * inputSize * inputSize * 3);
    var buffer = Uint8List.view(convertedBytes.buffer);

    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = img.getRed(pixel);
        buffer[pixelIndex++] = img.getGreen(pixel);
        buffer[pixelIndex++] = img.getBlue(pixel);
      }
    }
    return convertedBytes.buffer.asUint8List();
  }
}
