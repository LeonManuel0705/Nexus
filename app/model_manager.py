import threading
import os
from pathlib import Path
from typing import Optional, Dict, Callable
import time

WHISPER_MODEL = "small"
MLX_MODEL = "mlx-community/Qwen2.5-0.5B-Instruct-4bit"

TITANET_MODEL = "nvidia/speakerverification_en_titanet_large"
SPEECHBRAIN_MODEL = "speechbrain/spkrec-ecapa-voxceleb"

PROGRESS_UPDATE_INTERVAL = 1.0

_download_progress: Dict[str, dict] = {}
_download_lock = threading.Lock()
_download_stats: Dict[str, dict] = {}


def get_download_progress() -> Dict[str, dict]:
    with _download_lock:
        return dict(_download_progress)


def set_download_progress(model_name: str, progress: float, status: str, message: str = ""):
    with _download_lock:
        _download_progress[model_name] = {
            'progress': progress,
            'status': status,
            'message': message
        }


def clear_download_progress(model_name: str):
    with _download_lock:
        if model_name in _download_progress:
            del _download_progress[model_name]
        if model_name in _download_stats:
            del _download_stats[model_name]


def init_download_stats(model_name: str, total_size_mb: float = 0):
    with _download_lock:
        _download_stats[model_name] = {
            'start_time': time.time(),
            'last_update': time.time(),
            'bytes_downloaded': 0,
            'total_bytes': int(total_size_mb * 1024 * 1024),
            'speed_history': [],
        }


def update_download_stats(model_name: str, bytes_downloaded: int, total_bytes: int = 0):
    with _download_lock:
        if model_name not in _download_stats:
            _download_stats[model_name] = {
                'start_time': time.time(),
                'last_update': time.time(),
                'bytes_downloaded': 0,
                'total_bytes': total_bytes,
                'speed_history': [],
            }

        stats = _download_stats[model_name]
        now = time.time()
        time_diff = now - stats['last_update']

        if time_diff > 0:
            bytes_diff = bytes_downloaded - stats['bytes_downloaded']
            current_speed = bytes_diff / time_diff if time_diff > 0 else 0

            stats['speed_history'].append(current_speed)
            if len(stats['speed_history']) > 5:
                stats['speed_history'].pop(0)

        stats['bytes_downloaded'] = bytes_downloaded
        stats['last_update'] = now
        if total_bytes > 0:
            stats['total_bytes'] = total_bytes


def get_download_speed(model_name: str) -> dict:
    with _download_lock:
        if model_name not in _download_stats:
            return {'speed': 0, 'speed_str': '', 'progress': 0, 'eta': ''}

        stats = _download_stats[model_name]

        if stats['speed_history']:
            avg_speed = sum(stats['speed_history']) / len(stats['speed_history'])
        else:
            elapsed = time.time() - stats['start_time']
            avg_speed = stats['bytes_downloaded'] / elapsed if elapsed > 0 else 0

        if avg_speed >= 1024 * 1024:
            speed_str = f"{avg_speed / (1024 * 1024):.1f} MB/s"
        elif avg_speed >= 1024:
            speed_str = f"{avg_speed / 1024:.1f} KB/s"
        else:
            speed_str = f"{avg_speed:.0f} B/s"

        progress = 0
        if stats['total_bytes'] > 0:
            progress = min(99, int(stats['bytes_downloaded'] / stats['total_bytes'] * 100))

        eta_str = ''
        if avg_speed > 0 and stats['total_bytes'] > 0:
            remaining = stats['total_bytes'] - stats['bytes_downloaded']
            eta_seconds = remaining / avg_speed
            if eta_seconds < 60:
                eta_str = f"{int(eta_seconds)}s"
            elif eta_seconds < 3600:
                eta_str = f"{int(eta_seconds / 60)}m {int(eta_seconds % 60)}s"
            else:
                eta_str = f"{int(eta_seconds / 3600)}h {int((eta_seconds % 3600) / 60)}m"

        return {
            'speed': avg_speed,
            'speed_str': speed_str,
            'progress': progress,
            'eta': eta_str,
            'downloaded_mb': stats['bytes_downloaded'] / (1024 * 1024),
            'total_mb': stats['total_bytes'] / (1024 * 1024),
        }


