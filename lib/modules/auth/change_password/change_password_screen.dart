import 'package:vm_first_app/app/app_provider.dart';
import 'package:vm_first_app/core/route/router.dart';
import 'package:vm_first_app/core/core.dart';
import 'package:vm_first_app/modules/auth/change_password/change_password_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChangePasswordProvider(locator<AppProvider>()),
      child: const _ChangePasswordView(),
    );
  }
}

class _ChangePasswordView extends StatelessWidget {
  const _ChangePasswordView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChangePasswordProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: provider.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_outlined,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Create New Password',
                    style: AppTextStyles.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your new password must be different from previous password',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 32),
                  // Email Field
                  TextFormField(
                    controller: provider.passwordController,
                    obscureText: provider.obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      hintText: 'Enter your password',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          provider.obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: provider.togglePasswordVisibility,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                    enabled: !provider.isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: provider.newPasswordController,
                    obscureText: provider.obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password *',
                      hintText: 'Create new password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          provider.obscureNewPassword
                              ? Icons.visibility
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: provider.toggleNewPasswordVisibility,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a new password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                    enabled: !provider.isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    controller: provider.confirmNewPasswordController,
                    obscureText: provider.obscureConfirmNewPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password *',
                      hintText: 'Re-enter your password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          provider.obscureConfirmNewPassword
                              ? Icons.visibility
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: provider.toggleConfirmNewPasswordVisibility,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != provider.newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    enabled: !provider.isLoading,
                  ),

                  // Error Message
                  if (provider.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.errorMessage!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ChangePassword Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: provider.isLoading ? null : provider.changePassword,
                      child: provider.isLoading
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                        ),
                      )
                          : const Text('Reset Password'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Login Link
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     Text(
                  //       'Already have an account? ',
                  //       style: AppTextStyles.bodyMedium,
                  //     ),
                  //     TextButton(
                  //       onPressed: provider.isLoading
                  //           ? null
                  //           : () {
                  //         context.router.pop();
                  //       },
                  //       style: TextButton.styleFrom(
                  //         padding: const EdgeInsets.symmetric(horizontal: 4),
                  //         minimumSize: Size.zero,
                  //         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  //       ),
                  //       child: Text(
                  //         'Sign In',
                  //         style: AppTextStyles.bodyMedium.copyWith(
                  //           color: AppColors.primary,
                  //           fontWeight: FontWeight.w600,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
