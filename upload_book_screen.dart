import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:readify_app/viewmodel/upload_book_viewmodel.dart';
import 'package:readify_app/viewmodel/auth_viewmodel.dart';
import 'package:readify_app/data/models/category_model.dart';
import 'package:readify_app/data/repositories/category_repository.dart';

class UploadBookScreen extends StatefulWidget {
  const UploadBookScreen({super.key});

  @override
  State<UploadBookScreen> createState() => _UploadBookScreenState();
}

class _UploadBookScreenState extends State<UploadBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedGenre;
  String? _selectedLanguage;

  final List<String> _languages = ['English', 'Urdu', 'Arabic'];

  late UploadBookViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<UploadBookViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _viewModel.clearUploadForm();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _viewModel.clearUploadForm();
    super.dispose();
  }

  void _submitData(BuildContext context, UploadBookViewModel viewModel) async {
    if (_formKey.currentState!.validate()) {
      bool success = await viewModel.submitBook(
        authViewModel: context.read<AuthViewModel>(),
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        genre: _selectedGenre!,
        language: _selectedLanguage!,
        description: _descriptionController.text.trim(),
      );

      if (success && context.mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F27),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Success!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    viewModel.successMessage ?? 'Book uploaded successfully.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back home
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else if (context.mounted && viewModel.errorMessage != null) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F27),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Upload Failed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    viewModel.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        viewModel.clearMessages();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Try Again',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0E1B2A),
      appBar: AppBar(
        title: const Text(
          'Upload Book',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0E1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<UploadBookViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Book Details Section
                  _buildSectionTitle('Book Details', theme),
                  const SizedBox(height: 12),
                  Card(
                elevation: 0,
                color: const Color(0xFF1A1F27),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _titleController,
                        label: 'Book Title',
                        icon: Icons.book,
                        validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _authorController,
                        label: 'Author Name',
                        icon: Icons.person,
                        validator: (value) => value!.isEmpty ? 'Please enter an author name' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: StreamBuilder<List<Category>>(
                              stream: Provider.of<CategoryRepository>(context, listen: false).getCategoriesStream(),
                              builder: (context, snapshot) {
                                List<String> items = [];
                                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                  items = snapshot.data!.map((e) => e.name).toList();
                                } else {
                                  items = _selectedGenre != null ? [_selectedGenre!] : [];
                                }
                                
                                if (_selectedGenre != null && !items.contains(_selectedGenre)) {
                                  items.add(_selectedGenre!);
                                }
                                
                                return _buildDropdown(
                                  label: 'Genre',
                                  value: items.contains(_selectedGenre) ? _selectedGenre : null,
                                  items: items,
                                  icon: Icons.category,
                                  onChanged: (val) => setState(() => _selectedGenre = val),
                                );
                              }
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Language',
                              value: _selectedLanguage,
                              items: _languages,
                              icon: Icons.language,
                              onChanged: (val) => setState(() => _selectedLanguage = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        icon: Icons.description,
                        maxLines: 4,
                        validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Upload Files Section
              _buildSectionTitle('Upload Files', theme),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: const Color(0xFF1A1F27),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                        // Cover Image Preview & Picker
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 120,
                            width: 85,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E1B2A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                              image: viewModel.selectedCoverImage != null
                                  ? DecorationImage(
                                      image: FileImage(viewModel.selectedCoverImage!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: viewModel.selectedCoverImage == null
                                ? const Center(
                                    child: Icon(
                                      Icons.image_outlined,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cover Image',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Accepted formats: JPG, PNG',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: viewModel.pickCoverImage,
                                  icon: const Icon(Icons.upload_file, color: Colors.white),
                                  label: const Text('Select Image', style: TextStyle(color: Colors.white)),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Divider(color: Colors.grey),
                      ),

                      // PDF File Selection
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E1B2A),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.withOpacity(0.3)),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf,
                              color: Color(0xFF2196F3),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  viewModel.pdfFileName ?? 'No PDF selected',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: viewModel.pdfFileName != null ? FontWeight.bold : FontWeight.normal,
                                    color: viewModel.pdfFileName != null ? Colors.white : Colors.grey[400],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: viewModel.pickBookPdf,
                                  icon: const Icon(Icons.attach_file, color: Colors.white),
                                  label: const Text('Select Book (PDF)', style: TextStyle(color: Colors.white)),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: () => _submitData(context, viewModel),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text(
                  'Submit Book',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    },
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFF0E1B2A),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Required' : null,
      style: const TextStyle(color: Colors.white),
      dropdownColor: const Color(0xFF1A1F27),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFF0E1B2A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      isExpanded: true,
    );
  }
}
