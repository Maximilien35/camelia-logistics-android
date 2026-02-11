import 'package:flutter/material.dart';

class ModifInfo extends StatelessWidget {
  const ModifInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:const Text(
          'Modifier vos informations',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon:const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding:const EdgeInsets.all(20),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Nom Complet",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    //controller: controller, // Utilisez le contrôleur passé en argument
                    decoration: InputDecoration(
                      hintText: "modifier votre nom",
                      prefixIcon:const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                 const SizedBox(height: 10),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Telephone",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    //controller: controller, // Utilisez le contrôleur passé en argument
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '6 xx xx xx xx',
                      prefixIcon:const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Email",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                 const SizedBox(height: 10),
                  TextFormField(
                    readOnly: true,
                   
                    decoration: InputDecoration(
                      hintText: 'mail',
                      prefixIcon:const Icon(Icons.mail),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                 const SizedBox(height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
