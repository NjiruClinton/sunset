import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mysql1/mysql1.dart';



void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TicketingScreen(),
  ));
}


// var settings = new ConnectionSettings(
//     host: 'localhost',
//     port: 3306,
//     user: 'bob',
//     password: 'wibble',
//     db: 'mydb'
// );
// var conn = await MySqlConnection.connect(settings);
Future getData() async {
  final conn = await MySqlConnection.connect(ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'clinton',
      db: 'testdb',
      password: 'root'));

  // Create a table
  var results = await conn.query('SELECT * FROM customers');

  return conn;
}


Future Ticketing() async{
  final connect = await getData();
  var resulting = await connect.query('SELECT * FROM customers');
  List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(resulting.map((row) {
    return {
      "id": row[0],
      "name": row[1],
      "age": row[2],
      "address": row[3],
      "salary": row[4],
    };
  }));



  print(data);
  return data;
}



class TicketingScreen extends StatefulWidget {
  @override
  _TicketingScreenState createState() => _TicketingScreenState();
}

class _TicketingScreenState extends State<TicketingScreen> {
  List<Map<String, dynamic>> _ticketData = [];

  @override
  void initState() {
    super.initState();
    _getTicketData();
  }

  Future<void> _getTicketData() async {
    List<Map<String, dynamic>> ticketData = await Ticketing();
    setState(() {
      _ticketData = ticketData;
    });
  }

  Future<void> _deleteTicket(int id) async {
    final connect = await getData();
    await connect.query('DELETE FROM customers WHERE id=$id');
    _getTicketData();
  }

  Future<void> _editTicket(int id) async {
    // Get the ticket data for the selected ticket ID
    Map<String, dynamic> selectedTicket = _ticketData.firstWhere(
          (ticket) => ticket['id'] == id,
    );

    // Set up a text controller for the edit form fields
    final nameController = TextEditingController(text: selectedTicket['name']);
    final ageController = TextEditingController(text: selectedTicket['age'].toString());
    final addressController = TextEditingController(text: selectedTicket['address']);
    final salaryController = TextEditingController(text: selectedTicket['salary'].toString());

    // Show a dialog box for editing the ticket data
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Ticket'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                ),
              ),
              TextField(
                controller: ageController,
                decoration: InputDecoration(
                  labelText: 'Age',
                ),
              ),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                ),
              ),
              TextField(
                controller: salaryController,
                decoration: InputDecoration(
                  labelText: 'Salary',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Update the selected ticket data with the edited data
                selectedTicket['name'] = nameController.text;
                selectedTicket['age'] = int.parse(ageController.text);
                selectedTicket['address'] = addressController.text;
                selectedTicket['salary'] = double.parse(salaryController.text);

                await updateTicket(selectedTicket);

                setState(() {});

                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }
  Future<void> updateTicket(Map<String, dynamic> ticketData) async {
    final connect = await getData();
    final id = ticketData['id'];
    final name = ticketData['name'];
    final age = ticketData['age'];
    final address = ticketData['address'];
    final salary = ticketData['salary'];
    await connect.query('UPDATE customers SET name="$name", age=$age, address="$address", salary=$salary WHERE id=$id');
  }

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _salaryController = TextEditingController();

  Future<void> _addTicket() async {
    // Show a dialog box for adding new ticket data
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Add Ticket'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(hintText: 'Name'),
                ),
                TextField(
                  controller: _ageController,
                  decoration: InputDecoration(hintText: 'Age'),
                ),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(hintText: 'Address'),
                ),
                TextField(
                  controller: _salaryController,
                  decoration: InputDecoration(hintText: 'Salary'),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Save'),
                onPressed: () async {
                  // Get the input data from the text controllers
                  // random id integer between 1 and 100
                  final id = Random().nextInt(100) + 1;
                  final name = _nameController.text;
                  final age = int.tryParse(_ageController.text) ?? 0;
                  final address = _addressController.text;
                  final salary = int.tryParse(_salaryController.text) ?? 0;

                  // Insert the new data into the database
                  final connect = await getData();
                  await connect.query(
                      'INSERT INTO customers (id, name, age, address, salary) VALUES ("$id", "$name", $age, "$address", $salary)');

                  // Update the ticket data and dismiss the dialog box
                  await _getTicketData();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:   FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: (){
          Ticketing();
        },
      ),
      appBar: AppBar(
        title: Text('Ticketing System'),
        actions: [
          IconButton(
            onPressed: _addTicket, // Call the _addTicket function on press
            icon: Icon(Icons.add),
          )
        ],
      ),
      body: SizedBox(
        height: double.infinity,
        child: _ticketData.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: _ticketData.length,
          itemBuilder: (BuildContext context, int index) {
            final ticket = _ticketData[index];
            return ListTile(
              title: Text(ticket['name']),
              subtitle: Text(ticket['address']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => _editTicket(ticket['id']),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteTicket(ticket['id']),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

