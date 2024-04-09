import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PredictionPage extends StatefulWidget {
  @override
  _PredictionPageState createState() => _PredictionPageState();
}

class _PredictionPageState extends State<PredictionPage> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _collegeController = TextEditingController();
  TextEditingController _cgpaController = TextEditingController();
  TextEditingController _semesterController = TextEditingController();
  TextEditingController _courseController = TextEditingController();
  List<String> _courses = [];
  double _totalScore = 0.0;

  Future<double> _getPredictedScore(String course) async {
    try {
      // Make HTTP POST request to send course to the backend for prediction
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/predict'),
        headers: {
          'Content-Type': 'application/json', // Set Content-Type header
        },
        body: json.encode({'course': course}), // Encode request body as JSON
      );

      if (response.statusCode == 200) {
        // Parse the response body to get the predicted score
        final Map<String, dynamic> data = json.decode(response.body);
        final double predictedScore = data['predicted_score'];
        return predictedScore.toDouble(); // Convert predictedScore to double
      } else {
        // Handle errors
        print('Failed to fetch predicted score: ${response.reasonPhrase}');
        return 0.0; // Return a default value or handle the error accordingly
      }
    } catch (e) {
      // Handle network errors or other exceptions
      print('Error predicting score: $e');
      return 0.0; // Return a default value or handle the error accordingly
    }
  }

  void _calculateTotalScore() async {
    double total = 0.0;
    if (_courses.isNotEmpty) {
      // Calculate the total score for courses
      for (var course in _courses) {
        double predictedScore = await _getPredictedScore(course);
        total += predictedScore;
      }
      // Add half of the total score for courses to half of the CGPA
      total = (total * 0.5) + ((double.tryParse(_cgpaController.text) ?? 0.0) * 0.5);
    } else {
      // If no courses are entered, only consider the CGPA
      total = (double.tryParse(_cgpaController.text) ?? 0.0) * 0.5;
    }
    setState(() {
      _totalScore = total.clamp(0.0, 9.9); // Clamp total score to maximum 9.9
    });
  }

  Future<void> _addCourse(String name) async {
    try {
      // Call _getPredictedScore() to get the predicted score for the course
      double predictedScore = await _getPredictedScore(name);
      if (predictedScore != null) {
        setState(() {
          _courses.add(name);
          _calculateTotalScore();
        });
      }
    } catch (e) {
      // Handle errors
      print('Error adding course: $e');
    }
  }

  void _deleteCourse(int index) {
    setState(() {
      _courses.removeAt(index);
      _calculateTotalScore();
    });
  }

  String _getCircleText() {
    if (_cgpaController.text.isNotEmpty && double.parse(_cgpaController.text) < 6.0) {
      return 'NA';
    } else {
      return _totalScore.toStringAsFixed(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Prediction Page'),
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      // Placeholder for photo holder
                      color: Colors.grey,
                      child: Center(
                        child: Text('Photo Holder'),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Container(
                    // Progress Circle
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getCircleColor(),
                    ),
                    child: Center(
                      child: Text(
                        _getCircleText(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Divider(),
            SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Name:'),
                        SizedBox(height: 5),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter your name',
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('College:'),
                        SizedBox(height: 5),
                        TextField(
                          controller: _collegeController,
                          decoration: InputDecoration(
                            hintText: 'Enter your college',
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('CGPA:'),
                        SizedBox(height: 5),
                        TextField(
                          controller: _cgpaController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: 'Enter your CGPA',
                          ),
                          onChanged: (_) => _calculateTotalScore(),
                        ),
                        SizedBox(height: 10),
                        Text('Semester:'),
                        SizedBox(height: 5),
                        TextField(
                          controller: _semesterController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter your semester',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Courses:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _courseController,
                                decoration: InputDecoration(
                                  hintText: 'Enter course name',
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                String courseName = _courseController.text.trim();
                                if (courseName.isNotEmpty) {
                                  _addCourse(courseName);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Please enter a course name.'),
                                  ));
                                }
                                _courseController.clear();
                              },
                              child: Text('Add'),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _courses.length,
                            itemBuilder: (context, index) {
                              return Column(
                                children: [
                                  ListTile(
                                    title: Text(_courses[index]),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      _deleteCourse(index);
                                    },
                                    child: Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCircleColor() {
    if (_totalScore >= 9.0) {
      return Colors.green;
    } else if (_totalScore >= 6.0) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }
}

void main() {
  runApp(MaterialApp(
    home: PredictionPage(),
  ));
}
