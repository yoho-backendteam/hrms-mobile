import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _minDisplayTimer;
  Timer? _maxTimeoutTimer;
  bool _minTimeElapsed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _initSplashFlow();
  }

  @override
  void dispose() {
    _minDisplayTimer?.cancel();
    _maxTimeoutTimer?.cancel();
    super.dispose();
  }

  void _initSplashFlow() {
    // 1. Kick off non-blocking session check
    ref.read(authControllerProvider.notifier).checkAuthSession();

    // 2. Minimum smooth splash display: 1.0s
    _minDisplayTimer = Timer(const Duration(milliseconds: 1000), () {
      _minTimeElapsed = true;
      _checkAndNavigate();
    });

    // 3. Maximum hard timeout guarantee: 2.0s
    _maxTimeoutTimer = Timer(const Duration(milliseconds: 2000), () {
      _forceNavigate();
    });
  }

  void _cancelTimers() {
    _minDisplayTimer?.cancel();
    _minDisplayTimer = null;
    _maxTimeoutTimer?.cancel();
    _maxTimeoutTimer = null;
  }

  void _checkAndNavigate() {
    if (!mounted || _navigated || !_minTimeElapsed) return;
    final authState = ref.read(authControllerProvider);
    if (authState.status == AuthStatus.authenticated) {
      _navigated = true;
      _cancelTimers();
      context.go('/dashboard');
    } else if (authState.status == AuthStatus.unauthenticated) {
      _navigated = true;
      _cancelTimers();
      context.go('/login');
    }
  }

  void _forceNavigate() {
    if (!mounted || _navigated) return;
    _navigated = true;
    _cancelTimers();
    final authState = ref.read(authControllerProvider);
    if (authState.status == AuthStatus.authenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (_minTimeElapsed && !_navigated) {
        _checkAndNavigate();
      }
    });

    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Text(
          'HRMS',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: Color(0xFFFF6D00),
            letterSpacing: 4.0,
          ),
        ),
      ),
    );
  }
}
