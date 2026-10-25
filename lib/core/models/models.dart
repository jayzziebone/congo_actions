enum UserRole {
  donor,
  ngoAdmin,
  superAdmin;

  static UserRole fromString(String role) {
    switch (role.toUpperCase()) {
      case 'NGO_ADMIN':
        return UserRole.ngoAdmin;
      case 'SUPERADMIN':
        return UserRole.superAdmin;
      case 'DONOR':
      default:
        return UserRole.donor;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.donor:
        return 'Donor (Diaspora & DRC)';
      case UserRole.ngoAdmin:
        return 'NGO Organizer';
      case UserRole.superAdmin:
        return 'Platform SuperAdmin';
    }
  }
}

enum PaymentMethod {
  mpesa,
  orangeMoney,
  airtelMoney,
  afrimoney,
  cardStripe,
  cardFlutterwave;

  String get displayName {
    switch (this) {
      case PaymentMethod.mpesa:
        return 'Vodacom M-Pesa';
      case PaymentMethod.orangeMoney:
        return 'Orange Money';
      case PaymentMethod.airtelMoney:
        return 'Airtel Money';
      case PaymentMethod.afrimoney:
        return 'Africell Afrimoney';
      case PaymentMethod.cardStripe:
        return 'Visa / Mastercard / Apple Pay';
      case PaymentMethod.cardFlutterwave:
        return 'International Debit/Credit Card';
    }
  }

  bool get isMobileMoney =>
      this == PaymentMethod.mpesa ||
      this == PaymentMethod.orangeMoney ||
      this == PaymentMethod.airtelMoney ||
      this == PaymentMethod.afrimoney;
}

class UserProfile {
  final String id;
  final String phoneNumber;
  final String? email;
  final String fullName;
  final UserRole role;
  final String? avatarUrl;
  final String preferredCurrency; // 'USD' or 'CDF'

  UserProfile({
    required this.id,
    this.phoneNumber = '',
    this.email,
    required this.fullName,
    required this.role,
    this.avatarUrl,
    this.preferredCurrency = 'USD',
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String? ?? '',
      email: json['email'] as String? ?? json['contact_email'] as String?,
      fullName: json['full_name'] as String? ?? 'Congolese Donor',
      role: UserRole.fromString(json['role'] as String? ?? 'DONOR'),
      avatarUrl: json['avatar_url'] as String?,
      preferredCurrency: json['preferred_currency'] as String? ?? 'USD',
    );
  }

  UserProfile copyWith({
    String? id,
    String? phoneNumber,
    String? email,
    String? fullName,
    UserRole? role,
    String? avatarUrl,
    String? preferredCurrency,
  }) {
    return UserProfile(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
    );
  }
}

class NGO {
  final String id;
  final String adminUserId;
  final String name;
  final String legalRegistrationNumber;
  final String missionStatement;
  final String contactEmail;
  final String contactPhone;
  final String verificationStatus; // 'PENDING', 'VERIFIED', 'REJECTED'
  final String? bankName;
  final String? bankRib;
  final String? mobileMoneyMerchant;
  final DateTime createdAt;

  NGO({
    required this.id,
    required this.adminUserId,
    required this.name,
    required this.legalRegistrationNumber,
    required this.missionStatement,
    required this.contactEmail,
    required this.contactPhone,
    required this.verificationStatus,
    this.bankName,
    this.bankRib,
    this.mobileMoneyMerchant,
    required this.createdAt,
  });

  bool get isVerified => verificationStatus == 'VERIFIED';
}

class KYCDocument {
  final String id;
  final String ngoId;
  final String documentType; // 'ARRETE_MINISTERIEL', 'F92', etc.
  final String fileName;
  final String filePath;
  final String status; // 'PENDING', 'APPROVED', 'REJECTED'
  final String? reviewerNotes;
  final DateTime uploadedAt;

  KYCDocument({
    required this.id,
    required this.ngoId,
    required this.documentType,
    required this.fileName,
    required this.filePath,
    required this.status,
    this.reviewerNotes,
    required this.uploadedAt,
  });

