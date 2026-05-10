import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget
{
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DashBoard"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () {},
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.menu),
          )
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔽 PROFILE SECTION
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    backgroundImage:
                    AssetImage("assets/images/user.png"),
                  ),

                  const SizedBox(width: 20),

                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        _ProfileStat(count: "174", label: "Posts"),
                        _ProfileStat(count: "1M", label: "Followers"),
                        _ProfileStat(count: "174K", label: "Following"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// 🔽 BIO SECTION
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Biraj Sharma",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Flutter Developer",
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text("250125@softwarica.edu.np"),
                  SizedBox(height: 4),
                  Text("Followed by ram and sita"),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// 🔽 BUTTONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text("Follow"),
                    ),
                  ),
                  const SizedBox(width: 6),

                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text("Message"),
                    ),
                  ),
                  const SizedBox(width: 6),

                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      child: const Text("Email"),
                    ),
                  ),
                  const SizedBox(width: 6),

                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      border: Border.all(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_drop_down),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            /// 🔽 STORY HIGHLIGHTS
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 6,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          backgroundImage:
                          AssetImage("assets/images/user.png"),
                        ),
                        const SizedBox(height: 5),
                        Text("Story $index"),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(),

            /// 🔽 POSTS GRID
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemBuilder: (context, index) {
                return Image.asset(
                  "assets/images/user.png",
                  fit: BoxFit.cover,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔽 REUSABLE WIDGET (Clean Code)
class _ProfileStat extends StatelessWidget {
  final String count;
  final String label;

  const _ProfileStat({
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(label),
      ],
    );
  }
}