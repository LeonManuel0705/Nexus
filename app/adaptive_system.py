"""
Adaptive Parameter System for Voice Notes
Self-learning system that optimizes parameters per teacher based on user feedback.
"""

import json
import os
from datetime import datetime
from typing import Optional, Dict, List, Tuple
from pathlib import Path
import statistics

# Directories for storing learning data
LEARNING_DIR = Path(__file__).parent.parent / "learning_data"
PARAMS_LOG_FILE = LEARNING_DIR / "parameter_changes.jsonl"
FEEDBACK_CORRELATION_FILE = LEARNING_DIR / "feedback_correlation.json"
TEACHER_PROFILES_FILE = LEARNING_DIR / "teacher_optimal_params.json"

# Ensure directory exists
LEARNING_DIR.mkdir(parents=True, exist_ok=True)

# Default parameters and their tunable ranges
DEFAULT_PARAMS = {
    "voice_threshold": {
        "value": 0.30,
        "min": 0.15,
        "max": 0.60,
        "step": 0.05,
        "description": "Voice similarity threshold for speaker recognition"
    },
    "vad_threshold": {
        "value": 0.35,
        "min": 0.20,
        "max": 0.60,
        "step": 0.05,
        "description": "Voice activity detection sensitivity"
    },
    "min_speech_duration_ms": {
        "value": 200,
        "min": 100,
        "max": 500,
        "step": 50,
        "description": "Minimum speech duration to detect"
    },
    "no_speech_threshold": {
        "value": 0.6,
        "min": 0.3,
        "max": 0.8,
        "step": 0.1,
        "description": "Threshold for detecting silence"
    },
    "beam_size": {
        "value": 5,
        "min": 1,
        "max": 10,
        "step": 1,
        "description": "Transcription beam search size"
    },
    "temperature": {
        "value": 0.0,
        "min": 0.0,
        "max": 0.4,
        "step": 0.1,
        "description": "Transcription temperature (0 = deterministic)"
    }
}


