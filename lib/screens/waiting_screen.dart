import 'package:camelia_logistics/models/services/AdminService.dart';
import 'package:camelia_logistics/models/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class WaitingScreen extends StatefulWidget {
  final String orderId;
  WaitingScreen({super.key, required this.orderId});

  @override
  _WaitingScreenState createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final OrderService _orderService = OrderService();
  late final AnimationController _animationController;
  final AdminService _admin = AdminService();
  final List<String> messages = [
    'veuillez patienter, nous cherchons un chauffeur...',
    'cela ne devrait pas prendre plus de quelques minutes.',
    'un de nos chauffeurs va vous contacter très bientôt !',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Durée de chaque message
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _animationController.repeat();
      }
    });

    _animationController.forward(); // Démarre l'animation
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        _admin.handlePopInvoked(didPop, context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5, //
                child: Stack(
                  children: [
                    // The Lottie animation is the background
                    SizedBox.expand(
                      child: Lottie.asset('assets/car.json', fit: BoxFit.fill),
                    ),

                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Carousel text
                          SizedBox(
                            height: 60,
                            child: PageView.builder(
                              controller: _pageController,
                              scrollDirection: Axis.vertical,
                              itemCount: messages.length * 1000,
                              itemBuilder: (context, index) {
                                final messageIndex = index % messages.length;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    messages[messageIndex],
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 30),
                          const CircularProgressIndicator(color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              _buildSummarySection(widget.orderId),
              const SizedBox(height: 20),
              _buildDriverStatusSection(),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(String orderId) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[100],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 30,
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 15),
              FutureBuilder(
                future: _orderService.getOrder(orderId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 50.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final ord = snapshot.data;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ord!.pickupAddress.toString(),

                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        ord.dropoffAddress.toString(),

                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 15),
          FutureBuilder(
            future: _orderService.getOrder(orderId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final ord = snapshot.data;
              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shopping_bag,
                      size: 30,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Colis ${ord!.packageNature.toString()}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Véhicule : ${(ord.vehicleType.toString())}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDriverStatusSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.add, color: Colors.blue),
          const SizedBox(width: 5),
          const Expanded(
            child: Text(
              '100 chauffeurs actifs',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Gérer l'appel d'urgence
              },
              icon: const Icon(Icons.phone),
              label: const Text('Urgence'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                foregroundColor: Colors.blue.shade800,
                side: BorderSide(color: Colors.blue.shade800),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Gérer l'ouverture du support
              },
              icon: const Icon(Icons.chat_bubble),
              label: const Text('Support'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                foregroundColor: Colors.purple.shade600,
                side: BorderSide(color: Colors.purple.shade600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
