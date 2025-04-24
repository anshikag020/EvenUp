import 'package:flutter/material.dart';
import 'package:my_new_app/theme/theme_service.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeToggleTile extends StatelessWidget {
  const ThemeToggleTile({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDarkMode = themeService.isDarkMode;
    final iconColor = Theme.of(context).colorScheme.onBackground;

    return ListTile(
      leading: Icon(Icons.brightness_2_outlined, color: iconColor),
      title: Text(
        "Dark Mode",
        style: GoogleFonts.poppins(
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      trailing: Switch(
        value: isDarkMode,
        onChanged: (_) => themeService.toggleTheme(),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
    );
  }
}