class AdaptiveParameterSystem:
    """
    Self-learning parameter optimization system.
    Tracks feedback per teacher and adjusts parameters for optimal results.
    """

    def __init__(self):
        self._current_params = self._load_defaults()
        self._current_teacher: Optional[str] = None
        self._session_feedback: List[Dict] = []
        self._teacher_data: Dict = self._load_teacher_data()
        self._feedback_history: Dict = self._load_feedback_correlation()

    def _load_defaults(self) -> Dict[str, float]:
        """Load default parameter values."""
        return {k: v["value"] for k, v in DEFAULT_PARAMS.items()}

    def _load_teacher_data(self) -> Dict:
        """Load learned optimal parameters per teacher."""
        if TEACHER_PROFILES_FILE.exists():
            try:
                with open(TEACHER_PROFILES_FILE, 'r') as f:
                    return json.load(f)
            except:
                pass
        return {}

    def _save_teacher_data(self):
        """Save learned teacher parameters."""
        with open(TEACHER_PROFILES_FILE, 'w') as f:
            json.dump(self._teacher_data, f, indent=2, ensure_ascii=False)

    def _load_feedback_correlation(self) -> Dict:
        """Load feedback correlation data."""
        if FEEDBACK_CORRELATION_FILE.exists():
            try:
                with open(FEEDBACK_CORRELATION_FILE, 'r') as f:
                    return json.load(f)
            except:
                pass
        return {"global": [], "by_teacher": {}}

    def _save_feedback_correlation(self):
        """Save feedback correlation data."""
        with open(FEEDBACK_CORRELATION_FILE, 'w') as f:
            json.dump(self._feedback_history, f, indent=2, ensure_ascii=False)

    def _log_change(self, param: str, old_value: float, new_value: float,
                    reason: str, teacher: Optional[str] = None):
        """Log a parameter change with reason."""
        entry = {
            "timestamp": datetime.now().isoformat(),
            "teacher": teacher or self._current_teacher,
            "parameter": param,
            "old_value": old_value,
            "new_value": new_value,
            "reason": reason
        }

        # Append to log file
        with open(PARAMS_LOG_FILE, 'a') as f:
            f.write(json.dumps(entry, ensure_ascii=False) + "\n")

        print(f"[AdaptiveSystem] {param}: {old_value} -> {new_value} ({reason})")

    def set_teacher(self, teacher_name: str, teacher_id: str):
        """
        Set current teacher and load their optimal parameters.
        This is called when a voice profile is selected.
        """
        self._current_teacher = teacher_id
        teacher_key = f"{teacher_id}_{teacher_name}"

        if teacher_key in self._teacher_data:
            teacher_info = self._teacher_data[teacher_key]
            optimal_params = teacher_info.get("optimal_params", {})

            # Apply learned optimal parameters
            for param, value in optimal_params.items():
                if param in self._current_params:
                    old_val = self._current_params[param]
                    self._current_params[param] = value
                    print(f"[AdaptiveSystem] Loaded {param}={value} for teacher '{teacher_name}' (was {old_val})")

            # Log that we're using learned settings
            self._log_change(
                "profile_loaded",
                0, 1,
                f"Loaded optimal settings for '{teacher_name}' based on {teacher_info.get('feedback_count', 0)} feedback entries",
                teacher_id
            )

            return {
                "loaded": True,
                "teacher": teacher_name,
                "params": optimal_params,
                "feedback_count": teacher_info.get("feedback_count", 0),
                "avg_rating": teacher_info.get("avg_rating", 0),
                "message": f"Loaded optimized settings for {teacher_name}"
            }
        else:
            # New teacher - use defaults
            self._current_params = self._load_defaults()
            print(f"[AdaptiveSystem] New teacher '{teacher_name}' - using default parameters")

            return {
                "loaded": False,
                "teacher": teacher_name,
                "params": self._current_params,
                "message": f"New teacher - using default settings. System will learn from feedback."
            }

    def record_feedback(self, rating: int, teacher_id: Optional[str] = None,
                       teacher_name: Optional[str] = None,
                       quality_score: Optional[int] = None,
                       issues: Optional[List[str]] = None):
        """
        Record user feedback and update learning data.
        This is called when user submits feedback after recording.
        """
        teacher = teacher_id or self._current_teacher
        if not teacher:
            teacher = "unknown"

        teacher_key = f"{teacher}_{teacher_name or 'unknown'}"

        # Create feedback entry
        feedback_entry = {
            "timestamp": datetime.now().isoformat(),
            "rating": rating,
            "quality_score": quality_score,
            "issues": issues or [],
            "params_used": dict(self._current_params)
        }

        # Add to session feedback
        self._session_feedback.append(feedback_entry)

        # Add to global history
        self._feedback_history.setdefault("global", []).append(feedback_entry)

        # Add to teacher-specific history
        self._feedback_history.setdefault("by_teacher", {})
        self._feedback_history["by_teacher"].setdefault(teacher_key, []).append(feedback_entry)

        # Limit history size (keep last 100 per teacher)
        if len(self._feedback_history["by_teacher"][teacher_key]) > 100:
            self._feedback_history["by_teacher"][teacher_key] = \
                self._feedback_history["by_teacher"][teacher_key][-100:]

        self._save_feedback_correlation()

        # Analyze and potentially adjust parameters
        adjustment_result = self._analyze_and_adjust(teacher_key, rating, quality_score, issues)

        # Update teacher optimal params based on good feedback
        self._update_teacher_optimal_params(teacher_key, teacher_name, rating)

        return {
            "recorded": True,
            "teacher": teacher_name or teacher,
            "rating": rating,
            "adjustments": adjustment_result,
            "total_feedback_for_teacher": len(self._feedback_history["by_teacher"].get(teacher_key, []))
        }

    def _analyze_and_adjust(self, teacher_key: str, rating: int,
                           quality_score: Optional[int],
                           issues: Optional[List[str]]) -> Dict:
        """
        Analyze feedback and decide if parameters need adjustment.
        Only adjusts on bad feedback (rating <= 2).
        """
        adjustments = []

        if rating >= 4:
            # Good feedback - no adjustment needed, but record what worked
            return {"action": "none", "reason": "Feedback was positive - current settings work well"}

        if rating == 3:
            # Neutral - don't adjust yet, wait for more data
            return {"action": "none", "reason": "Neutral feedback - monitoring"}

        # Bad feedback (1-2 stars) - analyze issues and adjust
        if not issues:
            issues = []

        # Get teacher's recent feedback to understand patterns
        teacher_feedback = self._feedback_history.get("by_teacher", {}).get(teacher_key, [])
        recent_bad = [f for f in teacher_feedback[-10:] if f.get("rating", 5) <= 2]

        if len(recent_bad) < 2:
            # First bad feedback - don't adjust immediately
            return {"action": "monitoring", "reason": "First bad feedback - will adjust if pattern continues"}

        # Multiple bad feedbacks - analyze and adjust
        common_issues = self._find_common_issues(recent_bad)

        # Determine adjustments based on issues
        for issue_type in common_issues:
            adjustment = self._get_adjustment_for_issue(issue_type)
            if adjustment:
                param, direction, reason = adjustment
                self._adjust_parameter(param, direction, reason, teacher_key)
                adjustments.append({
                    "parameter": param,
                    "direction": direction,
                    "reason": reason
                })

        # If no specific issues, try general adjustments
        if not adjustments and len(recent_bad) >= 3:
            # Try lowering voice threshold (more permissive)
            if self._current_params["voice_threshold"] > DEFAULT_PARAMS["voice_threshold"]["min"]:
                self._adjust_parameter("voice_threshold", "decrease",
                                       "Multiple bad feedbacks - trying more permissive voice matching",
                                       teacher_key)
                adjustments.append({
                    "parameter": "voice_threshold",
                    "direction": "decrease",
                    "reason": "Trying more permissive voice matching"
                })

        return {
            "action": "adjusted" if adjustments else "none",
            "adjustments": adjustments,
            "common_issues": common_issues
        }

    def _find_common_issues(self, feedback_list: List[Dict]) -> List[str]:
        """Find commonly occurring issues in feedback."""
        issue_counts = {}
        for fb in feedback_list:
            for issue in fb.get("issues", []):
                issue_type = issue.get("type", "unknown") if isinstance(issue, dict) else str(issue)
                issue_counts[issue_type] = issue_counts.get(issue_type, 0) + 1

        # Return issues that appear in more than half the feedback
        threshold = len(feedback_list) / 2
        return [issue for issue, count in issue_counts.items() if count >= threshold]

    def _get_adjustment_for_issue(self, issue_type: str) -> Optional[Tuple[str, str, str]]:
        """Map issue types to parameter adjustments."""
        issue_adjustments = {
            # Voice filter issues
            "voice_not_detected": ("voice_threshold", "decrease", "Voice not being detected - lowering threshold"),
            "wrong_voice_transcribed": ("voice_threshold", "increase", "Wrong voice being transcribed - raising threshold"),

            # Speech detection issues
            "missing_speech": ("vad_threshold", "decrease", "Speech being missed - lowering VAD threshold"),
            "too_much_noise": ("vad_threshold", "increase", "Too much noise - raising VAD threshold"),
            "short_words_missing": ("min_speech_duration_ms", "decrease", "Short words missing - lowering min duration"),

            # Transcription quality issues
            "repeated_words": ("no_speech_threshold", "increase", "Repeated words - adjusting silence detection"),
            "incomplete_sentences": ("beam_size", "increase", "Incomplete sentences - increasing beam size"),
            "wrong_words": ("temperature", "decrease", "Wrong words - lowering temperature for determinism"),
        }

        return issue_adjustments.get(issue_type)

    def _adjust_parameter(self, param: str, direction: str, reason: str, teacher_key: str):
        """Adjust a parameter within its allowed range."""
        if param not in DEFAULT_PARAMS:
            return

        param_info = DEFAULT_PARAMS[param]
        old_value = self._current_params[param]
        step = param_info["step"]

        if direction == "increase":
            new_value = min(old_value + step, param_info["max"])
        else:
            new_value = max(old_value - step, param_info["min"])

        if new_value != old_value:
            self._current_params[param] = new_value
            self._log_change(param, old_value, new_value, reason, teacher_key)

    def _update_teacher_optimal_params(self, teacher_key: str, teacher_name: Optional[str], rating: int):
        """Update the stored optimal parameters for a teacher based on good feedback."""
        if rating < 4:
            return  # Only learn from good feedback

        # Initialize teacher data if needed
        if teacher_key not in self._teacher_data:
            self._teacher_data[teacher_key] = {
                "name": teacher_name or "Unknown",
                "created_at": datetime.now().isoformat(),
                "optimal_params": dict(self._current_params),
                "feedback_count": 0,
                "total_rating": 0,
                "avg_rating": 0,
                "good_params_history": []
            }

        teacher_info = self._teacher_data[teacher_key]
        teacher_info["feedback_count"] += 1
        teacher_info["total_rating"] += rating
        teacher_info["avg_rating"] = teacher_info["total_rating"] / teacher_info["feedback_count"]
        teacher_info["last_updated"] = datetime.now().isoformat()

        # Record the params that led to good feedback
        teacher_info["good_params_history"].append({
            "timestamp": datetime.now().isoformat(),
            "rating": rating,
            "params": dict(self._current_params)
        })

        # Keep only last 20 good param sets
        if len(teacher_info["good_params_history"]) > 20:
            teacher_info["good_params_history"] = teacher_info["good_params_history"][-20:]

        # Calculate optimal params as weighted average of good feedback params
        self._calculate_optimal_params(teacher_key)
        self._save_teacher_data()

    def _calculate_optimal_params(self, teacher_key: str):
        """Calculate optimal parameters based on feedback history."""
        teacher_info = self._teacher_data[teacher_key]
        history = teacher_info.get("good_params_history", [])

        if not history:
            return

        # Weight by rating (5 stars = weight 2, 4 stars = weight 1)
        optimal = {}
        for param in DEFAULT_PARAMS.keys():
            weighted_sum = 0
            weight_total = 0

            for entry in history:
                weight = 2 if entry["rating"] == 5 else 1
                value = entry["params"].get(param, DEFAULT_PARAMS[param]["value"])
                weighted_sum += value * weight
                weight_total += weight

            if weight_total > 0:
                optimal[param] = round(weighted_sum / weight_total, 3)

        teacher_info["optimal_params"] = optimal

    def get_current_params(self) -> Dict[str, float]:
        """Get current parameter values."""
        return dict(self._current_params)

    def get_param(self, name: str) -> float:
        """Get a specific parameter value."""
        return self._current_params.get(name, DEFAULT_PARAMS.get(name, {}).get("value", 0))

    def get_teacher_stats(self, teacher_id: str, teacher_name: str) -> Dict:
        """Get learning statistics for a teacher."""
        teacher_key = f"{teacher_id}_{teacher_name}"

        if teacher_key not in self._teacher_data:
            return {
                "known": False,
                "message": "No learning data for this teacher yet"
            }

        info = self._teacher_data[teacher_key]
        return {
            "known": True,
            "name": info.get("name"),
            "feedback_count": info.get("feedback_count", 0),
            "avg_rating": round(info.get("avg_rating", 0), 2),
            "optimal_params": info.get("optimal_params", {}),
            "last_updated": info.get("last_updated"),
            "created_at": info.get("created_at")
        }

    def get_change_log(self, limit: int = 50) -> List[Dict]:
        """Get recent parameter change log."""
        if not PARAMS_LOG_FILE.exists():
            return []

        entries = []
        with open(PARAMS_LOG_FILE, 'r') as f:
            for line in f:
                try:
                    entries.append(json.loads(line))
                except:
                    continue

        return entries[-limit:]

    def reset_teacher(self, teacher_id: str, teacher_name: str):
        """Reset learned data for a teacher (start fresh)."""
        teacher_key = f"{teacher_id}_{teacher_name}"

        if teacher_key in self._teacher_data:
            del self._teacher_data[teacher_key]
            self._save_teacher_data()

        if teacher_key in self._feedback_history.get("by_teacher", {}):
            del self._feedback_history["by_teacher"][teacher_key]
            self._save_feedback_correlation()

        self._current_params = self._load_defaults()

        self._log_change("reset", 0, 1, f"Reset all learning data for teacher '{teacher_name}'", teacher_key)

        return {"reset": True, "teacher": teacher_name}


# Singleton instance
_adaptive_system: Optional[AdaptiveParameterSystem] = None


def get_adaptive_system() -> AdaptiveParameterSystem:
    """Get the singleton adaptive system instance."""
    global _adaptive_system
    if _adaptive_system is None:
        _adaptive_system = AdaptiveParameterSystem()
    return _adaptive_system


def set_teacher(teacher_name: str, teacher_id: str) -> Dict:
    """Set current teacher and load optimal parameters."""
    return get_adaptive_system().set_teacher(teacher_name, teacher_id)


def record_feedback(rating: int, **kwargs) -> Dict:
    """Record user feedback."""
    return get_adaptive_system().record_feedback(rating, **kwargs)


def get_param(name: str) -> float:
    """Get a parameter value."""
    return get_adaptive_system().get_param(name)


def get_current_params() -> Dict[str, float]:
    """Get all current parameters."""
    return get_adaptive_system().get_current_params()


def get_teacher_stats(teacher_id: str, teacher_name: str) -> Dict:
    """Get learning stats for a teacher."""
    return get_adaptive_system().get_teacher_stats(teacher_id, teacher_name)


def get_change_log(limit: int = 50) -> List[Dict]:
    """Get parameter change log."""
    return get_adaptive_system().get_change_log(limit)
