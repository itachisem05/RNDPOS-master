import 'package:flutter/material.dart';

class UnderDevelopmentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:
      Stack(
      children: <Widget>[
        Container(
        width: double.infinity,
        height: 200,
        margin: EdgeInsets.fromLTRB(20, 20, 20, 10),
        padding: EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border.all(
              color: Color.fromARGB(255, 51, 204, 255), width: 1),
          borderRadius: BorderRadius.circular(5),
          shape: BoxShape.rectangle,
        ),
      ),
      Positioned(
        left: 50,
        top: 12,
        child: Container(
          padding: EdgeInsets.only(bottom: 10, left: 10, right: 10),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Create an account',
                style: TextStyle(color: Colors.black, fontSize: 12),
              ),
              SizedBox(height: 10), // Add spacing between text and dropdown
              DropdownButton<String>(
                hint: Text('Select an option'),
                items: <String>['Option 1', 'Option 2', 'Option 3']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  // Handle dropdown value change here
                },
              ),
            ],
          ),
        ),
      ),
      ],
    )
      ),
    );
  }
}

