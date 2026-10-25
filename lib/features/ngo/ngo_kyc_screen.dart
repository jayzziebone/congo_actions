import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class NgoKycScreen extends ConsumerStatefulWidget {
  const NgoKycScreen({super.key});

  @override
  ConsumerState<NgoKycScreen> createState() => _NgoKycScreenState();
}

class _NgoKycScreenState extends ConsumerState<NgoKycScreen> {
  int _currentStep = 0;

  // Form controllers
  final _ngoNameController = TextEditingController(text: 'Fondation Panzi');
  final _regNumController = TextEditingController(text: 'Arrêté N° 045/CAB/MIN/J&DH/2021');
  final _bankRibController = TextEditingController(text: '05100-0101-09876543210-90');
  final _mobileMerchantController = TextEditingController(text: 'PANZI-MERCHANT-01');

  final Map<String, bool> _uploadedDocs = {
    'Arrêté Ministériel (Ministerial Decree)': true,
    'F92 Legal Status Document': true,
    'Notarized Statutes & Bylaws': false,
    'Director National ID / Passport': true,
  };

  @override
  void dispose() {
    _ngoNameController.dispose();
    _regNumController.dispose();
    _bankRibController.dispose();
    _mobileMerchantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfacePureWhite,
      appBar: AppBar(
        title: const Text('NGO Verification (KYC)'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/ngo');
            }
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  _buildStepIndicator(0, 'Legal Registry'),
                  const Expanded(child: Divider(color: AppTheme.cardOutline, thickness: 2)),
                  _buildStepIndicator(1, 'Documents'),
                  const Expanded(child: Divider(color: AppTheme.cardOutline, thickness: 2)),
                  _buildStepIndicator(2, 'Payout Rail'),
                ],
              ),
            ),
            const Divider(color: AppTheme.cardOutline, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildCurrentStepContent(),
              ),
            ),
            // Bottom Action buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.surfacePureWhite,
                border: Border(top: BorderSide(color: AppTheme.cardOutline, width: 1)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep--),
                          child: const Text('Previous Step'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: PillButton(
                        label: _currentStep == 2 ? 'Submit for SuperAdmin Review' : 'Next Step',
                        onPressed: () {
                          if (_currentStep < 2) {
                            setState(() => _currentStep++);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('KYC Dossier submitted! SuperAdmin has been notified.')),
                            );
                            context.go('/ngo');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    final isActive = _currentStep == stepIndex;
    final isDone = _currentStep > stepIndex;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isDone
                ? AppTheme.mintGreen
                : (isActive ? AppTheme.ceruleanBlue : AppTheme.backgroundIceBlue),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone || isActive ? Colors.transparent : AppTheme.cardOutline,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppTheme.textMutedGray,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: isActive ? AppTheme.textSlateNavy : AppTheme.textMutedGray,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Organization Information',
              style: TextStyle(color: AppTheme.textSlateNavy, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Provide the registered legal entity details recognized under the Ministry of Justice of the DRC.',
              style: TextStyle(color: AppTheme.textMutedGray, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _buildInputField('Official NGO Name', _ngoNameController, 'e.g. Fondation Panzi'),
            const SizedBox(height: 16),
            _buildInputField('Arrêté Ministériel Registry N°', _regNumController, 'e.g. Arrêté N° 045/CAB/MIN/J&DH/2021'),
            const SizedBox(height: 16),
            _buildInputField('Headquarters Address', TextEditingController(text: 'Avenue de l\'Hôpital, Bukavu, Sud-Kivu'), 'Physical address in DRC'),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Legal Documentation',
              style: TextStyle(color: AppTheme.textSlateNavy, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'All files are stored in private Supabase Storage buckets with strict Row Level Security.',
              style: TextStyle(color: AppTheme.textMutedGray, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ..._uploadedDocs.entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundIceBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardOutline),
                ),
                child: Row(
                  children: [
                    Icon(
                      entry.value ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                      color: entry.value ? AppTheme.mintGreen : AppTheme.ceruleanBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              color: AppTheme.textSlateNavy,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.value ? 'Uploaded • PDF verified' : 'Required document (PDF / JPG max 15MB)',
                            style: TextStyle(
                              color: entry.value ? AppTheme.mintGreen : AppTheme.textMutedGray,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          _uploadedDocs[entry.key] = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${entry.key} uploaded and compressed successfully.')),
                        );
                      },
                      child: Text(entry.value ? 'Re-upload' : 'Upload'),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      case 2:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payout Configuration',
              style: TextStyle(color: AppTheme.textSlateNavy, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Specify where cleared donations will be wired when withdrawals are initiated.',
              style: TextStyle(color: AppTheme.textMutedGray, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _buildInputField('Bank Name', TextEditingController(text: 'Rawbank Kinshasa / Bukavu'), 'e.g. Rawbank or Equity BCDC'),
            const SizedBox(height: 16),
            _buildInputField('Relevé d\'Identité Bancaire (RIB)', _bankRibController, '23-digit bank code'),
            const SizedBox(height: 16),
            _buildInputField('Corporate Mobile Money Merchant ID', _mobileMerchantController, 'e.g. M-Pesa or Orange Till Number'),
          ],
        );
    }
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSlateNavy, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}
