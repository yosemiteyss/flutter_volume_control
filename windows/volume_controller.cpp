#include "include/flutter_volume_controller/volume_controller.h"

#include <windows.h>
#include <mmdeviceapi.h>

namespace flutter_volume_controller {
	VolumeController::VolumeController() : endpoint_volume(NULL), volume_notification(NULL) {}

	VolumeController& VolumeController::GetInstance() {
		static VolumeController instance;
		return instance;
	}

	bool VolumeController::RegisterController() {
		HRESULT hr = E_FAIL;
		IMMDevice* default_device = NULL;
		IMMDeviceEnumerator* device_enumator = NULL;

		CoInitialize(NULL);

		hr = CoCreateInstance(__uuidof(MMDeviceEnumerator), NULL, CLSCTX_INPROC_SERVER, __uuidof(IMMDeviceEnumerator),
			(LPVOID*)&device_enumator);
		if (FAILED(hr)) {
			return false;
		}

		hr = device_enumator->GetDefaultAudioEndpoint(eRender, eConsole, &default_device);
		if (FAILED(hr)) {
			return false;
		}

		hr = default_device->Activate(__uuidof(IAudioEndpointVolume), CLSCTX_INPROC_SERVER, NULL,
			(LPVOID*)&endpoint_volume);
		if (FAILED(hr)) {
			return false;
		}

		return true;
	}

	bool VolumeController::RegisterNotification(VolumeCallback callback) {
		HRESULT hr = E_FAIL;

		if (!callback) {
			return false;
		}

		if (endpoint_volume) {
			volume_notification = new VolumeNotification(callback);
			hr = endpoint_volume->RegisterControlChangeNotify(volume_notification);
			if (FAILED(hr)) {
				return false;
			}
		}

		return true;
	}

	void VolumeController::DisposeController() {
		if (endpoint_volume) {
			DisposeNotification();
			endpoint_volume->Release();
		}

		CoUninitialize();
	}

	void VolumeController::DisposeNotification() {
		if (volume_notification) {
			if (endpoint_volume) {
				endpoint_volume->UnregisterControlChangeNotify(volume_notification);
			}
			volume_notification->Release();
		}
	}

	bool VolumeController::SetVolume(float volume) {
		HRESULT hr = E_FAIL;

		if (endpoint_volume) {
			if (!SetMute(false)) {
				return false;
			}
			
			hr = endpoint_volume->SetMasterVolumeLevelScalar(volume, NULL);
			if (FAILED(hr)) {
				return false;
			}
		}

		return true;
	}

	bool VolumeController::SetMaxVolume() {
		HRESULT hr = E_FAIL;
		UINT current_step, step_count;

		if (endpoint_volume) {
			hr = endpoint_volume->GetVolumeStepInfo(&current_step, &step_count);
			if (FAILED(hr)) {
				return false;
			}

			if (!SetMute(false)) {
				return false;
			}

			for (UINT index = current_step; index < step_count; index++) {
				if (!SetVolumeUpBySystemStep()) {
					return false;
				}
			}
		}

		return true;
	}

	bool VolumeController::SetMinVolume() {
		HRESULT hr = E_FAIL;
		UINT current_step, step_count;

		if (endpoint_volume) {
			hr = endpoint_volume->GetVolumeStepInfo(&current_step, &step_count);
			if (FAILED(hr)) {
				return false;
			}

			if (!SetMute(false)) {
				return false;
			}

			for (UINT index = current_step; index > 0; index--) {
				if (!SetVolumeDownBySystemStep()) {
					return false;
				}
			}
		}

		return true;
	}

	bool VolumeController::SetVolumeUp(float step) {
		HRESULT hr = E_FAIL;

		if (endpoint_volume) {
			auto current_volume = GetCurrentVolume();
			if (!current_volume.has_value()) {
				return false;
			}

			float volume = current_volume.value();
			float target_step = (1 - volume) < step ? 1 : volume + step;

			hr = endpoint_volume->SetMasterVolumeLevelScalar(target_step, NULL);
			if (FAILED(hr)) {
				return false;
			}
		}

		return true;
	}

	bool VolumeController::SetVolumeDown(float step) {
		HRESULT hr = E_FAIL;

		if (endpoint_volume) {
			auto current_volume = GetCurrentVolume();
			if (!current_volume.has_value()) {
				return false;
			}

			float volume = current_volume.value();
			float target_step = volume < step ? 0 : volume - step;

			hr = endpoint_volume->SetMasterVolumeLevelScalar(target_step, NULL);
			if (FAILED(hr)) {
				return false;
			}
		}

		return true;
	}

	bool VolumeController::SetVolumeUpBySystemStep() {
		HRESULT hr = E_FAIL;

		if (endpoint_volume) {
			hr = endpoint_volume->VolumeStepUp(NULL);
			if (FAILED(hr)) {
				return false;
			}
		}

		return true;
	}

	bool VolumeController::SetVolumeDownBySystemStep() {
		HRESULT hr = E_FAIL;

		if (endpoint_volume) {
			hr = endpoint_volume->VolumeStepDown(NULL);
			if (FAILED(hr)) {
				return false;
			}
		}

		return true;
	}

	bool VolumeController::SetMute(bool is_mute) {
		HRESULT hr = E_FAIL;

		if (is_mute) {
			hr = endpoint_volume->SetMute(TRUE, NULL);
		}
		else {
			hr = endpoint_volume->SetMute(FALSE, NULL);
		}

		if (FAILED(hr)) {
			return false;
		}

		return true;
	}

	std::optional<float> VolumeController::GetCurrentVolume() {
		HRESULT hr = E_FAIL;
		UINT current_step, step_count;
		float current_volume = 0.0f;

		if (endpoint_volume) {
			hr = endpoint_volume->GetVolumeStepInfo(&current_step, &step_count);
			if (FAILED(hr)) {
				return std::nullopt;
			}
			current_volume = current_step * 1.0f / step_count;
		}

		return current_volume;
	}
}
