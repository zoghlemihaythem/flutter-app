import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/event_model.dart';
import '../providers/event_provider.dart';

/// Form screen for creating and editing events
class EventFormScreen extends StatefulWidget {
  final Event? event;

  const EventFormScreen({super.key, this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _capacityController;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _category;
  late bool _isPublished;

  bool get isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(text: event?.description ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');
    _capacityController = TextEditingController(
      text: event?.capacity.toString() ?? '100',
    );
    _startDate = event?.date ?? DateTime.now().add(const Duration(days: 7));
    _endDate = event?.endDate ?? DateTime.now().add(const Duration(days: 7, hours: 4));
    _category = event?.category ?? EventCategories.all.first;
    _isPublished = event?.isPublished ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
      );
      if (time != null) {
        setState(() {
          final newDateTime = DateTime(
            picked.year, picked.month, picked.day, time.hour, time.minute,
          );
          if (isStart) {
            _startDate = newDateTime;
            if (_endDate.isBefore(_startDate)) {
              _endDate = _startDate.add(const Duration(hours: 2));
            }
          } else {
            _endDate = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final eventProvider = context.read<EventProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    if (isEditing) {
      final updated = widget.event!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _startDate,
        endDate: _endDate,
        location: _locationController.text.trim(),
        capacity: int.tryParse(_capacityController.text) ?? 100,
        category: _category,
        isPublished: _isPublished,
      );
      await eventProvider.updateEvent(updated);
    } else {
      await eventProvider.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        date: _startDate,
        endDate: _endDate,
        location: _locationController.text.trim(),
        organizerId: user.id,
        organizerName: user.name,
        capacity: int.tryParse(_capacityController.text) ?? 100,
        category: _category,
        isPublished: _isPublished,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Event' : 'Create Event'),
      ),
      body: LoadingOverlay(
        isLoading: eventProvider.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _titleController,
                  label: 'Event Title',
                  hint: 'Enter event title',
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Describe your event',
                  maxLines: 4,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: EventCategories.all.map((c) => 
                    DropdownMenuItem(value: c, child: Text(c))
                  ).toList(),
                  onChanged: (v) => setState(() => _category = v!),
                ),
                const SizedBox(height: 16),
                _DateSelector(
                  label: 'Start Date & Time',
                  date: _startDate,
                  onTap: () => _selectDate(true),
                ),
                const SizedBox(height: 16),
                _DateSelector(
                  label: 'End Date & Time',
                  date: _endDate,
                  onTap: () => _selectDate(false),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _locationController,
                  label: 'Location',
                  hint: 'Event venue',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _capacityController,
                  label: 'Capacity',
                  hint: 'Max attendees',
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.people_outlined),
                  validator: (v) {
                    if (v?.isEmpty == true) return 'Required';
                    if (int.tryParse(v!) == null) return 'Invalid number';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SwitchListTile(
                  value: _isPublished,
                  onChanged: (v) => setState(() => _isPublished = v),
                  title: const Text('Publish immediately'),
                  subtitle: const Text('Make event visible to participants'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: isEditing ? 'Save Changes' : 'Create Event',
                  onPressed: _saveEvent,
                  isLoading: eventProvider.isLoading,
                  useGradient: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateSelector({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          suffixIcon: const Icon(Icons.edit),
        ),
        child: Text(DateFormat('MMM dd, yyyy • HH:mm').format(date)),
      ),
    );
  }
}