def check_whisper_model() -> dict:
    try:
        from faster_whisper import WhisperModel
        cache_dir = Path.home() / ".cache" / "huggingface" / "hub"
        model_patterns = [f"*whisper*{WHISPER_MODEL}*", f"*{WHISPER_MODEL}*"]

        model_found = False
        for pattern in model_patterns:
            if list(cache_dir.glob(pattern)):
                model_found = True
                break

        if not model_found:
            try:
                import huggingface_hub
                model_info = huggingface_hub.scan_cache_dir()
                for repo in model_info.repos:
                    if WHISPER_MODEL in repo.repo_id.lower() or 'whisper' in repo.repo_id.lower():
                        model_found = True
                        break
            except:
                pass

        return {
            'name': 'whisper',
            'display_name': f'Whisper ({WHISPER_MODEL})',
            'installed': model_found,
            'required': True,
            'size': '~500 MB'
        }
    except ImportError:
        return {
            'name': 'whisper',
            'display_name': f'Whisper ({WHISPER_MODEL})',
            'installed': False,
            'required': True,
            'size': '~500 MB',
            'error': 'faster-whisper not installed'
        }


def check_mlx_model() -> dict:
    try:
        import platform
        if platform.processor() != 'arm':
            return {
                'name': 'mlx',
                'display_name': 'AI Grammar (MLX)',
                'installed': True,
                'required': False,
                'available': False,
                'message': 'MLX requires Apple Silicon'
            }

        import mlx
        import mlx_lm

        cache_dir = Path.home() / ".cache" / "huggingface" / "hub"
        model_name = MLX_MODEL.replace("/", "--")
        model_dir = cache_dir / f"models--{model_name}"

        model_installed = model_dir.exists() and any(model_dir.glob("**/*.safetensors"))

        return {
            'name': 'mlx',
            'display_name': 'AI Grammar (Qwen2.5)',
            'installed': model_installed,
            'required': False,
            'size': '~400 MB'
        }
    except ImportError:
        return {
            'name': 'mlx',
            'display_name': 'AI Grammar (MLX)',
            'installed': False,
            'required': False,
            'available': False,
            'message': 'MLX not installed (optional for Apple Silicon)'
        }


def check_titanet_available() -> bool:
    try:
        import nemo.collections.asr as nemo_asr
        return True
    except ImportError:
        return False


def check_speaker_model() -> dict:
    try:
        titanet_available = check_titanet_available()

        if titanet_available:
            nemo_cache = Path.home() / ".cache" / "torch" / "NeMo"
            titanet_installed = nemo_cache.exists() and any(nemo_cache.glob("**/*titanet*"))

            if not titanet_installed:
                hf_cache = Path.home() / ".cache" / "huggingface" / "hub"
                titanet_installed = any(hf_cache.glob("*titanet*"))

            return {
                'name': 'speaker',
                'display_name': 'Voice Filter (TitaNet)',
                'installed': titanet_installed,
                'required': False,
                'size': '~100 MB',
                'model_type': 'titanet'
            }

        model_dir = Path(__file__).parent.parent / "models" / "speaker_model"
        model_installed = model_dir.exists() and (any(model_dir.glob("*.ckpt")) or any(model_dir.glob("**/*.ckpt")))

        return {
            'name': 'speaker',
            'display_name': 'Voice Filter (SpeechBrain)',
            'installed': model_installed,
            'required': False,
            'size': '~100 MB',
            'model_type': 'speechbrain'
        }
    except Exception as e:
        return {
            'name': 'speaker',
            'display_name': 'Voice Filter',
            'installed': False,
            'required': False,
            'size': '~100 MB',
            'error': str(e)
        }


def check_all_models() -> dict:
    models = {
        'whisper': check_whisper_model(),
        'mlx': check_mlx_model(),
        'speaker': check_speaker_model()
    }

    all_required_installed = all(
        m['installed'] for m in models.values() if m.get('required', False)
    )

    return {
        'models': models,
        'ready': all_required_installed,
        'downloads_in_progress': get_download_progress()
    }


