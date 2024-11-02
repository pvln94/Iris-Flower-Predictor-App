import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.lightBlue[50],
      ),
      home: IrisPredictorHome(),
    );
  }
}

class IrisPredictorHome extends StatefulWidget {
  @override
  _IrisPredictorHomeState createState() => _IrisPredictorHomeState();
}

class _IrisPredictorHomeState extends State<IrisPredictorHome> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _sepalLengthController = TextEditingController();
  final TextEditingController _sepalWidthController = TextEditingController();
  final TextEditingController _petalLengthController = TextEditingController();
  final TextEditingController _petalWidthController = TextEditingController();
  Interpreter? _interpreter;
  String _predictionResult = '';
  String _predictionImage = '';

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/iris_model.tflite');
    } catch (e) {
      setState(() {
        _predictionResult = 'Failed to load model: $e';
      });
    }
  }

  Future<void> _predict() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_interpreter == null) {
        setState(() {
          _predictionResult = 'Model not loaded yet.';
        });
        return;
      }

      double sepalLength = double.parse(_sepalLengthController.text);
      double sepalWidth = double.parse(_sepalWidthController.text);
      double petalLength = double.parse(_petalLengthController.text);
      double petalWidth = double.parse(_petalWidthController.text);

      List<List<double>> input = [[sepalLength, sepalWidth, petalLength, petalWidth]];
      var output = List.filled(3, 0.0).reshape([1, 3]);

      try {
        _interpreter!.run(input, output);

        List<double> probabilities = output[0];
        int predictedIndex = probabilities.indexOf(probabilities.reduce((a, b) => a > b ? a : b));

        List<String> flowerTypes = ['Iris-setosa', 'Iris-versicolor', 'Iris-virginica'];
        List<String> flowerImages = [
          'assets/images/Iris-setosa.png',
          'assets/images/Iris-versicolor.png',
          'assets/images/Iris-virginica.png'
        ];

        setState(() {
          _predictionResult = 'Prediction: ${flowerTypes[predictedIndex]}';
          _predictionImage = flowerImages[predictedIndex];
        });
      } catch (e) {
        setState(() {
          _predictionResult = 'Error during prediction: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Iris Flower Predictor'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Enter the Iris Flower Features',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
                SizedBox(height: 20),
                _buildTextField(_sepalLengthController, 'Sepal Length'),
                _buildTextField(_sepalWidthController, 'Sepal Width'),
                _buildTextField(_petalLengthController, 'Petal Length'),
                _buildTextField(_petalWidthController, 'Petal Width'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _predict,
                  child: Text('Predict'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,  // Change 'primary' to 'backgroundColor'
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    textStyle: TextStyle(fontSize: 18),
                  ),
                ),

                SizedBox(height: 20),
                Text(
                  _predictionResult,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                if (_predictionImage.isNotEmpty)
                  Image.asset(
                    _predictionImage,
                    height: 200,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          try {
            double.parse(value);
            return null;
          } catch (e) {
            return 'Please enter a valid number';
          }
        },
      ),
    );
  }
}
