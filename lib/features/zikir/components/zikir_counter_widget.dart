// Dosya: lib/features/zikir/components/zikir_counter_widget.dart
// Yol: C:\src\zikirmo_new\lib\features\zikir\components\zikir_counter_widget.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ZikirCounterWidget extends StatelessWidget {
  final int count;
  final int targetCount;
  final Animation<double> animation;
  final VoidCallback onTap;
  final double size;
  final bool isCompleted;
  final bool isDefaultMode;

  const ZikirCounterWidget({
    Key? key,
    required this.count,
    required this.targetCount,
    required this.animation,
    required this.onTap,
    this.size = 180.0,
    this.isCompleted = false,
    this.isDefaultMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = count / targetCount;
    final color = isDefaultMode 
        ? Colors.orange 
        : (isCompleted ? Colors.green : Theme.of(context).primaryColor);
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
                border: Border.all(
                  color: color,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // İlerleme halka göstergesi
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  
                  // Merkez içerik
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Sayaç değeri
                        Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: size * 0.15,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        
                        // Hedef bilgisi
                        Text(
                          '/ $targetCount',
                          style: TextStyle(
                            fontSize: size * 0.08,
                            color: color.withOpacity(0.7),
                          ),
                        ),
                        
                        // Default mod göstergesi
                        if (isDefaultMode) ...[
                          const SizedBox(height: 4),
                          Text(
                            'default'.tr(),
                            style: TextStyle(
                              fontSize: size * 0.06,
                              color: color.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        
                        // Tamamlanma göstergesi
                        if (isCompleted) ...[
                          const SizedBox(height: 4),
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: size * 0.1,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Tıklama ipucu
                  if (!isCompleted)
                    Positioned(
                      bottom: size * 0.15,
                      left: 0,
                      right: 0,
                      child: Text(
                        'tapToCount'.tr(),
                        style: TextStyle(
                          fontSize: size * 0.05,
                          color: color.withOpacity(0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}