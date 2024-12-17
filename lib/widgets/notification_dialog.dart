import 'package:flutter/material.dart';

class NotificationDialog extends StatelessWidget {
  final List<Map<String, String>> notifications;

  const NotificationDialog({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Notifications',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      content: notifications.isEmpty
          ? const Text('You have no new notifications.')
          : SizedBox(
              width: double.maxFinite,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: notifications.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return ListTile(
                    title: Text(
                      notification['title']!,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(notification['body']!),
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
