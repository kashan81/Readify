import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:readify_app/data/models/book_model.dart';
import 'package:readify_app/data/models/category_model.dart';
import 'package:readify_app/data/repositories/book_repository.dart';
import 'package:readify_app/data/repositories/category_repository.dart';
import 'package:readify_app/viewmodel/auth_viewmodel.dart';

class AdminEditBookScreen extends StatefulWidget {
  final Book? book; // If null, it's Add Mode. If provided, it's Edit Mode.

  const AdminEditBookScreen({Key? key, this.book}) : super(key: key);

  @override
  State<AdminEditBookScreen> createState() => _AdminEditBookScreenState();
}

class _AdminEditBookScreenState extends State<AdminEditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedGenre;
  String? _selectedLanguage;

  final List<String> _languages = ['English', 'Urdu', 'Arabic'];

  File? _selectedCoverImage;
  File? _selectedPdfFile;
  String? _pdfFileName;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      _titleController.text = widget.book!.title;
      _authorController.text = widget.book!.author;
      _descriptionController.text = widget.book!.description;
      _selectedGenre = widget.book!.category;
      _selectedLanguage = widget.book!.language;
    }
  }

  Future<void> _pickCoverImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() => _selectedCoverImage = File(image.path));
    }
  }

  Future<void> _pickBookPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedPdfFile = File(result.files.single.path!);
        _pdfFileName = result.files.single.name;
      });
    }
  }

  String _mapGenreToFolder(String genre) {
    if (genre == 'Romance') return 'romance';
    if (genre == 'Mystery') return 'mystery';
    if (genre == 'Fantasy or Sci-fi') return 'fantasy_sci_fi';
    if (genre == 'Motivational and Philosophy') return 'motivational_philosophy';
    return genre.toLowerCase().replaceAll(' ', '_');
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (widget.book == null && (_selectedCoverImage == null || _selectedPdfFile == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select both Cover Image and PDF Book'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bookRepo = Provider.of<BookRepository>(context, listen: false);
      final authVM = Provider.of<AuthViewModel>(context, listen: false);
      
      final uid = authVM.userModel?.uid ?? authVM.user?.uid ?? 'admin';
      final email = authVM.userModel?.email ?? authVM.user?.email;

      String coverUrl = widget.book?.coverUrl ?? '';
      String bookUrl = widget.book?.bookUrl ?? '';

      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final genreFolder = _mapGenreToFolder(_selectedGenre ?? 'others');

      if (_selectedCoverImage != null) {
        final imageFileName = 'cover_${uid}_$timestamp.jpg';
        coverUrl = await bookRepo.uploadCoverImage(_selectedCoverImage!, imageFileName, genreFolder);
      }

      if (_selectedPdfFile != null) {
        final pdfFileName = 'book_${uid}_$timestamp.pdf';
        bookUrl = await bookRepo.uploadBookPdf(_selectedPdfFile!, pdfFileName, genreFolder);
      }

      if (widget.book == null) {
        // Add new book
        final newBook = Book(
          title: _titleController.text.trim(),
          author: _authorController.text.trim(),
          category: _selectedGenre!,
          language: _selectedLanguage!,
          description: _descriptionController.text.trim(),
          imageUrl: '',
          coverUrl: coverUrl,
          bookUrl: bookUrl,
          status: 'approved', // Direct to approved for Admin
          uploaderId: uid,
          uploaderEmail: email,
        );
        await bookRepo.addBook(newBook);
      } else {
        // Update existing book
        await bookRepo.updateBookData(widget.book!.id, {
          'title': _titleController.text.trim(),
          'author': _authorController.text.trim(),
          'category': _selectedGenre,
          'language': _selectedLanguage,
          'description': _descriptionController.text.trim(),
          if (_selectedCoverImage != null) 'coverUrl': coverUrl,
          if (_selectedPdfFile != null) 'bookUrl': bookUrl,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved Successfully!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.book != null;
    final theme = Theme.of(context);
    final categoryRepo = Provider.of<CategoryRepository>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFF0E1B2A),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Book' : 'Add Book', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0E1B2A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2196F3)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                          _buildTextField(controller: _titleController, label: 'Book Title', icon: Icons.book, requiredMsg: 'Required'),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _authorController, label: 'Author Name', icon: Icons.person, requiredMsg: 'Required'),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: StreamBuilder<List<Category>>(
                                  stream: categoryRepo.getCategoriesStream(),
                                  builder: (context, snapshot) {
                                    List<String> items = [];
                                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                      items = snapshot.data!.map((e) => e.name).toList();
                                    } else {
                                      // Fallback to currently selected if API hasn't loaded or is empty
                                      items = _selectedGenre != null ? [_selectedGenre!] : [];
                                    }
                                    
                                    // Make sure selected genre is in the list to avoid dropdown error
                                    if (_selectedGenre != null && !items.contains(_selectedGenre)) {
                                      items.add(_selectedGenre!);
                                    }
                                    
                                    return _buildDropdown(
                                      label: 'Category',
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
                          _buildTextField(controller: _descriptionController, label: 'Description', icon: Icons.description, maxLines: 4, requiredMsg: 'Required'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(isEdit ? 'Update Files (Optional)' : 'Upload Files', theme),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: const Color(0xFF1A1F27),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Cover Image Selection
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 120, width: 85,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0E1B2A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                  image: _selectedCoverImage != null
                                    ? DecorationImage(image: FileImage(_selectedCoverImage!), fit: BoxFit.cover)
                                    : (isEdit && widget.book?.coverUrl != null && widget.book!.coverUrl!.isNotEmpty)
                                        ? DecorationImage(image: NetworkImage(widget.book!.coverUrl!), fit: BoxFit.cover)
                                        : null,
                                ),
                                child: _selectedCoverImage == null && (!isEdit || widget.book?.coverUrl == null || widget.book!.coverUrl!.isEmpty)
                                    ? const Center(child: Icon(Icons.image_outlined, size: 40, color: Colors.grey))
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Cover Image', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('Accepted formats: JPG, PNG', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: _pickCoverImage,
                                      icon: const Icon(Icons.upload_file, color: Colors.white),
                                      label: const Text('Change Image', style: TextStyle(color: Colors.white)),
                                      style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.withOpacity(0.5))),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.grey)),
                          // PDF Selection
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.withOpacity(0.3))),
                                child: const Icon(Icons.picture_as_pdf, color: Color(0xFF2196F3), size: 32),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _pdfFileName ?? (isEdit ? 'Existing PDF Book is attached' : 'No PDF selected'),
                                      style: TextStyle(fontWeight: FontWeight.bold, color: (_pdfFileName != null || isEdit) ? Colors.white : Colors.grey[400]),
                                    ),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: _pickBookPdf,
                                      icon: const Icon(Icons.attach_file, color: Colors.white),
                                      label: const Text('Change PDF', style: TextStyle(color: Colors.white)),
                                      style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.grey.withOpacity(0.5))),
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
                  ElevatedButton(
                    onPressed: _submitData,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: const Color(0xFF2196F3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(isEdit ? 'Save Changes' : 'Add Book', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, required String requiredMsg, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (val) => val == null || val.isEmpty ? requiredMsg : null,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        alignLabelWithHint: maxLines > 1,
        filled: true,
        fillColor: const Color(0xFF0E1B2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDropdown({required String label, required String? value, required List<String> items, required IconData icon, required void Function(String?) onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
      style: const TextStyle(color: Colors.white),
      dropdownColor: const Color(0xFF1A1F27),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF0E1B2A),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      isExpanded: true,
    );
  }
}
