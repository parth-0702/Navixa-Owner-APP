import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../common/app_card.dart';
import '../../common/skeleton_loading.dart';

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadTeam();
    });
  }

  void _showInviteDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'manager';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Invite Team Member'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name *'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email Address'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'manager', child: Text('Manager (Operational Read & Alert Ack)')),
                        DropdownMenuItem(value: 'viewer', child: Text('Viewer (Read Only)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Temporary Password',
                        hintText: 'Min 8 characters',
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondaryTeal, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    Navigator.pop(ctx);
                    final success = await this.context.read<SettingsProvider>().inviteMember(
                          name: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                          phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                          role: selectedRole,
                          tempPassword: passCtrl.text.trim().isNotEmpty ? passCtrl.text.trim() : null,
                        );
                    if (mounted) {
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Invitation created successfully' : 'Failed to invite team member'),
                          backgroundColor: success ? AppColors.secondaryTeal : AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Send Invite'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRoleOptions(User member) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Manage ${member.name}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              if (member.role != UserRole.manager)
                ListTile(
                  leading: const Icon(Icons.manage_accounts_rounded, color: AppColors.secondaryTeal),
                  title: const Text('Change Role to Manager'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<SettingsProvider>().updateMemberRole(member.id, 'manager');
                  },
                ),
              if (member.role != UserRole.viewer)
                ListTile(
                  leading: const Icon(Icons.visibility_outlined, color: AppColors.primaryNavy),
                  title: const Text('Change Role to Viewer'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<SettingsProvider>().updateMemberRole(member.id, 'viewer');
                  },
                ),
              const Divider(),
              ListTile(
                leading: Icon(
                  member.isActive ? Icons.person_off_outlined : Icons.person_add_alt_outlined,
                  color: member.isActive ? AppColors.error : AppColors.success,
                ),
                title: Text(member.isActive ? 'Deactivate Account' : 'Reactivate Account'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<SettingsProvider>().deactivateMember(member.id, !member.isActive);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final isOwner = auth.isOwner;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => settings.loadTeam(),
          ),
        ],
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.secondaryTeal,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Invite Member'),
              onPressed: _showInviteDialog,
            )
          : null,
      body: settings.isLoading && settings.teamMembers.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: SkeletonLoading(itemCount: 4, height: 80),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: settings.teamMembers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final member = settings.teamMembers[index];

                return AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                        child: Text(
                          member.name.isNotEmpty ? member.name[0].toUpperCase() : 'U',
                          style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  member.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: member.role == UserRole.owner
                                        ? AppColors.primaryNavy.withValues(alpha: 0.1)
                                        : (member.role == UserRole.manager
                                            ? AppColors.secondaryTeal.withValues(alpha: 0.1)
                                            : AppColors.lightBorder),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    member.role.name.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: member.role == UserRole.owner
                                          ? AppColors.primaryNavy
                                          : (member.role == UserRole.manager
                                              ? AppColors.secondaryTeal
                                              : AppColors.secondaryText),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              member.email,
                              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                      if (!member.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.errorSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('INACTIVE', style: TextStyle(fontSize: 10, color: AppColors.error, fontWeight: FontWeight.bold)),
                        ),
                      if (isOwner && member.role != UserRole.owner)
                        IconButton(
                          icon: const Icon(Icons.more_vert_rounded),
                          onPressed: () => _showRoleOptions(member),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
