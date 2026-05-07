import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: AppBar(),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Image.asset("assets/images/user.png",
                height: 50,
                width: 50,
              )
            ],
          ),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 100,
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("hello")
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                  height: 100,
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("hello")
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  height: 100,
                  child: Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("hello")
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
