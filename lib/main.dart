import 'package:flutter/material.dart';
import 'package:flutter_socket_io_chat_example/constants.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<types.Message> _messages = [];
  final _user = const types.User(id: '82091008-a484-4a89-ae75-a22bf8d6f3ac');
  late IO.Socket socket;
  var uuid = Uuid();

  @override
  void initState() {
    socket = IO.io(
      SERVER_URL,
      IO.OptionBuilder()
          .setTransports(['websocket']) // for Flutter or Dart VM
          .disableAutoConnect() // disable auto-connection
          .build(),
    );
    socket.connect();
    setupMessageListener();

    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Chat(
          messages: _messages,
          onSendPressed: _handleSendPressed,
          user: _user,
        ),
      );

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
        author: _user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: uuid.v1(),
        text: message.text,
        status: types.Status.delivered);

    _addMessage(textMessage); // Add message to the state

    socket.emit(
        'chat message', textMessage.toJson()); // Emit the message to the socket
  }

  /// Setup Message Listener
  /// Handling received message from the socket
  void setupMessageListener() {
    socket.on('message-receive', (data) {
      // Create the message class from the data
      final message = types.TextMessage(
        author: types.User(id: data['author']),
        id: data['id'],
        text: data['text'],
      );

      _addMessage(message); // Add Message to the state
    });
  }
}
