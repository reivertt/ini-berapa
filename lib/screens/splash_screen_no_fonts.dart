import 'package:flutter/material.dart';
import 'package:ini_berapa/screens/home_screen.dart';

class SplashScreenNoFonts extends StatefulWidget {
  const SplashScreenNoFonts({super.key});

  @override
  State<SplashScreenNoFonts> createState() => _SplashScreenNoFontsState();
}

class _SplashScreenNoFontsState extends State<SplashScreenNoFonts>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scannerController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scannerAnimation;

  @override
  void initState() {
    super.initState();
    
    // Fade animation for the entire splash screen
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Scanner line animation (continuous loop)
    _scannerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Scanner animation from 15% to 85% and back (matching CSS)
    _scannerAnimation = Tween<double>(
      begin: 0.15,
      end: 0.85,
    ).animate(CurvedAnimation(
      parent: _scannerController,
      curve: Curves.easeInOut,
    ));

    _startSplashScreen();
  }

  _startSplashScreen() async {
    // Start fade in
    _fadeController.forward();
    
    // Wait a bit then start scanner animation
    await Future.delayed(const Duration(milliseconds: 500));
    _scannerController.repeat(reverse: true);
    
    // Wait for 3 seconds total then navigate to home
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Light gray background like CSS
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Icon Container
              Container(
                width: 256,
                height: 256,
                decoration: BoxDecoration(
                  // Radial gradient matching CSS
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF7E08FC), // Bright purple center
                      Color(0xFF37145C), // Deep purple edge
                    ],
                    center: Alignment.center,
                    radius: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(48), // iOS icon corner radius
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(48),
                  child: Stack(
                    children: [
                      // "Rp" Text in center
                      const Center(
                        child: Text(
                          'Rp',
                          style: TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            // Using system fonts instead of Inter
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Animated Scanner Line
                      AnimatedBuilder(
                        animation: _scannerAnimation,
                        builder: (context, child) {
                          return Positioned(
                            left: 0,
                            right: 0,
                            top: _scannerAnimation.value * 256, // 256 is container height
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E676), // Vivid green
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00E676),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF00E676),
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 5,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Welcome Text
              const Text(
                'Welcome to IniBerapa',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF37145C), // Deep purple to match icon
                  // Using system fonts instead of Inter
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
