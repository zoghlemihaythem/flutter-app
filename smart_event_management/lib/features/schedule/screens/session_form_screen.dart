import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../models/session_model.dart';
import '../providers/schedule_provider.dart';

/// Form for creating/editing sessions
class SessionFormScreen extends StatefulWidget {
  final String eventId;
  final Session? session;

  const SessionFormScreen({super.key, required this.eventId, this.session});

  @override
  State<SessionFormScreen> createState() => _SessionFormScreenState();
}

class _SessionFormScreenState extends State<SessionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _speakerController;
  late final TextEditingController _speakerBioController;
  late final TextEditingController _locationController;
  late DateTime _startTime;
  late DateTime _endTime;

  bool get isEditing => widget.session != null;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _titleController = TextEditingController(text: s?.title ?? '');
    _descriptionController = TextEditingController(text: s?.description ?? '');
    _speakerController = TextEditingController(text: s?.speaker ?? '');
    _speakerBioController = TextEditingController(text: s?.speakerBio ?? '');
    _locationController = TextEditingController(text: s?.location ?? '');
    _startTime = s?.startTime ?? DateTime.now().add(const Duration(days: 1));
    _endTime = s?.endTime ?? DateTime.now().add(const Duration(days: 1, hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _speakerController.dispose();
    _speakerBioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final initialDate = isStart ? _startTime : _endTime;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;
    setState(() {
      final dt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (isStart) {
        _startTime = dt;
        if (_endTime.isBefore(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      } else {
        _endTime = dt;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ScheduleProvider>();
    if (isEditing) {
      await provider.updateSession(widget.session!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        speaker: _speakerController.text.trim(),
        speakerBio: _speakerBioController.text.trim().isEmpty
            ? null
            : _speakerBioController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
      ));
    } else {
      await provider.createSession(
        eventId: widget.eventId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        speaker: _speakerController.text.trim(),
        speakerBio: _speakerBioController.text.trim().isEmpty
            ? null
            : _speakerBioController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        startTime: _startTime,
        endTime: _endTime,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScheduleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Session' : 'Add Session'),
      ),
      body: LoadingOverlay(
        isLoading: provider.isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _titleController,
                  label: 'Session Title',
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _speakerController,
                  label: 'Speaker',
                  prefixIcon: const Icon(Icons.person),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _speakerBioController,
                  label: 'Speaker Bio (optional)',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _locationController,
                  label: 'Room/Location (optional)',
                  prefixIcon: const Icon(Icons.location_on),
                ),
                const SizedBox(height: 16),
                _TimeSelector(
                  label: 'Start Time',
                  time: _startTime,
                  onTap: () => _selectTime(true),
                ),
                const SizedBox(height: 16),
                _TimeSelector(
                  label: 'End Time',
                  time: _endTime,
                  onTap: () => _selectTime(false),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: isEditing ? 'Save Changes' : 'Add Session',
                  onPressed: _save,
                  isLoading: provider.isLoading,
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

class _TimeSelector extends StatelessWidget {
  final String label;
  final DateTime time;
  final VoidCallback onTap;

  const _TimeSelector({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.access_time),
          suffixIcon: const Icon(Icons.edit),
        ),
        child: Text(DateFormat('MMM dd, yyyy • HH:mm').format(time)),
      ),
    );
  }
}
