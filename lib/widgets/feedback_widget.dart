import 'package:flutter/material.dart';
import 'dart:async';

class FeedbackWidget extends StatefulWidget {
  final String detectedValue;
  final Function(bool isCorrect, String? actualValue) onFeedback;
  final VoidCallback onDismiss;

  const FeedbackWidget({
    super.key,
    required this.detectedValue,
    required this.onFeedback,
    required this.onDismiss,
  });

  @override
  State<FeedbackWidget> createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<FeedbackWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  Timer? _autoHideTimer;
  bool _showCorrection = false;
  String? _selectedValue;

  // Indonesian Rupiah denominations
  final List<String> _rupiahValues = [
    'Rp 1,000',
    'Rp 2,000',
    'Rp 5,000',
    'Rp 10,000',
    'Rp 20,000',
    'Rp 50,000',
    'Rp 100,000',
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start animation
    _animationController.forward();

    // Auto-hide timer (10 seconds)
    _startAutoHideTimer();
  }

  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        _dismissWidget();
      }
    });
  }

  void _dismissWidget() {
    _autoHideTimer?.cancel();
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  void _handleCorrectFeedback() {
    widget.onFeedback(true, null);
    _dismissWidget();
  }

  void _handleIncorrectFeedback() {
    setState(() {
      _showCorrection = true;
    });
    // Reset timer when showing correction
    _startAutoHideTimer();
  }

  void _submitCorrection() {
    if (_selectedValue != null) {
      widget.onFeedback(false, _selectedValue);
      _dismissWidget();
    }
  }

  @override
  void dispose() {
    _autoHideTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.deepPurpleAccent.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with detected value
            Row(
              children: [
                const Icon(
                  Icons.help_outline,
                  color: Colors.deepPurpleAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Detected: ${widget.detectedValue}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: _dismissWidget,
                  child: const Icon(
                    Icons.close,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (!_showCorrection) ...[
              // Initial feedback buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleCorrectFeedback,
                      icon: const Icon(Icons.thumb_up, size: 18),
                      label: const Text('YES'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleIncorrectFeedback,
                      icon: const Icon(Icons.thumb_down, size: 18),
                      label: const Text('NO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Correction interface
              const Text(
                'What is the correct value?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Dropdown for correction
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.deepPurpleAccent.withOpacity(0.3),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedValue,
                    hint: const Text(
                      'Select correct value',
                      style: TextStyle(color: Colors.grey),
                    ),
                    dropdownColor: const Color(0xFF2A2A2A),
                    style: const TextStyle(color: Colors.white),
                    items: _rupiahValues.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedValue = newValue;
                      });
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Submit correction button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedValue != null ? _submitCorrection : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Submit Feedback'),
                ),
              ),
            ],
            
            // Auto-hide indicator
            const SizedBox(height: 8),
            Text(
              'Auto-hide in 10s',
              style: TextStyle(
                color: Colors.grey.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