def download_whisper_model(progress_callback: Optional[Callable] = None) -> bool:
    set_download_progress('whisper', 0, 'downloading', 'Initializing Whisper download...')

    try:
        from faster_whisper import WhisperModel

        set_download_progress('whisper', 10, 'downloading', 'Downloading Whisper model...')

        start_progress_animation('whisper', max_progress=90)

        model = WhisperModel(
            WHISPER_MODEL,
            device="cpu",
            compute_type="int8"
        )

        stop_progress_animation('whisper')
        set_download_progress('whisper', 100, 'complete', 'Whisper model ready')
        time.sleep(0.5)
        clear_download_progress('whisper')

        return True

    except Exception as e:
        stop_progress_animation('whisper')
        set_download_progress('whisper', 0, 'error', f'Download failed: {str(e)}')
        return False


def download_mlx_model(progress_callback: Optional[Callable] = None) -> bool:
    set_download_progress('mlx', 0, 'downloading', 'Initializing MLX model download...')

    try:
        import platform
        if platform.processor() != 'arm':
            set_download_progress('mlx', 0, 'error', 'MLX requires Apple Silicon')
            return False

        from mlx_lm import load

        set_download_progress('mlx', 10, 'downloading', 'Downloading Qwen2.5 model...')

        start_progress_animation('mlx', max_progress=90)

        model, tokenizer = load(MLX_MODEL)

        stop_progress_animation('mlx')
        set_download_progress('mlx', 100, 'complete', 'MLX model ready')
        time.sleep(0.5)
        clear_download_progress('mlx')

        del model
        del tokenizer

        return True

    except ImportError as e:
        stop_progress_animation('mlx')
        set_download_progress('mlx', 0, 'error', 'MLX not installed')
        return False
    except Exception as e:
        stop_progress_animation('mlx')
        set_download_progress('mlx', 0, 'error', f'Download failed: {str(e)}')
        return False


def download_speaker_model(progress_callback: Optional[Callable] = None) -> bool:
    set_download_progress('speaker', 0, 'downloading', 'Initializing speaker model download...')

    if _try_download_titanet():
        return True

    return _try_download_speechbrain()


def _try_download_titanet() -> bool:
    try:
        import nemo.collections.asr as nemo_asr

        set_download_progress('speaker', 10, 'downloading', 'Downloading TitaNet model (optimized for noisy environments)...')

        start_progress_animation('speaker', max_progress=90)

        model = nemo_asr.models.EncDecSpeakerLabelModel.from_pretrained(
            model_name=TITANET_MODEL
        )

        stop_progress_animation('speaker')
        set_download_progress('speaker', 100, 'complete', 'TitaNet speaker model ready')
        time.sleep(0.5)
        clear_download_progress('speaker')

        del model

        return True

    except ImportError:
        stop_progress_animation('speaker')
        print("NeMo not installed, trying SpeechBrain...")
        return False
    except Exception as e:
        stop_progress_animation('speaker')
        print(f"TitaNet download failed: {e}, trying SpeechBrain...")
        return False


def _try_download_speechbrain() -> bool:
    try:
        from speechbrain.inference.speaker import EncoderClassifier

        model_dir = Path(__file__).parent.parent / "models" / "speaker_model"
        model_dir.mkdir(parents=True, exist_ok=True)

        set_download_progress('speaker', 10, 'downloading', 'Downloading SpeechBrain model...')

        start_progress_animation('speaker', max_progress=90)

        model = EncoderClassifier.from_hparams(
            source=SPEECHBRAIN_MODEL,
            savedir=str(model_dir),
            run_opts={"device": "cpu"}
        )

        stop_progress_animation('speaker')
        set_download_progress('speaker', 100, 'complete', 'SpeechBrain speaker model ready')
        time.sleep(0.5)
        clear_download_progress('speaker')

        del model

        return True

    except ImportError as e:
        stop_progress_animation('speaker')
        set_download_progress('speaker', 0, 'error', 'SpeechBrain not installed')
        return False
    except Exception as e:
        stop_progress_animation('speaker')
        set_download_progress('speaker', 0, 'error', f'Download failed: {str(e)}')
        return False


def download_model(model_name: str) -> bool:
    downloaders = {
        'whisper': download_whisper_model,
        'mlx': download_mlx_model,
        'speaker': download_speaker_model
    }

    if model_name not in downloaders:
        return False

    return downloaders[model_name]()


def download_model_async(model_name: str, callback: Optional[Callable] = None):
    def _download():
        success = download_model(model_name)
        if callback:
            callback(model_name, success)

    thread = threading.Thread(target=_download, daemon=True)
    thread.start()
    return thread
