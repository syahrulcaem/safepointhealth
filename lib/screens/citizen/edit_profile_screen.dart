import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _profileService = ProfileService();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _nikController;
  late TextEditingController _whatsappKeluargaController;
  late TextEditingController _chronicConditionsController;

  // Dropdown values
  String? _selectedHubungan;
  String? _selectedBloodType;
  DateTime? _selectedBirthDate;

  bool _isLoading = false;
  bool _isSaving = false;
  String? _ktpImageUrl;
  XFile? _selectedKtpImage;

  final List<String> _hubunganOptions = [
    'KEPALA_KELUARGA',
    'ISTRI',
    'SUAMI',
    'ANAK',
    'AYAH',
    'IBU',
    'KAKEK',
    'NENEK',
    'CUCU',
    'SAUDARA',
    'LAINNYA',
  ];

  final List<String> _bloodTypeOptions = [
    'A',
    'B',
    'AB',
    'O',
    'UNKNOWN',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _nikController = TextEditingController();
    _whatsappKeluargaController = TextEditingController();
    _chronicConditionsController = TextEditingController();

    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nikController.dispose();
    _whatsappKeluargaController.dispose();
    _chronicConditionsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      print('📝 Loading profile data...');

      // Check if user is authenticated
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated || authProvider.user == null) {
        print('❌ User not authenticated');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login first'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      print('✅ User authenticated: ${authProvider.user!.email}');

      final profile = await _profileService.getProfile();
      print('📦 Profile received: ${profile != null ? "Yes" : "No"}');

      if (profile != null && mounted) {
        print('📋 Profile data: ${profile.toString()}');

        setState(() {
          _nameController.text = profile['name'] ?? '';
          _phoneController.text = profile['phone'] ?? '';

          print('   Name: ${_nameController.text}');
          print('   Phone: ${_phoneController.text}');

          final citizenProfile = profile['citizen_profile'];
          print('   Citizen Profile: ${citizenProfile != null ? "Yes" : "No"}');

          if (citizenProfile != null) {
            print('   📋 Citizen Profile data: ${citizenProfile.toString()}');

            _nikController.text = citizenProfile['nik'] ?? '';
            _whatsappKeluargaController.text =
                citizenProfile['whatsapp_keluarga'] ?? '';
            _chronicConditionsController.text =
                citizenProfile['chronic_conditions'] ?? '';
            _selectedHubungan = citizenProfile['hubungan'];
            _selectedBloodType = citizenProfile['blood_type'];
            _ktpImageUrl = citizenProfile['ktp_image_url'];

            print('   NIK: ${_nikController.text}');
            print('   WhatsApp Keluarga: ${_whatsappKeluargaController.text}');
            print('   Hubungan: $_selectedHubungan');
            print('   Blood Type: $_selectedBloodType');

            if (citizenProfile['birth_date'] != null) {
              _selectedBirthDate = DateTime.parse(citizenProfile['birth_date']);
              print('   Birth Date: $_selectedBirthDate');
            }
          }
        });

        print('✅ Profile data loaded into form fields');
      } else {
        print('⚠️ Profile is null, form will be empty');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickKtpImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedKtpImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFE53E3E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Update profile data with correct nested structure (email removed - cannot be changed)
      final profileData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'citizen_profile': {
          'nik': _nikController.text.trim(),
          'whatsapp_keluarga': _whatsappKeluargaController.text.trim(),
          'hubungan': _selectedHubungan,
          'birth_date': _selectedBirthDate != null
              ? DateFormat('yyyy-MM-dd').format(_selectedBirthDate!)
              : null,
          'blood_type': _selectedBloodType,
          'chronic_conditions': _chronicConditionsController.text.trim(),
        }
      };

      print('💾 Saving profile data: ${profileData.toString()}');

      final success = await _profileService.updateProfile(profileData);
      print('📤 Update profile API result: $success');

      if (success && mounted) {
        print(
            '✅ Profile update successful, proceeding with post-save actions...');

        // Upload KTP image if selected
        if (_selectedKtpImage != null) {
          print('📷 Uploading KTP image...');
          final imageUrl =
              await _profileService.uploadKtpImage(_selectedKtpImage!);
          print('📷 KTP image upload result: $imageUrl');
        }

        // IMPORTANT: Refresh auth provider to get updated user data from server
        if (mounted) {
          // Small delay to ensure server has processed the update
          await Future.delayed(const Duration(milliseconds: 500));

          print('🔄 Refreshing user data from server...');
          final authProvider =
              Provider.of<AuthProvider>(context, listen: false);
          await authProvider.refreshUser();

          // Verify refresh worked
          final updatedUser = authProvider.user;
          print('✅ User data after refresh:');
          print('   Name: ${updatedUser?.name}');
          print('   Phone: ${updatedUser?.phone}');
          print(
              '   Citizen Profile: ${updatedUser?.citizenProfile != null ? "Exists" : "null"}');
          if (updatedUser?.citizenProfile != null) {
            print('   NIK: ${updatedUser!.citizenProfile!.nik}');
            print(
                '   WhatsApp: ${updatedUser.citizenProfile!.whatsappKeluarga}');
            print('   Hubungan: ${updatedUser.citizenProfile!.hubungan}');
            print('   Blood Type: ${updatedUser.citizenProfile!.bloodType}');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFFE53E3E),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // KTP Image Section
                  _buildKtpImageSection(),
                  const SizedBox(height: 24),

                  // Personal Information
                  _buildSectionTitle('Personal Information'),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    icon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),

                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),

                  _buildTextField(
                    controller: _nikController,
                    label: 'NIK (16 digits)',
                    icon: Icons.credit_card,
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          value.length != 16) {
                        return 'NIK must be 16 digits';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Emergency Contact
                  _buildSectionTitle('Emergency Contact'),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _whatsappKeluargaController,
                    label: 'Family WhatsApp',
                    icon: Icons.contact_phone,
                    keyboardType: TextInputType.phone,
                  ),

                  _buildDropdownField(
                    label: 'Family Relationship',
                    icon: Icons.family_restroom,
                    value: _selectedHubungan,
                    items: _hubunganOptions,
                    onChanged: (value) {
                      setState(() {
                        _selectedHubungan = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Medical Information
                  _buildSectionTitle('Medical Information'),
                  const SizedBox(height: 16),

                  _buildDateField(
                    label: 'Birth Date',
                    icon: Icons.cake,
                    date: _selectedBirthDate,
                    onTap: _selectBirthDate,
                  ),

                  _buildDropdownField(
                    label: 'Blood Type',
                    icon: Icons.bloodtype,
                    value: _selectedBloodType,
                    items: _bloodTypeOptions,
                    onChanged: (value) {
                      setState(() {
                        _selectedBloodType = value;
                      });
                    },
                  ),

                  _buildTextField(
                    controller: _chronicConditionsController,
                    label: 'Chronic Conditions (if any)',
                    icon: Icons.medical_information,
                    maxLines: 3,
                    hintText: 'e.g., Diabetes, Hipertensi',
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53E3E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildKtpImageSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KTP Photo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedKtpImage != null || _ktpImageUrl != null)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _selectedKtpImage != null
                    ? Image.network(
                        _selectedKtpImage!.path,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child:
                                Icon(Icons.error, size: 50, color: Colors.red),
                          );
                        },
                      )
                    : Image.network(
                        _ktpImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child:
                                Icon(Icons.image, size: 50, color: Colors.grey),
                          );
                        },
                      ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickKtpImage,
              icon: const Icon(Icons.camera_alt),
              label: Text(_selectedKtpImage != null || _ktpImageUrl != null
                  ? 'Change KTP Photo'
                  : 'Upload KTP Photo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE53E3E),
                side: const BorderSide(color: Color(0xFFE53E3E)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFFE53E3E),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    String? hintText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(icon, color: const Color(0xFFE53E3E)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFE53E3E)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item.replaceAll('_', ' ')),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: const Color(0xFFE53E3E)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE53E3E), width: 2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date != null
                    ? DateFormat('dd MMM yyyy').format(date)
                    : 'Select date',
                style: TextStyle(
                  color: date != null ? Colors.black : Colors.grey,
                ),
              ),
              const Icon(Icons.calendar_today, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
