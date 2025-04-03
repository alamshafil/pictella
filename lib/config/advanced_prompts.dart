import 'package:flutter/material.dart';

class AdvancedPrompt {
  final String title;
  final String description;
  final String prompt;
  final IconData icon;
  final Color accentColor;
  final String category;

  const AdvancedPrompt({
    required this.title,
    required this.description,
    required this.prompt,
    required this.icon,
    this.accentColor = Colors.blue,
    required this.category,
  });
}

class CategoryInfo {
  final String name;
  final IconData icon;

  const CategoryInfo({required this.name, required this.icon});
}

final Map<String, CategoryInfo> categoryInfoMap = {
  'All': CategoryInfo(name: 'All', icon: Icons.apps),
  'Portrait': CategoryInfo(name: 'Portrait', icon: Icons.face),
  'Background': CategoryInfo(name: 'Background', icon: Icons.landscape),
  'Lighting': CategoryInfo(name: 'Lighting', icon: Icons.light_mode),
  'Style': CategoryInfo(name: 'Style', icon: Icons.style),
  'Effects': CategoryInfo(name: 'Effects', icon: Icons.auto_fix_high),
};

final List<String> advancedPromptCategories = [
  'Portrait',
  'Background',
  'Lighting',
  'Style',
  'Effects',
];

final List<AdvancedPrompt> advancedPrompts = [
  AdvancedPrompt(
    title: 'Professional Portrait',
    description: 'Transform into a high-end business headshot',
    prompt:
        'Transform this photo into a professional corporate headshot with perfect studio lighting, clean neutral background, crisp focus on face, and subtle color grading that emphasizes professionalism. Ensure proper exposure, natural skin tones, and sharp details especially in the eyes.',
    icon: Icons.business,
    accentColor: Colors.blueAccent,
    category: 'Portrait',
  ),
  AdvancedPrompt(
    title: 'Perfect Background',
    description: 'Clean and enhance the background',
    prompt:
        'Enhance the background with subtle bokeh effect, maintain perfect separation between subject and background, adjust lighting to create depth, and ensure the background complements the subject without overpowering it.',
    icon: Icons.blur_on,
    accentColor: Colors.orangeAccent,
    category: 'Background',
  ),
  AdvancedPrompt(
    title: 'Perfect Lighting',
    description: 'Optimize all lighting aspects',
    prompt:
        'Optimize the lighting to create perfect exposure across the entire image. Add subtle rim lighting, fix harsh shadows, enhance natural light, and ensure proper highlight and shadow balance. Maintain natural look while maximizing lighting quality.',
    icon: Icons.wb_sunny,
    accentColor: Colors.amberAccent,
    category: 'Lighting',
  ),
  AdvancedPrompt(
    title: 'Artistic Portrait',
    description: 'Add dramatic artistic effects',
    prompt:
        'Convert this image into a cinematic portrait with dramatic Rembrandt lighting, rich deep shadows, enhanced facial features, and a subtle vignette effect. Add professional color grading with rich contrasts while maintaining natural skin tones.',
    icon: Icons.brush,
    accentColor: Colors.purpleAccent,
    category: 'Effects',
  ),
  AdvancedPrompt(
    title: 'Magazine Style',
    description: 'High-fashion magazine aesthetic',
    prompt:
        'Transform this photo into a high-end fashion magazine style portrait with perfect skin retouching, enhanced features, professional color grading, and magazine-quality lighting. Add subtle makeup enhancement and ensure high-end editorial look.',
    icon: Icons.style,
    accentColor: Colors.pinkAccent,
    category: 'Style',
  ),
  AdvancedPrompt(
    title: "Add djcow's submariner",
    description: "Add the world-famous djcow submariner to the image.",
    prompt:
        "Add a Rolex Submariner watch to the wrist of the main person in the image. Ensure the watch is realistic and matches the lighting and angle of the original photo. Also add girls who are in awe of the watch to the image due the person being famous. Make sure the girls are correctly in the image.",
    icon: Icons.watch,
    accentColor: Colors.blueAccent,
    category: 'Effects',
  ),
];
