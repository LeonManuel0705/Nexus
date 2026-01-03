import sounddevice as sd
import numpy as np
import wave
import threading
import os
import time
import queue
from datetime import datetime
from scipy import signal

AUDIO_TEMP_PATH = os.path.expanduser("~/Documents/voice-notes/audio_temp")

CHUNK_DURATION = 3.0
MIN_SPEECH_ENERGY = 0.005
SILENCE_THRESHOLD = 0.8
MAX_DEVICE_RETRIES = 3
DEVICE_RETRY_DELAY = 0.5


class AudioRecorder:
    def __init__(self, sample_rate=16000, channels=1):
        self.sample_rate = sample_rate
        self.channels = channels
        self.recording = False
        self.audio_data = []
        self.stream = None
        self.start_time = None
        self.last_error = None
        self.device_id = None

        self.audio_queue = queue.Queue()
        self.pending_audio = []
        self.chunk_samples = 0
        self.speech_detected = False
        self.silence_samples = 0

        self.enrollment_queue = queue.Queue()
        self.enrollment_buffer = []
        self.enrollment_samples = 0

    def _calculate_energy(self, audio):
        return np.sqrt(np.mean(audio ** 2))

    def _has_speech(self, audio):
        energy = self._calculate_energy(audio)
        return energy > MIN_SPEECH_ENERGY

    def _audio_callback(self, indata, frames, time_info, status):
        if status:
            print(f"Audio status: {status}")

        if not self.recording:
            return

        audio = indata.copy().flatten()
        self.audio_data.append(indata.copy())

        if len(self.audio_data) % 50 == 1:
            energy = self._calculate_energy(audio)
            print(f"[Recorder] Callback: {len(audio)} samples, energy={energy:.4f}")

        self.enrollment_buffer.append(audio)
        self.enrollment_samples += len(audio)
        enrollment_duration = self.enrollment_samples / self.sample_rate

        if enrollment_duration >= CHUNK_DURATION:
            enrollment_audio = np.concatenate(self.enrollment_buffer)
            enrollment_audio = self._enhance_audio(enrollment_audio)
            self.enrollment_queue.put(enrollment_audio)
            print(f"[Recorder] Enrollment chunk queued: {len(enrollment_audio)} samples ({enrollment_duration:.1f}s)")
            self.enrollment_buffer = []
            self.enrollment_samples = 0

        has_speech = self._has_speech(audio)

        if has_speech:
            self.speech_detected = True
            self.silence_samples = 0
        else:
            self.silence_samples += len(audio)

        self.pending_audio.append(audio)
        self.chunk_samples += len(audio)

        chunk_duration = self.chunk_samples / self.sample_rate
        silence_duration = self.silence_samples / self.sample_rate

        should_emit = False

        if chunk_duration >= CHUNK_DURATION and self.speech_detected:
            should_emit = True

        if self.speech_detected and silence_duration >= SILENCE_THRESHOLD and chunk_duration >= 1.0:
            should_emit = True

        if should_emit and self.speech_detected:
            chunk_audio = np.concatenate(self.pending_audio)

            chunk_audio = self._enhance_audio(chunk_audio)

            self.audio_queue.put(chunk_audio)

            self.pending_audio = []
            self.chunk_samples = 0
            self.speech_detected = False
            self.silence_samples = 0

    def _enhance_audio(self, audio):
        audio = audio - np.mean(audio)

        nyquist = self.sample_rate / 2
        low_freq = 80 / nyquist
        high_freq = 8000 / nyquist

        if low_freq < 1 and high_freq < 1:
            b, a = signal.butter(4, [low_freq, high_freq], btype='band')
            audio = signal.filtfilt(b, a, audio)

        max_val = np.max(np.abs(audio))
        if max_val > 0:
            audio = audio / max_val * 0.9

        return audio

    def _find_working_device(self):
        try:
            sd._terminate()
            sd._initialize()
        except Exception:
            pass

        try:
            default_device = sd.default.device[0]
            if default_device is not None:
                device_info = sd.query_devices(default_device)
                if device_info['max_input_channels'] > 0:
                    return default_device
        except Exception:
            pass

        try:
            devices = sd.query_devices()
            for i, device in enumerate(devices):
                if device['max_input_channels'] > 0:
                    try:
                        test_stream = sd.InputStream(
                            device=i,
                            samplerate=self.sample_rate,
                            channels=1,
                            dtype=np.float32,
                            blocksize=1024
                        )
                        test_stream.close()
                        return i
                    except Exception:
                        continue
        except Exception:
            pass

        return None

    def _get_supported_sample_rate(self, device_id):
        preferred_rates = [16000, 44100, 48000, 22050, 8000]

        for rate in preferred_rates:
            try:
                sd.check_input_settings(device=device_id, samplerate=rate, channels=1)
                return rate
            except Exception:
                continue

        try:
            device_info = sd.query_devices(device_id)
            return int(device_info['default_samplerate'])
        except Exception:
            return 16000

    def start_recording(self, on_chunk_ready=None):
        if self.recording:
            return False

        self.audio_data = []
        self.pending_audio = []
        self.chunk_samples = 0
        self.speech_detected = False
        self.silence_samples = 0
        self.last_error = None

        self.enrollment_buffer = []
        self.enrollment_samples = 0

        while not self.audio_queue.empty():
            try:
                self.audio_queue.get_nowait()
            except Exception:
                break

        while not self.enrollment_queue.empty():
            try:
                self.enrollment_queue.get_nowait()
            except Exception:
                break

        for attempt in range(MAX_DEVICE_RETRIES):
            try:
                device_id = self._find_working_device()
                if device_id is None:
                    raise Exception("No audio input device found")

                actual_sample_rate = self._get_supported_sample_rate(device_id)
                if actual_sample_rate != self.sample_rate:
                    print(f"Using sample rate {actual_sample_rate}")
                    self.sample_rate = actual_sample_rate

                self.stream = sd.InputStream(
                    device=device_id,
                    samplerate=self.sample_rate,
                    channels=self.channels,
                    dtype=np.float32,
                    callback=self._audio_callback,
                    blocksize=int(self.sample_rate * 0.1)
                )
                self.stream.start()
                self.recording = True
                self.start_time = time.time()
                print(f"Recording started on device {device_id} at {self.sample_rate}Hz")
                return True

            except sd.PortAudioError as e:
                self.last_error = str(e)
                print(f"PortAudio error (attempt {attempt + 1}/{MAX_DEVICE_RETRIES}): {e}")

                try:
                    sd._terminate()
                    time.sleep(DEVICE_RETRY_DELAY)
                    sd._initialize()
                except Exception:
                    pass

                if attempt < MAX_DEVICE_RETRIES - 1:
                    time.sleep(DEVICE_RETRY_DELAY)

            except Exception as e:
                self.last_error = str(e)
                print(f"Recording error (attempt {attempt + 1}/{MAX_DEVICE_RETRIES}): {e}")
                if attempt < MAX_DEVICE_RETRIES - 1:
                    time.sleep(DEVICE_RETRY_DELAY)

        print(f"Failed to start recording after {MAX_DEVICE_RETRIES} attempts")
        return False

    def get_next_chunk(self, timeout=0.5):
        try:
            return self.audio_queue.get(timeout=timeout)
        except queue.Empty:
            return None

    def get_enrollment_chunk(self, timeout=0.5):
        try:
            return self.enrollment_queue.get(timeout=timeout)
        except queue.Empty:
            return None

    def stop_recording(self) -> tuple:
        if not self.recording:
            return None, 0

        self.recording = False
        duration = time.time() - self.start_time

        if self.stream:
            self.stream.stop()
            self.stream.close()
            self.stream = None

        if len(self.pending_audio) > 0:
            chunk_audio = np.concatenate(self.pending_audio)
            chunk_audio = self._enhance_audio(chunk_audio)
            self.audio_queue.put(chunk_audio)

        if len(self.enrollment_buffer) > 0:
            enrollment_audio = np.concatenate(self.enrollment_buffer)
            enrollment_audio = self._enhance_audio(enrollment_audio)
            self.enrollment_queue.put(enrollment_audio)

        if not self.audio_data:
            return None, 0

        audio_array = np.concatenate(self.audio_data, axis=0)
        audio_array = self._enhance_audio(audio_array.flatten())

        os.makedirs(AUDIO_TEMP_PATH, exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filepath = os.path.join(AUDIO_TEMP_PATH, f"recording_{timestamp}.wav")

        audio_int16 = (audio_array * 32767).astype(np.int16)

        with wave.open(filepath, 'wb') as wf:
            wf.setnchannels(self.channels)
            wf.setsampwidth(2)
            wf.setframerate(self.sample_rate)
            wf.writeframes(audio_int16.tobytes())

        return filepath, duration

    def is_recording(self) -> bool:
        return self.recording

    def get_duration(self) -> float:
        if self.recording and self.start_time:
            return time.time() - self.start_time
        return 0

    def get_last_error(self) -> str:
        return self.last_error


def refresh_audio_devices():
    try:
        sd._terminate()
        time.sleep(0.2)
        sd._initialize()
        return True
    except Exception as e:
        print(f"Failed to refresh audio devices: {e}")
        return False


def list_audio_devices():
    try:
        devices = sd.query_devices()
    except Exception:
        refresh_audio_devices()
        devices = sd.query_devices()

    input_devices = []
    for i, device in enumerate(devices):
        if device['max_input_channels'] > 0:
            usable = True
            try:
                sd.check_input_settings(device=i, channels=1)
            except Exception:
                usable = False

            input_devices.append({
                'id': i,
                'name': device['name'],
                'channels': device['max_input_channels'],
                'sample_rate': device['default_samplerate'],
                'usable': usable
            })
    return input_devices


def get_default_input_device():
    try:
        device_id = sd.default.device[0]
        device = sd.query_devices(device_id)
        return {
            'id': device_id,
            'name': device['name'],
            'channels': device['max_input_channels'],
            'sample_rate': device['default_samplerate']
        }
    except Exception:
        return None


_recorder = None

def get_recorder() -> AudioRecorder:
    global _recorder
    if _recorder is None:
        _recorder = AudioRecorder()
    return _recorder
