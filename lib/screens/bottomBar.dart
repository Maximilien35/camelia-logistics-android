import 'package:flutter/material.dart';

class CustomBottomBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const CustomBottomBar({
    required this.selectedIndex,
    required this.onItemTapped,
    super.key,
  });

  @override
  _CustomBottomBarState createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  final List<IconData> _icons = [
    Icons.home,
    Icons.unarchive,
    Icons.history,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // La barre de navigation courbée en arrière-plan
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 70, // Hauteur de la barre
            decoration: const BoxDecoration(
              color: Colors.purpleAccent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_icons.length, (index) {
                // On cache l'icône si elle est sélectionnée pour ne pas la dupliquer
                if (index == widget.selectedIndex) {
                  return const SizedBox(width: 40);
                }
                return IconButton(
                  icon: Icon(_icons[index], color: Colors.white, size: 28),
                  onPressed: () => widget.onItemTapped(index),
                );
              }),
            ),
          ),
        ),
        // L'icône flottante sélectionnée
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          top: -25, // Position haute
          left: _getFloatingIconPosition(widget.selectedIndex),
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () => widget.onItemTapped(widget.selectedIndex),
            child: Icon(_icons[widget.selectedIndex], color: Colors.black),
          ),
        ),
      ],
    );
  }

  // Calcule la position horizontale de l'icône flottante
  double _getFloatingIconPosition(int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconWidth = screenWidth / _icons.length;
    return (index * iconWidth) +
        (iconWidth / 2) -
        28; // 28 est la moitié de la taille du bouton
  }
}
