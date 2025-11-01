import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage(
                      'images/profile.png',
                    ), // ou NetworkImage
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.notifications_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text("Good morning 👋", style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              // --- Balance Card ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "\$0",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Active balance",
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "VISA",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // --- Quick Action Buttons ---
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 3.2,
                ),
                children: [
                  _quickActionButton(Icons.arrow_upward, "Top Up"),
                  _quickActionButton(Icons.send, "Send"),
                  _quickActionButton(Icons.request_page, "Request"),
                  _quickActionButton(Icons.more_horiz, "Other"),
                ],
              ),
              const SizedBox(height: 24),
              // --- Transaction History ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Transaction History",
                    style: theme.textTheme.titleMedium,
                  ),
                  TextButton(onPressed: () {}, child: const Text("View All")),
                ],
              ),
              const SizedBox(height: 16),
              // Placeholder pour l'image "No transactions"
              Center(
                child: Column(
                  children: [
                    Image.asset('images/notransaction.png', height: 120),
                    const SizedBox(height: 16),
                    const Text(
                      "No transactions yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Once you start sending or receiving money, all your activity will appear here.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionButton(IconData icon, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
