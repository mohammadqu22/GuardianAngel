class Emergency {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String description;
  final List<String> warnings;

  Emergency({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.warnings,
  });
}

// Sample data (we'll replace this with JSON later)
List<Emergency> getSampleEmergencies() {
  return [
    Emergency(
      id: 'burns',
      name: 'Burns',
      icon: 'fire',
      color: '0xFFFF5722',
      description:
          'Treatment for thermal, chemical, or electrical burns affecting the skin. Burns can range from minor to severe and require immediate cooling and proper care.',
      warnings: [
        'Remove from heat source immediately',
        'Cool with running water for 10-20 minutes',
        'Do NOT use ice directly on burn',
        'Do NOT apply creams or ointments immediately',
        'Cover with clean, non-stick bandage',
      ],
    ),
    Emergency(
      id: 'choking',
      name: 'Choking',
      icon: 'air',
      color: '0xFF2196F3',
      description:
          'Emergency response for airway obstruction. Quick action is critical when someone cannot breathe, cough, or speak due to a blocked airway.',
      warnings: [
        'Ask "Are you choking?" to confirm',
        'Encourage coughing if they can',
        'Perform back blows and abdominal thrusts',
        'Call emergency services immediately if severe',
        'Do NOT give water to someone who is choking',
      ],
    ),
    Emergency(
      id: 'cpr',
      name: 'CPR',
      icon: 'favorite',
      color: '0xFFE53935',
      description:
          'Cardiopulmonary resuscitation for cardiac arrest. CPR keeps blood flowing to vital organs until professional help arrives.',
      warnings: [
        'Check if person is responsive and breathing',
        'Call emergency services first',
        'Push hard and fast in center of chest',
        '100-120 compressions per minute',
        'Continue until help arrives or person responds',
      ],
    ),
    Emergency(
      id: 'bleeding',
      name: 'Bleeding',
      icon: 'water_drop',
      color: '0xFFD32F2F',
      description:
          'Control severe bleeding and prevent shock. Quick action to stop blood loss can be life-saving in emergency situations.',
      warnings: [
        'Apply direct pressure with clean cloth',
        'Keep pressure constant for 10-15 minutes',
        'Elevate the injured area if possible',
        'Do NOT remove blood-soaked cloth, add more on top',
        'Call emergency services for severe bleeding',
      ],
    ),
    Emergency(
      id: 'fractures',
      name: 'Fractures',
      icon: 'accessible',
      color: '0xFF9C27B0',
      description:
          'Stabilization and care for broken bones. Proper immobilization prevents further injury and reduces pain.',
      warnings: [
        'Do NOT try to straighten the bone',
        'Immobilize the injured area',
        'Apply ice pack to reduce swelling',
        'Do NOT move the person unless necessary',
        'Seek medical attention immediately',
      ],
    ),
    Emergency(
      id: 'seizures',
      name: 'Seizures',
      icon: 'warning_amber',
      color: '0xFFFFA726',
      description:
          'Response to seizure episodes. Protecting the person from injury and monitoring their condition is crucial.',
      warnings: [
        'Stay calm and time the seizure',
        'Clear area of dangerous objects',
        'Do NOT restrain the person',
        'Do NOT put anything in their mouth',
        'Turn them on their side after seizure stops',
      ],
    ),
  ];
}