  factory KYCDocument.fromJson(Map<String, dynamic> json) {
    return KYCDocument(
      id: json['id'] as String,
      ngoId: json['ngo_id'] as String? ?? '',
      documentType: json['document_type'] as String? ?? 'OTHER',
      fileName: json['file_name'] as String? ?? 'document.pdf',
      filePath: json['file_path'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      reviewerNotes: json['reviewer_notes'] as String?,
      uploadedAt: json['uploaded_at'] != null ? DateTime.parse(json['uploaded_at'] as String) : DateTime.now(),
    );
  }

  KYCDocument copyWith({
    String? id,
    String? ngoId,
    String? documentType,
    String? fileName,
    String? filePath,
    String? status,
    String? reviewerNotes,
    DateTime? uploadedAt,
  }) {
    return KYCDocument(
      id: id ?? this.id,
      ngoId: ngoId ?? this.ngoId,
      documentType: documentType ?? this.documentType,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      status: status ?? this.status,
      reviewerNotes: reviewerNotes ?? this.reviewerNotes,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}

class Campaign {
  final String id;
  final String? ngoId;
  final String? ngoName;
  final bool isNgoVerified;
  final String title;
  final String subtitle;
  final String description;
  final String category; // 'Health', 'Education', 'Children', etc.
  final bool isPooledFund;
  final int targetAmountUsdCents;
  final int raisedAmountUsdCents;
  final int targetAmountCdf;
  final int raisedAmountCdf;
  final String imageUrl;
  final String location;
  final List<CampaignSplit> splits;
  final List<ImpactUpdate> impactUpdates;
  final DateTime createdAt;

  Campaign({
    required this.id,
    this.ngoId,
    this.ngoName,
    this.isNgoVerified = true,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.isPooledFund,
    required this.targetAmountUsdCents,
    required this.raisedAmountUsdCents,
    required this.targetAmountCdf,
    required this.raisedAmountCdf,
    required this.imageUrl,
    required this.location,
    this.splits = const [],
    this.impactUpdates = const [],
    required this.createdAt,
  });

  double get progressRatioUsd => targetAmountUsdCents > 0
      ? (raisedAmountUsdCents / targetAmountUsdCents).clamp(0.0, 1.0)
      : 0.0;

  double get progressRatioCdf => targetAmountCdf > 0
      ? (raisedAmountCdf / targetAmountCdf).clamp(0.0, 1.0)
      : 0.0;

  factory Campaign.fromJson(Map<String, dynamic> json) {
    var rawSplits = json['campaign_splits'] as List<dynamic>? ?? [];
    var rawUpdates = json['impact_updates'] as List<dynamic>? ?? [];

    final ngoMap = json['ngos'] as Map<String, dynamic>?;
    final ngoName = ngoMap != null ? ngoMap['name'] as String? : null;

    return Campaign(
      id: json['id'] as String,
      ngoId: json['ngo_id'] as String?,
      ngoName: ngoName,
      isNgoVerified: ngoMap != null ? (ngoMap['verification_status'] == 'VERIFIED') : true,
      title: json['title'] as String? ?? 'Untitled Cause',
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Health',
      isPooledFund: json['is_pooled_fund'] as bool? ?? false,
      targetAmountUsdCents: (json['target_amount_usd_cents'] as num?)?.toInt() ?? 0,
      raisedAmountUsdCents: (json['raised_amount_usd_cents'] as num?)?.toInt() ?? 0,
      targetAmountCdf: (json['target_amount_cdf'] as num?)?.toInt() ?? 0,
      raisedAmountCdf: (json['raised_amount_cdf'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String? ?? 'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?auto=format&fit=crop&w=1200&q=80',
      location: json['location'] as String? ?? 'DRC',
      splits: rawSplits.map((s) => CampaignSplit.fromJson(s as Map<String, dynamic>)).toList(),
      impactUpdates: rawUpdates.map((u) => ImpactUpdate.fromJson(u as Map<String, dynamic>)).toList(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Campaign copyWith({
    int? raisedAmountUsdCents,
    int? raisedAmountCdf,
    List<CampaignSplit>? splits,
    List<ImpactUpdate>? impactUpdates,
  }) {
    return Campaign(
      id: id,
      ngoId: ngoId,
      ngoName: ngoName,
      isNgoVerified: isNgoVerified,
      title: title,
      subtitle: subtitle,
      description: description,
      category: category,
      isPooledFund: isPooledFund,
      targetAmountUsdCents: targetAmountUsdCents,
      raisedAmountUsdCents: raisedAmountUsdCents ?? this.raisedAmountUsdCents,
      targetAmountCdf: targetAmountCdf,
      raisedAmountCdf: raisedAmountCdf ?? this.raisedAmountCdf,
      imageUrl: imageUrl,
      location: location,
      splits: splits ?? this.splits,
      impactUpdates: impactUpdates ?? this.impactUpdates,
      createdAt: createdAt,
    );
  }
}

class CampaignSplit {
  final String id;
  final String ngoId;
  final String ngoName;
  final double percentage; // e.g. 40.0 for 40%

  CampaignSplit({
    required this.id,
    required this.ngoId,
    required this.ngoName,
    required this.percentage,
  });

  factory CampaignSplit.fromJson(Map<String, dynamic> json) {
    final ngoMap = json['ngos'] as Map<String, dynamic>?;
    return CampaignSplit(
      id: json['id'] as String,
      ngoId: json['ngo_id'] as String? ?? '',
      ngoName: ngoMap?['name'] as String? ?? json['ngo_name'] as String? ?? 'Partner NGO',
      percentage: (json['split_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  CampaignSplit copyWith({double? percentage}) {
    return CampaignSplit(
      id: id,
      ngoId: ngoId,
      ngoName: ngoName,
      percentage: percentage ?? this.percentage,
    );
  }
}

class Donation {
  final String id;
  final String? donorId;
  final String campaignId;
  final String campaignTitle;
  final int amountUsdCents;
  final int amountCdf;
  final String currency;
  final int feeCoveredUsdCents;
  final int feeCoveredCdf;
  final bool isAnonymous;
  final PaymentMethod paymentMethod;
  final String paymentReference;
  final String status; // 'PENDING', 'SUCCESS', 'FAILED'
  final String receiptNumber;
  final DateTime createdAt;

  Donation({
    required this.id,
    this.donorId,
    required this.campaignId,
    required this.campaignTitle,
    required this.amountUsdCents,
    required this.amountCdf,
    required this.currency,
    required this.feeCoveredUsdCents,
    required this.feeCoveredCdf,
    required this.isAnonymous,
    required this.paymentMethod,
    required this.paymentReference,
    required this.status,
    required this.receiptNumber,
    required this.createdAt,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    final campaignMap = json['campaigns'] as Map<String, dynamic>?;
    final pmStr = (json['payment_method'] as String? ?? 'CARD_STRIPE').toUpperCase();
    PaymentMethod method = PaymentMethod.cardStripe;
    if (pmStr.contains('MPESA')) {
      method = PaymentMethod.mpesa;
    } else if (pmStr.contains('ORANGE')) {
      method = PaymentMethod.orangeMoney;
    } else if (pmStr.contains('AIRTEL')) {
      method = PaymentMethod.airtelMoney;
    } else if (pmStr.contains('AFRI')) {
      method = PaymentMethod.afrimoney;
    }

    return Donation(
      id: json['id'] as String,
      donorId: json['donor_id'] as String?,
      campaignId: json['campaign_id'] as String? ?? '',
      campaignTitle: campaignMap?['title'] as String? ?? json['campaign_title'] as String? ?? 'Humanitarian Campaign',
      amountUsdCents: (json['amount_usd_cents'] as num?)?.toInt() ?? 0,
      amountCdf: (json['amount_cdf'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      feeCoveredUsdCents: (json['fee_covered_usd_cents'] as num?)?.toInt() ?? 0,
      feeCoveredCdf: (json['fee_covered_cdf'] as num?)?.toInt() ?? 0,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      paymentMethod: method,
      paymentReference: json['payment_reference'] as String? ?? '',
      status: json['status'] as String? ?? 'SUCCESS',
      receiptNumber: json['receipt_number'] as String? ?? 'REC-${json['id']?.toString().substring(0, 8)}',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }
}

class Ngo {
  final String id;
  final String adminUserId;
  final String name;
  final String legalRegistrationNumber;
  final String missionStatement;
  final String contactEmail;
  final String contactPhone;
  final String? websiteUrl;
  final String verificationStatus; // 'PENDING', 'VERIFIED', 'REJECTED'
  final String? bankName;
  final String? bankRib;
  final String? mobileMoneyMerchant;
  final DateTime createdAt;

  Ngo({
    required this.id,
    required this.adminUserId,
    required this.name,
    required this.legalRegistrationNumber,
    required this.missionStatement,
    required this.contactEmail,
    required this.contactPhone,
    this.websiteUrl,
    required this.verificationStatus,
    this.bankName,
    this.bankRib,
    this.mobileMoneyMerchant,
    required this.createdAt,
  });

  factory Ngo.fromJson(Map<String, dynamic> json) {
    return Ngo(
      id: json['id'] as String,
      adminUserId: json['admin_user_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Congolese NGO',
      legalRegistrationNumber: json['legal_registration_number'] as String? ?? '',
      missionStatement: json['mission_statement'] as String? ?? '',
      contactEmail: json['contact_email'] as String? ?? '',
      contactPhone: json['contact_phone'] as String? ?? '',
      websiteUrl: json['website_url'] as String?,
      verificationStatus: json['verification_status'] as String? ?? 'PENDING',
      bankName: json['bank_name'] as String?,
      bankRib: json['bank_rib'] as String?,
      mobileMoneyMerchant: json['mobile_money_merchant'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }
}

class Subscription {
  final String id;
  final String donorId;
  final String campaignId;
  final String campaignTitle;
  final int amountUsdCents;
  final int amountCdf;
  final String currency;
  final String paymentRail; // 'CARD_AUTO_DEBIT', 'MOBILE_MONEY_PLEDGE'
  final String phoneNumber;
  final String status; // 'ACTIVE', 'PAUSED', 'CANCELLED'
  final bool actionNeededToday;
  final DateTime nextBillingDate;

  Subscription({
    required this.id,
    required this.donorId,
    required this.campaignId,
    required this.campaignTitle,
    required this.amountUsdCents,
    required this.amountCdf,
    required this.currency,
    required this.paymentRail,
    required this.phoneNumber,
    required this.status,
    required this.actionNeededToday,
    required this.nextBillingDate,
  });

  Subscription copyWith({
    String? status,
    bool? actionNeededToday,
    DateTime? nextBillingDate,
  }) {
    return Subscription(
      id: id,
      donorId: donorId,
      campaignId: campaignId,
      campaignTitle: campaignTitle,
      amountUsdCents: amountUsdCents,
      amountCdf: amountCdf,
      currency: currency,
      paymentRail: paymentRail,
      phoneNumber: phoneNumber,
      status: status ?? this.status,
      actionNeededToday: actionNeededToday ?? this.actionNeededToday,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
    );
  }
}

class PayoutRequest {
  final String id;
  final String ngoId;
  final String ngoName;
  final int amountUsdCents;
  final int amountCdf;
  final String currency;
  final String destinationType; // 'BANK_RIB' or 'MOBILE_MONEY'
  final String destinationDetails;
  final bool biometricVerified;
  final String status; // 'REQUESTED', 'APPROVED', 'COMPLETED'
  final DateTime createdAt;

  PayoutRequest({
    required this.id,
    required this.ngoId,
    required this.ngoName,
    required this.amountUsdCents,
    required this.amountCdf,
    required this.currency,
    required this.destinationType,
    required this.destinationDetails,
    required this.biometricVerified,
    required this.status,
    required this.createdAt,
  });
}

class ImpactUpdate {
  final String id;
  final String campaignId;
  final String ngoId;
  final String ngoName;
  final String title;
  final String content;
  final List<String> mediaUrls;
  final String? receiptImageUrl;
  final DateTime publishedAt;

  ImpactUpdate({
    required this.id,
    required this.campaignId,
    required this.ngoId,
    required this.ngoName,
    required this.title,
    required this.content,
    required this.mediaUrls,
    this.receiptImageUrl,
    required this.publishedAt,
  });

  factory ImpactUpdate.fromJson(Map<String, dynamic> json) {
    final ngoMap = json['ngos'] as Map<String, dynamic>?;
    final mediaList = (json['media_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

    return ImpactUpdate(
      id: json['id'] as String,
      campaignId: json['campaign_id'] as String? ?? '',
      ngoId: json['ngo_id'] as String? ?? '',
      ngoName: ngoMap?['name'] as String? ?? json['ngo_name'] as String? ?? 'Verified NGO Partner',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      mediaUrls: mediaList,
      receiptImageUrl: json['receipt_image_url'] as String?,
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at'] as String) : DateTime.now(),
    );
  }
}
