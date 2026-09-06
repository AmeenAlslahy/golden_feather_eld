// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart';
// import '../../../../core/extensions/context_extensions.dart';
// import '../../../../core/theme/app_colors.dart';
// import '../../../../core/theme/app_spacing.dart';
// import '../../../../core/theme/app_theme.dart';
// import '../../../../core/widgets/app_button.dart';
// import '../../../../core/widgets/app_text_field.dart';
// import '../providers/auth_state_provider.dart';

// class RegisterPage extends ConsumerStatefulWidget {
//   const RegisterPage({super.key});

//   @override
//   ConsumerState<RegisterPage> createState() => _RegisterPageState();
// }

// class _RegisterPageState extends ConsumerState<RegisterPage> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   void _submit() async {
//     if (!_formKey.currentState!.validate()) return;

//     final success = await ref.read(authStateProvider.notifier).register(
//           name: _nameController.text.trim(),
//           email: _emailController.text.trim(),
//           password: _passwordController.text,
//         );

//     if (success && mounted) {
//       context.goNamed('home');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authState = ref.watch(authStateProvider);
//     final isLoading = authState.status == AuthStatus.loading;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('إنشاء حساب جديد'),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(AppSpacing.screenPadding),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 const SizedBox(height: AppSpacing.xl),
//                 Text(
//                   'التسجيل كسائق جديد',
//                   style: AppTextStyles(context).pageTitle,
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: AppSpacing.xl),

//                 // Name Field
//                 AppTextField(
//                   label: 'الاسم الكامل',
//                   controller: _nameController,
//                   prefixIcon: const Icon(Icons.person),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'الرجاء إدخال الاسم';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: AppSpacing.lg),

//                 // Email Field
//                 AppTextField(
//                   label: context.loc.email,
//                   controller: _emailController,
//                   prefixIcon: const Icon(Icons.email),
//                   keyboardType: TextInputType.emailAddress,
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'الرجاء إدخال البريد الإلكتروني';
//                     }
//                     if (!value.contains('@')) {
//                       return 'البريد الإلكتروني غير صحيح';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: AppSpacing.lg),

//                 // Password Field
//                 AppTextField(
//                   label: context.loc.password,
//                   controller: _passwordController,
//                   prefixIcon: const Icon(Icons.lock),
//                   obscureText: true,
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'الرجاء إدخال كلمة المرور';
//                     }
//                     if (value.length < 6) {
//                       return 'كلمة المرور يجب أن لا تقل عن 6 أحرف';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: AppSpacing.lg),

//                 // Confirm Password Field
//                 AppTextField(
//                   label: 'تأكيد كلمة المرور',
//                   controller: _confirmPasswordController,
//                   prefixIcon: const Icon(Icons.lock_outline),
//                   obscureText: true,
//                   validator: (value) {
//                     if (value != _passwordController.text) {
//                       return 'كلمة المرور غير متطابقة';
//                     }
//                     return null;
//                   },
//                 ),

//                 if (authState.errorMessage != null) ...[
//                   Container(
//                     padding: const EdgeInsets.all(AppSpacing.sm),
//                     decoration: BoxDecoration(
//                       color: context.colors.error.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(
//                           Icons.error_outline,
//                           color: context.colors.error,
//                           size: 20,
//                         ),
//                         const SizedBox(width: AppSpacing.sm),
//                         Expanded(
//                           child: Text(
//                             context.translateErrorKey(authState.errorMessage),
//                             style: context.textTheme.bodySmall?.copyWith(
//                               color: context.colors.error,
//                               height: 1.3,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: AppSpacing.lg),
//                 ],

//                 const SizedBox(height: AppSpacing.xl),

//                 // Submit Button
//                 AppButton(
//                   label: 'إنشاء الحساب',
//                   isLoading: isLoading,
//                   onPressed: isLoading ? null : _submit,
//                 ),

//                 const SizedBox(height: AppSpacing.md),
//                 TextButton(
//                   onPressed: isLoading
//                       ? null
//                       : () {
//                           if (mounted) Navigator.pop(context);
//                         },
//                   child: const Text('لدي حساب بالفعل؟ تسجيل الدخول'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
