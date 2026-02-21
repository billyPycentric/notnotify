import 'package:flutter/material.dart';
import 'package:notification_service/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService.initialize(
    onTokenReceived: (token) {
      debugPrint('TOKEN RECEIVED: $token');
    },
    onMessageReceived: (message) {
      debugPrint('FOREGROUND MESSAGE: ${message.title} - ${message.body}');
    },
    onNotificationTapped: (message) {
      debugPrint('NOTIFICATION TAPPED: ${message.title}');
      debugPrint('  route: ${message.payload.route}');
      debugPrint('  data: ${message.rawData}');
    },
    onTokenRefresh: (token) {
      debugPrint('TOKEN REFRESHED: $token');
    },
    requestPermissionOnInit: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _token = 'Loading...';
  String _permissionStatus = 'Unknown';
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final token = NotificationService.getCachedToken() ?? 'No token yet';
    final status = await NotificationService.checkPermission();
    setState(() {
      _token = token;
      _permissionStatus = status.description;
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toIso8601String().substring(11, 19)} $message');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Notification Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Permission: $_permissionStatus',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Text('Token:', style: Theme.of(context).textTheme.titleSmall),
                    SelectableText(
                      _token,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final status = await NotificationService.requestPermission();
                    _addLog('Permission: ${status.description}');
                    _loadInfo();
                  },
                  child: const Text('Request Permission'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final token = await NotificationService.getToken();
                    _addLog('Token: ${token ?? "null"}');
                    _loadInfo();
                  },
                  child: const Text('Get Token'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await NotificationService.subscribeToTopic('test');
                    _addLog('Subscribed to "test"');
                  },
                  child: const Text('Subscribe "test"'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await NotificationService.unsubscribeFromTopic('test');
                    _addLog('Unsubscribed from "test"');
                  },
                  child: const Text('Unsubscribe "test"'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final info = NotificationService.getPlatformInfo();
                    _addLog('Platform: $info');
                  },
                  child: const Text('Platform Info'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Logs', style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(_logs[index],
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
