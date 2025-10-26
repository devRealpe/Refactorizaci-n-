// lib/presentation/pages/formulario/formulario_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../injection_container.dart' as di;
import '../../blocs/config/config_bloc.dart';
import '../../blocs/formulario/formulario_bloc.dart';
import '../../theme/medical_colors.dart';
import 'widgets/form_header.dart';
import 'widgets/form_fields.dart';
import 'widgets/form_audio_picker.dart';
import 'widgets/upload_overlay.dart';

class FormularioPage extends StatelessWidget {
  const FormularioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => di.sl<FormularioBloc>(),
        ),
      ],
      child: const _FormularioPageView(),
    );
  }
}

class _FormularioPageView extends StatefulWidget {
  const _FormularioPageView();

  @override
  State<_FormularioPageView> createState() => _FormularioPageViewState();
}

class _FormularioPageViewState extends State<_FormularioPageView> {
  final _formKey = GlobalKey<FormState>();

  // Controllers de estado del formulario
  String? _hospital;
  String? _consultorio;
  String? _estado;
  String? _focoAuscultacion;
  DateTime? _selectedDate;
  String? _observaciones;
  String? _audioFilePath;

  // Configuración de hospital por defecto
  static const String _hospitalPorDefecto = 'Departamental';
  static const bool _mostrarSelectorHospital = false;

  @override
  void initState() {
    super.initState();
    if (!_mostrarSelectorHospital) {
      _hospital = _hospitalPorDefecto;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FormularioBloc, FormularioState>(
      listener: _handleFormularioStateChanges,
      builder: (context, formularioState) {
        return BlocBuilder<ConfigBloc, ConfigState>(
          builder: (context, configState) {
            return Scaffold(
              backgroundColor: MedicalColors.backgroundLight,
              appBar: _buildAppBar(context),
              body: Stack(
                children: [
                  _buildFormContent(context, configState),
                  if (formularioState is FormularioEnviando)
                    UploadOverlay(
                      progress: formularioState.progress,
                      status: formularioState.status,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return FormHeader(
      onInfoPressed: () => _showInfoDialog(context),
    );
  }

  Widget _buildFormContent(BuildContext context, ConfigState configState) {
    if (configState is ConfigLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (configState is ConfigError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: MedicalColors.errorRed),
            const SizedBox(height: 16),
            Text(
              'Error al cargar configuración',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(configState.message),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<ConfigBloc>().add(CargarConfiguracionEvent());
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (configState is! ConfigLoaded) {
      return const SizedBox.shrink();
    }

    final config = configState.config;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            FormFields(
              config: config,
              hospital: _hospital,
              consultorio: _consultorio,
              estado: _estado,
              focoAuscultacion: _focoAuscultacion,
              selectedDate: _selectedDate,
              observaciones: _observaciones,
              mostrarSelectorHospital: _mostrarSelectorHospital,
              onHospitalChanged: _onHospitalChanged,
              onConsultorioChanged: (value) {
                setState(() => _consultorio = value);
              },
              onEstadoChanged: (value) {
                setState(() => _estado = value);
              },
              onFocoChanged: (value) {
                setState(() => _focoAuscultacion = value);
              },
              onDateChanged: (value) {
                setState(() => _selectedDate = value);
              },
              onObservacionesChanged: (value) {
                setState(() => _observaciones = value);
              },
            ),
            const SizedBox(height: 20),
            FormAudioPicker(
              onFileSelected: (filePath) {
                setState(() => _audioFilePath = filePath);
              },
            ),
            const SizedBox(height: 32),
            _buildSubmitButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _onHospitalChanged(String? value) {
    setState(() {
      _hospital = value;
      _consultorio = null; // Resetear consultorio al cambiar hospital
    });

    if (value != null) {
      final config = context.read<ConfigBloc>().state;
      if (config is ConfigLoaded) {
        final hospital = config.config.getHospitalPorNombre(value);
        if (hospital != null) {
          context.read<ConfigBloc>().add(
                ObtenerConsultoriosPorHospitalEvent(hospital.codigo),
              );
        }
      }
    }
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: MedicalColors.primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha((0.2 * 255).toInt()),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, size: 18),
            ),
            const SizedBox(width: 12),
            const Text(
              'ENVIAR DATOS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    // Verificar conexión
    final connectivityResults = await Connectivity().checkConnectivity();
    if (connectivityResults.contains(ConnectivityResult.none)) {
      _showError(AppConstants.errorNoInternet);
      return;
    }

    // Validar formulario
    if (!_formKey.currentState!.validate()) {
      _showError(AppConstants.errorCamposIncompletos);
      return;
    }

    // Validar archivo de audio
    if (_audioFilePath == null || !File(_audioFilePath!).existsSync()) {
      _showError(AppConstants.errorArchivoNoSeleccionado);
      return;
    }

    // Obtener códigos de la configuración
    final configState = context.read<ConfigBloc>().state;
    if (configState is! ConfigLoaded) {
      _showError('Configuración no cargada');
      return;
    }

    final config = configState.config;
    final hospitalEntity = config.getHospitalPorNombre(_hospital!);
    final consultorioEntity = config.getConsultorioPorNombre(_consultorio!);
    final focoEntity = config.getFocoPorNombre(_focoAuscultacion!);

    if (hospitalEntity == null ||
        consultorioEntity == null ||
        focoEntity == null) {
      _showError('Error al obtener configuración');
      return;
    }

    // Enviar formulario
    context.read<FormularioBloc>().add(
          EnviarFormularioEvent(
            fechaNacimiento: _selectedDate!,
            hospital: _hospital!,
            codigoHospital: hospitalEntity.codigo,
            consultorio: _consultorio!,
            codigoConsultorio: consultorioEntity.codigo,
            estado: _estado!,
            focoAuscultacion: _focoAuscultacion!,
            codigoFoco: focoEntity.codigo,
            observaciones: _observaciones,
            audioFile: File(_audioFilePath!),
          ),
        );
  }

  void _handleFormularioStateChanges(
    BuildContext context,
    FormularioState state,
  ) {
    if (state is FormularioEnviadoExitosamente) {
      _showSuccess(state.mensaje);
      _resetForm();
      context.read<FormularioBloc>().add(ResetFormularioEvent());
    } else if (state is FormularioError) {
      _showError(state.mensaje);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _hospital = _hospitalPorDefecto;
      _consultorio = null;
      _estado = null;
      _focoAuscultacion = null;
      _selectedDate = null;
      _observaciones = null;
      _audioFilePath = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: MedicalColors.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: MedicalColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    // Implementar el diálogo de información
    // Usar el código del form_state.dart original
  }
}
