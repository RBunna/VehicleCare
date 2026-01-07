import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vehicle_care/data/models/vehicle.dart';
import 'package:vehicle_care/data/repositories/vehicle_repository.dart';
import 'package:vehicle_care/data/db/app_database.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nicknameController = TextEditingController();
  final _odometerController = TextEditingController();
  final _licensePlateController = TextEditingController();

  File? _vehiclePhotoFile;
  final ImagePicker _picker = ImagePicker();

  void _pickImage() async {
    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      final XFile? pickedFile = await _picker.pickImage(source: result);

      if (pickedFile != null) {
        setState(() {
          _vehiclePhotoFile = File(pickedFile.path);
        });
      }
    }
  }

  void _saveVehicle() async {
    final FormState? formState = _formKey.currentState;

    if (formState != null && formState.validate()) {
      formState.save();

      final double initialOdo =
          double.tryParse(_odometerController.text) ?? 0.0;

      final newVehicle = Vehicle(
        nickname: _nicknameController.text,
        initialOdometer: initialOdo,

        licensePlate: _licensePlateController.text.isNotEmpty
            ? _licensePlateController.text
            : null,

        photoPath: _vehiclePhotoFile?.path,
      );

      final dbInstance = await AppDatabase().database;
      final repo = VehicleRepository(dbInstance);

      await repo.createVehicle(newVehicle);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _odometerController.dispose();
    _licensePlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Vehicle")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: _vehiclePhotoFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt, size: 50),
                          Text(
                            "Add Vehicle Photo (Optional)",

                            style:
                                Theme.of(context).textTheme.bodySmall ??
                                const TextStyle(fontSize: 12),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _vehiclePhotoFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(labelText: 'Nickname *'),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Nickname is required' : null,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _odometerController,
              decoration: const InputDecoration(
                labelText: 'Initial Odometer *',
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty
                  ? 'Odometer is required'
                  : (double.tryParse(v) == null ? 'Must be a number' : null),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _licensePlateController,
              decoration: const InputDecoration(
                labelText: 'License Plate (Optional)',
              ),
              keyboardType: TextInputType.text,
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _saveVehicle,
              child: const Text("Save Vehicle"),
            ),

            TextButton(
              onPressed: () {},
              child: const Text("Set up maintenance reminders now."),
            ),
          ],
        ),
      ),
    );
  }
}
