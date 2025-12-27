import threading
import os
from pathlib import Path
from typing import Optional, Dict, Callable
import time

WHISPER_MODEL = "small"
MLX_MODEL = "mlx-community/Qwen2.5-0.5B-Instruct-4bit"
SPEAKER_MODEL = "speechbrain/spkrec-ecapa-voxceleb"

_download_progress: Dict[str, dict] = {}
_download_lock = threading.Lock()


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


def check_speaker_model() -> dict:
    try:
        model_dir = Path(__file__).parent.parent / "models" / "speaker_model"
        model_installed = model_dir.exists() and any(model_dir.glob("*.ckpt")) or any(model_dir.glob("**/*.ckpt"))

        return {
            'name': 'speaker',
            'display_name': 'Voice Filter (SpeechBrain)',
            'installed': model_installed,
            'required': False,
            'size': '~100 MB'
        }
    except Exception as e:
        return {
            'name': 'speaker',
            'display_name': 'Voice Filter (SpeechBrain)',
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

        model = WhisperModel(
            WHISPER_MODEL,
            device="cpu",
            compute_type="int8"
        )

        set_download_progress('whisper', 100, 'complete', 'Whisper model ready')
        time.sleep(0.5)
        clear_download_progress('whisper')

        return True

    except Exception as e:
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

        model, tokenizer = load(MLX_MODEL)

        set_download_progress('mlx', 100, 'complete', 'MLX model ready')
        time.sleep(0.5)
        clear_download_progress('mlx')

        del model
        del tokenizer

        return True

    except ImportError as e:
        set_download_progress('mlx', 0, 'error', 'MLX not installed')
        return False
    except Exception as e:
        set_download_progress('mlx', 0, 'error', f'Download failed: {str(e)}')
        return False


def download_speaker_model(progress_callback: Optional[Callable] = None) -> bool:
    set_download_progress('speaker', 0, 'downloading', 'Initializing speaker model download...')

    try:
        from speechbrain.inference.speaker import EncoderClassifier

        model_dir = Path(__file__).parent.parent / "models" / "speaker_model"
        model_dir.mkdir(parents=True, exist_ok=True)

        set_download_progress('speaker', 10, 'downloading', 'Downloading SpeechBrain model...')

        model = EncoderClassifier.from_hparams(
            source=SPEAKER_MODEL,
            savedir=str(model_dir),
            run_opts={"device": "cpu"}
        )

        set_download_progress('speaker', 100, 'complete', 'Speaker model ready')
        time.sleep(0.5)
        clear_download_progress('speaker')

        del model

        return True

    except ImportError as e:
        set_download_progress('speaker', 0, 'error', 'SpeechBrain not installed')
        return False
    except Exception as e:
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
