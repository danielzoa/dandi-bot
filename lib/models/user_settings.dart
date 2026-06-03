import 'package:flutter/material.dart';

import '../enums/currency.dart';
import '../enums/investor_profile.dart';
import '../enums/time_horizon.dart';

class UserSettings {
  const UserSettings({
    required this.themeMode,
    required this.investorProfile,
    required this.timeHorizon,
    required this.currency,
    this.geminiApiKey,
    this.backendUrl = 'http://127.0.0.1:8000',
  });

  final ThemeMode themeMode;
  final InvestorProfile investorProfile;
  final TimeHorizon timeHorizon;
  final Currency currency;
  final String? geminiApiKey;
  final String backendUrl;

  static const defaults = UserSettings(
    themeMode: ThemeMode.dark,
    investorProfile: InvestorProfile.moderate,
    timeHorizon: TimeHorizon.longTerm,
    currency: Currency.brl,
    geminiApiKey: null,
    backendUrl: 'http://127.0.0.1:8000',
  );

  UserSettings copyWith({
    ThemeMode? themeMode,
    InvestorProfile? investorProfile,
    TimeHorizon? timeHorizon,
    Currency? currency,
    String? geminiApiKey,
    String? backendUrl,
  }) {
    return UserSettings(
      themeMode: themeMode ?? this.themeMode,
      investorProfile: investorProfile ?? this.investorProfile,
      timeHorizon: timeHorizon ?? this.timeHorizon,
      currency: currency ?? this.currency,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      backendUrl: backendUrl ?? this.backendUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'investorProfile': investorProfile.name,
    'timeHorizon': timeHorizon.name,
    'currency': currency.name,
    if (geminiApiKey != null) 'geminiApiKey': geminiApiKey,
    'backendUrl': backendUrl,
  };

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      themeMode: ThemeMode.values.byName(json['themeMode'] as String),
      investorProfile: InvestorProfile.values.byName(
        json['investorProfile'] as String,
      ),
      timeHorizon: TimeHorizon.values.byName(json['timeHorizon'] as String),
      currency: Currency.values.byName(json['currency'] as String),
      geminiApiKey: json['geminiApiKey'] as String?,
      backendUrl: json['backendUrl'] as String? ?? 'http://127.0.0.1:8000',
    );
  }
}

