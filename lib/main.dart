import 'package:flutter/material.dart';
import 'task.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

// Main entry point for the application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  runApp(const TaskManagerApp());
}

// TaskManagerApp is the root widget for the application.
class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp is a convenience widget that wraps a number of widgets
    // that are commonly required for material design applications. 
    return MaterialApp(
      title: 'Task Manager', // Title of the application
      theme: ThemeData(
        //Define the default theme of the app 
        primarySwatch: Colors.blue, // Primary color of the theme
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.orange, // Accent color of the theme
        ),
      ),
      home: const TaskListScreen(), // The widget that will be shown when the app starts
    );
  }
}

// A StatefulWidget that displays the list of tasks.
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  TaskListScreenState createState() => TaskListScreenState();
}

// The state associated with TaskListScreen.
class TaskListScreenState extends State<TaskListScreen> {
  // A list to hold tasks.
  List<Task> tasks = [];

  // Method to add a new task to the list.
  void _addTask(String taskName) async {
    if (taskName.isNotEmpty) {
      var uuid = Uuid();
      Task newTask = Task(id: uuid.v4(), name: taskName);
      try {
        await FirebaseFirestore.instance.collection('tasks').doc(newTask.id).set(newTask.toMap());

        // Update the UI to display the new task.
        setState(() {
          tasks.add(newTask);
        });
      } catch (e) {
        // Handle the error, eg., by showing an error message or logging the error.
        FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
        if (!mounted) return; //Check if widget is still mounted.
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Error'),
            content: Text('Failed to add the task.'),
            actions: <Widget>[
              TextButton(
                child: Text('Okay'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        );
      }
    }
  }

// Method to show a dialog for adding a new task.
void _showAddTaskDialog() {
  TextEditingController taskController = TextEditingController();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add a new task'),
      content: TextField(
        controller: taskController, // Controller for the text field
        decoration: const InputDecoration(hintText: "Enter task name"),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog without adding a task
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            _addTask(taskController.text); // Add the task when "Add" is pressed
            Navigator.of(context).pop(); // Close the dialog
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}


@override
Widget build(BuildContext context) {
  // Scaffold provides a standard layout structure of the material design app.
  return Scaffold(
    appBar: AppBar(
      title: const Text('Task Manager'), // Title displayed in the AppBar.
    ),
    // ListView.builder creates a list of items (in this case, tasks).
    body: StreamBuilder(
      stream: FirebaseFirestore.instance.collection('tasks').snapshots(), // Number of tasks
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          // Display a message or UI element indicating that an error occurred.
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        // Accessing the name property of Task object
        if (!snapshot.hasData) {
          // Show a loading indicator while the tasks are being fetched.
          return const Center(child: CircularProgressIndicator());
        }

        // Proceed with data processing and UI rendering when data is available and there's no error
        tasks = snapshot.data!.docs.map((e) => Task.fromMap(e.data() as Map<String, dynamic>)).toList();

        return ListView.builder(
          itemCount: tasks.length, // Number of tasks
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(tasks[index].name),
              );
          },
        );
      },
    ),
    // Floating action button to add a new task.
    floatingActionButton: FloatingActionButton(
      onPressed: _showAddTaskDialog, // Show the add task dialog when pressed.
      tooltip: 'Add Task', // Tooltip for the button.
      child: const Icon(Icons.add), // Icon displayed on the button.
      ),
  );
}
}