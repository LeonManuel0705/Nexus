from flask import Flask, request, jsonify, render_template, redirect, url_for
from flask_cors import CORS
from flask_socketio import SocketIO
import os
import uuid
from datetime import datetime
from pathlib import Path
import json
import time

from . import database as db

app = Flask(__name__, static_folder='static')
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')

@app.route('/')
def landing():
                                                              
    return redirect(url_for('hub_home'))

@app.route('/welcome')
def welcome_page():
                                                                    
    return render_template('landing.html')

@app.route('/apps')
def apps_selection():
                             
    return render_template('apps.html')

@app.route('/hub')
def hub_home():
    return render_template('hub/home.html', active_tab='dashboard')

@app.route('/hub/tasks')
def hub_tasks():
    return render_template('hub/tasks.html', active_tab='tasks')

@app.route('/hub/calendar')
def hub_calendar():
    return render_template('hub/calendar.html', active_tab='calendar')

@app.route('/hub/school')
def hub_school():
    return render_template('hub/school.html', active_tab='school')

@app.route('/hub/training')
def hub_training():
    return render_template('hub/training.html', active_tab='training')

@app.route('/hub/projects')
def hub_projects():
    return render_template('hub/projects.html', active_tab='projects')

@app.route('/hub/knowledge')
def hub_knowledge():
    return render_template('hub/knowledge.html', active_tab='knowledge')

@app.route('/hub/review')
def hub_review():
    return render_template('hub/review.html', active_tab='review')

@app.route('/hub/mousepad')
def hub_mousepad():
    return render_template('hub/mousepad.html', active_tab='mousepad')

@app.route('/hub/assistant')
def hub_assistant():
    return render_template('hub/assistant.html', active_tab='assistant')

@app.route('/hub/settings')
def hub_settings():
    return render_template('hub/settings.html', active_tab='settings')

@app.route('/hub/terms')
def hub_terms():
    return render_template('hub/terms.html', active_tab='settings')

@app.route('/hub/privacy')
def hub_privacy():
    return render_template('hub/privacy.html', active_tab='settings')

@app.route('/hub/email')
def hub_email():
    return render_template('hub/email.html', active_tab='email')

# Fast ping endpoints for connection checking
@app.route('/api/ping', methods=['HEAD', 'GET'])
def ping():
    """Fast ping endpoint for connection checking - minimal overhead"""
    return '', 204

@app.route('/api/iserv/ping', methods=['HEAD', 'GET'])
def iserv_ping():
    """Fast IServ availability check"""
    from .iserv_service import get_iserv_service
    service = get_iserv_service()
    status = service.get_status()
    if status.get('connected') or status.get('has_credentials'):
        return '', 204
    return '', 503

@app.route('/api/hub/tasks', methods=['GET'])
def get_hub_tasks_api():
    """Get hub tasks, optionally filtered by user_id"""
    filter_type = request.args.get('filter', 'all')
    user_id = request.args.get('user_id')
    tasks = db.get_hub_tasks(filter_type, user_id=user_id)
    return jsonify({'success': True, 'tasks': tasks})

@app.route('/api/hub/tasks', methods=['POST'])
def create_hub_task_api():
    """Create a new hub task with optional user_id"""
    data = request.get_json()
    if not data or not data.get('title'):
        return jsonify({'success': False, 'error': 'Title is required'}), 400

    task_id = db.create_hub_task(
        title=data.get('title'),
        description=data.get('description'),
        due_date=data.get('due_date'),
        due_time=data.get('due_time'),
        priority=data.get('priority', 'medium'),
        category=data.get('category'),
        user_id=data.get('user_id'),
        repeat_type=data.get('repeat_type', 'none'),
        repeat_days=data.get('repeat_days'),
        repeat_end_date=data.get('repeat_end_date')
    )
    task = db.get_hub_task(task_id)
    return jsonify({'success': True, 'task': task})

@app.route('/api/hub/tasks/<int:task_id>', methods=['GET'])
def get_hub_task_api(task_id):
                                  
    task = db.get_hub_task(task_id)
    if not task:
        return jsonify({'success': False, 'error': 'Task not found'}), 404
    return jsonify({'success': True, 'task': task})

@app.route('/api/hub/tasks/<int:task_id>', methods=['PUT'])
def update_hub_task_api(task_id):
                            
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    success = db.update_hub_task(
        task_id,
        title=data.get('title'),
        description=data.get('description'),
        due_date=data.get('due_date'),
        due_time=data.get('due_time'),
        priority=data.get('priority'),
        category=data.get('category'),
        repeat_type=data.get('repeat_type'),
        repeat_days=data.get('repeat_days'),
        repeat_end_date=data.get('repeat_end_date')
    )

    if success:
        task = db.get_hub_task(task_id)
        return jsonify({'success': True, 'task': task})
    return jsonify({'success': False, 'error': 'Task not found or no changes made'}), 404

@app.route('/api/hub/tasks/<int:task_id>', methods=['DELETE'])
def delete_hub_task_api(task_id):
                            
    success = db.delete_hub_task(task_id)
    if success:
        return jsonify({'success': True})
    return jsonify({'success': False, 'error': 'Task not found'}), 404

@app.route('/api/hub/tasks/<int:task_id>/toggle', methods=['POST'])
def toggle_hub_task_api(task_id):
    """Toggle task completion and create next occurrence if repeating"""
    result = db.toggle_hub_task(task_id)
    if result.get('success'):
        task = db.get_hub_task(task_id)
        response = {'success': True, 'task': task}
        # If a next task was created (repeating task), include its info
        if result.get('next_task_id'):
            next_task = db.get_hub_task(result['next_task_id'])
            response['next_task'] = next_task
        return jsonify(response)
    return jsonify({'success': False, 'error': 'Task not found'}), 404

@app.route('/api/hub/reviews', methods=['GET'])
def get_reviews():
                          
    review_type = request.args.get('type')
    reviews = db.get_hub_reviews(review_type=review_type)
    return jsonify({'reviews': reviews})

@app.route('/api/hub/reviews', methods=['POST'])
def create_review():
                              
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    review_type = data.get('type', 'daily')
    date = data.get('date')
    energy = data.get('energy')

    review_data = {k: v for k, v in data.items() if k not in ['type', 'date', 'energy', 'id']}
    data_json = json.dumps(review_data) if review_data else None

    review_id = db.create_hub_review(review_type, date, data_json, energy)
    review = db.get_hub_review(review_id)

    return jsonify({'success': True, 'review': review})

@app.route('/api/hub/reviews/<int:review_id>', methods=['GET'])
def get_review(review_id):
                                
    review = db.get_hub_review(review_id)
    if not review:
        return jsonify({'success': False, 'error': 'Review not found'}), 404
    return jsonify({'success': True, 'review': review})

@app.route('/api/hub/reviews/<int:review_id>', methods=['PUT'])
def update_review(review_id):
                                    
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    review = db.get_hub_review(review_id)
    if not review:
        return jsonify({'success': False, 'error': 'Review not found'}), 404

    energy = data.get('energy')
    review_data = {k: v for k, v in data.items() if k not in ['type', 'date', 'energy', 'id']}
    data_json = json.dumps(review_data) if review_data else None

    db.update_hub_review(review_id, data=data_json, energy=energy)
    updated_review = db.get_hub_review(review_id)

    return jsonify({'success': True, 'review': updated_review})

@app.route('/api/hub/reviews/<int:review_id>', methods=['DELETE'])
def delete_review(review_id):
                          
    db.delete_hub_review(review_id)
    return jsonify({'success': True})

@app.route('/api/hub/knowledge', methods=['GET'])
def get_knowledge():
    """Get knowledge entries, optionally filtered by user_id"""
    topic = request.args.get('topic')
    search = request.args.get('search')
    user_id = request.args.get('user_id')
    entries = db.get_hub_knowledge(topic=topic, search=search, user_id=user_id)
    return jsonify({'entries': entries})

@app.route('/api/hub/knowledge', methods=['POST'])
def create_knowledge():
    """Create a knowledge entry with optional user_id"""
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    entry_id = db.create_hub_knowledge(
        title=data.get('title'),
        topic=data.get('topic', 'general'),
        content=data.get('content', ''),
        tags=data.get('tags', ''),
        user_id=data.get('user_id')
    )
    entry = db.get_hub_knowledge_entry(entry_id)

    return jsonify({'success': True, 'entry': entry})

@app.route('/api/hub/knowledge/<int:entry_id>', methods=['GET'])
def get_knowledge_entry(entry_id):
                                         
    entry = db.get_hub_knowledge_entry(entry_id)
    if not entry:
        return jsonify({'success': False, 'error': 'Entry not found'}), 404
    return jsonify({'success': True, 'entry': entry})

@app.route('/api/hub/knowledge/<int:entry_id>', methods=['PUT'])
def update_knowledge(entry_id):
                                             
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    entry = db.get_hub_knowledge_entry(entry_id)
    if not entry:
        return jsonify({'success': False, 'error': 'Entry not found'}), 404

    db.update_hub_knowledge(
        entry_id,
        title=data.get('title'),
        topic=data.get('topic'),
        content=data.get('content'),
        tags=data.get('tags')
    )
    updated_entry = db.get_hub_knowledge_entry(entry_id)

    return jsonify({'success': True, 'entry': updated_entry})

@app.route('/api/hub/knowledge/<int:entry_id>', methods=['DELETE'])
def delete_knowledge(entry_id):
                                   
    db.delete_hub_knowledge(entry_id)
    return jsonify({'success': True})

@app.route('/api/hub/projects', methods=['GET'])
def get_projects():
    """Get projects, optionally filtered by user_id"""
    status = request.args.get('status')
    user_id = request.args.get('user_id')
    projects = db.get_hub_projects(status=status, user_id=user_id)
    return jsonify({'projects': projects})

@app.route('/api/hub/projects', methods=['POST'])
def create_project():
    """Create a project with optional user_id"""
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    project_id = db.create_hub_project(
        name=data.get('name'),
        goal=data.get('goal', ''),
        status=data.get('status', 'active'),
        deadline=data.get('deadline'),
        next_step=data.get('next_step', ''),
        notes=data.get('notes', ''),
        progress=data.get('progress', 0),
        user_id=data.get('user_id')
    )
    project = db.get_hub_project(project_id)

    return jsonify({'success': True, 'project': project})

@app.route('/api/hub/projects/<int:project_id>', methods=['GET'])
def get_project(project_id):
                                 
    project = db.get_hub_project(project_id)
    if not project:
        return jsonify({'success': False, 'error': 'Project not found'}), 404
    return jsonify({'success': True, 'project': project})

@app.route('/api/hub/projects/<int:project_id>', methods=['PUT'])
def update_project(project_id):
                                     
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    project = db.get_hub_project(project_id)
    if not project:
        return jsonify({'success': False, 'error': 'Project not found'}), 404

    db.update_hub_project(
        project_id,
        name=data.get('name'),
        goal=data.get('goal'),
        status=data.get('status'),
        deadline=data.get('deadline'),
        next_step=data.get('next_step'),
        notes=data.get('notes'),
        progress=data.get('progress')
    )
    updated_project = db.get_hub_project(project_id)

    return jsonify({'success': True, 'project': updated_project})

@app.route('/api/hub/projects/<int:project_id>', methods=['DELETE'])
def delete_project(project_id):
                           
    db.delete_hub_project(project_id)
    return jsonify({'success': True})

SCHOOL_SUBJECTS_FILE = Path(__file__).parent.parent / 'data' / 'school_subjects.json'
SCHOOL_HOMEWORK_FILE = Path(__file__).parent.parent / 'data' / 'school_homework.json'
SCHOOL_TESTS_FILE = Path(__file__).parent.parent / 'data' / 'school_tests.json'
SCHOOL_EXAMS_FILE = Path(__file__).parent.parent / 'data' / 'school_exams.json'
SCHOOL_GRADES_FILE = Path(__file__).parent.parent / 'data' / 'school_grades.json'
SCHOOL_CALENDAR_FILE = Path(__file__).parent.parent / 'data' / 'school_calendar.json'

def load_school_subjects():
                                         
    if SCHOOL_SUBJECTS_FILE.exists():
        try:
            with open(SCHOOL_SUBJECTS_FILE, 'r') as f:
                return json.load(f)
        except Exception:
            return []
    return []

def save_school_subjects(subjects):
                                       
    SCHOOL_SUBJECTS_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(SCHOOL_SUBJECTS_FILE, 'w') as f:
        json.dump(subjects, f, indent=2, ensure_ascii=False)

def load_school_homework():
                                         
    if SCHOOL_HOMEWORK_FILE.exists():
        try:
            with open(SCHOOL_HOMEWORK_FILE, 'r') as f:
                return json.load(f)
        except Exception:
            return []
    return []

def save_school_homework(homework):
                                       
    SCHOOL_HOMEWORK_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(SCHOOL_HOMEWORK_FILE, 'w') as f:
        json.dump(homework, f, indent=2, ensure_ascii=False)

def load_school_tests():
                                      
    if SCHOOL_TESTS_FILE.exists():
        try:
            with open(SCHOOL_TESTS_FILE, 'r') as f:
                return json.load(f)
        except Exception:
            return []
    return []

def save_school_tests(tests):
                                    
    SCHOOL_TESTS_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(SCHOOL_TESTS_FILE, 'w') as f:
        json.dump(tests, f, indent=2, ensure_ascii=False)

def load_school_exams():
                                      
    if SCHOOL_EXAMS_FILE.exists():
        try:
            with open(SCHOOL_EXAMS_FILE, 'r') as f:
                return json.load(f)
        except Exception:
            return []
    return []

def save_school_exams(exams):
                                    
    SCHOOL_EXAMS_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(SCHOOL_EXAMS_FILE, 'w') as f:
        json.dump(exams, f, indent=2, ensure_ascii=False)

def load_school_grades():
                                       
    if SCHOOL_GRADES_FILE.exists():
        try:
            with open(SCHOOL_GRADES_FILE, 'r') as f:
                return json.load(f)
        except Exception:
            return []
    return []

def save_school_grades(grades):
                                     
    SCHOOL_GRADES_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(SCHOOL_GRADES_FILE, 'w') as f:
        json.dump(grades, f, indent=2, ensure_ascii=False)

def load_school_calendar():
                                                
    if SCHOOL_CALENDAR_FILE.exists():
        try:
            with open(SCHOOL_CALENDAR_FILE, 'r') as f:
                return json.load(f)
        except Exception:
            return []
    return []

def save_school_calendar(events):
                                              
    SCHOOL_CALENDAR_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(SCHOOL_CALENDAR_FILE, 'w') as f:
        json.dump(events, f, indent=2, ensure_ascii=False)

@app.route('/api/hub/school/subjects', methods=['GET'])
def get_school_subjects():
                                  
    subjects = load_school_subjects()
    return jsonify({'subjects': subjects})

@app.route('/api/hub/school/subjects', methods=['POST'])
def create_school_subject():
                                      
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    subjects = load_school_subjects()

    subject_id = str(uuid.uuid4())[:8]

    subject = {
        'id': subject_id,
        'name': data.get('name'),
        'teacher': data.get('teacher', ''),
        'room': data.get('room', ''),
        'color': data.get('color', '#667eea'),
        'grade': data.get('grade'),
        'course_type': data.get('course_type', 'GK'),
        'created_at': datetime.now().isoformat()
    }

    subjects.append(subject)
    save_school_subjects(subjects)

    return jsonify({'success': True, 'subject': subject})

@app.route('/api/hub/school/subjects/<subject_id>', methods=['PUT'])
def update_school_subject(subject_id):
                                            
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    subjects = load_school_subjects()
    subject_index = next((i for i, s in enumerate(subjects) if s['id'] == subject_id), None)

    if subject_index is None:
        return jsonify({'success': False, 'error': 'Subject not found'}), 404

    subjects[subject_index].update({
        'name': data.get('name', subjects[subject_index].get('name')),
        'teacher': data.get('teacher', subjects[subject_index].get('teacher')),
        'room': data.get('room', subjects[subject_index].get('room')),
        'color': data.get('color', subjects[subject_index].get('color')),
        'grade': data.get('grade', subjects[subject_index].get('grade')),
        'course_type': data.get('course_type', subjects[subject_index].get('course_type', 'GK')),
        'updated_at': datetime.now().isoformat()
    })

    save_school_subjects(subjects)
    return jsonify({'success': True, 'subject': subjects[subject_index]})

@app.route('/api/hub/school/subjects/<subject_id>', methods=['DELETE'])
def delete_school_subject(subject_id):
                                  
    subjects = load_school_subjects()
    subjects = [s for s in subjects if s['id'] != subject_id]
    save_school_subjects(subjects)
    return jsonify({'success': True})

@app.route('/api/hub/school/homework', methods=['GET'])
def get_school_homework():
                                  
    homework = load_school_homework()
    return jsonify({'homework': homework})

@app.route('/api/hub/school/homework', methods=['POST'])
def create_school_homework():
                                      
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    homework_list = load_school_homework()

    homework_id = str(uuid.uuid4())[:8]

    homework = {
        'id': homework_id,
        'subject_id': data.get('subject_id'),
        'title': data.get('title'),
        'due_date': data.get('due_date'),
        'notes': data.get('notes', ''),
        'completed': False,
        'created_at': datetime.now().isoformat()
    }

    homework_list.append(homework)
    save_school_homework(homework_list)

    return jsonify({'success': True, 'homework': homework})

@app.route('/api/hub/school/homework/<homework_id>', methods=['PUT'])
def update_school_homework(homework_id):
                                            
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    homework_list = load_school_homework()
    homework_index = next((i for i, h in enumerate(homework_list) if h['id'] == homework_id), None)

    if homework_index is None:
        return jsonify({'success': False, 'error': 'Homework not found'}), 404

    homework_list[homework_index].update({
        'subject_id': data.get('subject_id', homework_list[homework_index].get('subject_id')),
        'title': data.get('title', homework_list[homework_index].get('title')),
        'due_date': data.get('due_date', homework_list[homework_index].get('due_date')),
        'notes': data.get('notes', homework_list[homework_index].get('notes')),
        'completed': data.get('completed', homework_list[homework_index].get('completed')),
        'updated_at': datetime.now().isoformat()
    })

    save_school_homework(homework_list)
    return jsonify({'success': True, 'homework': homework_list[homework_index]})

@app.route('/api/hub/school/homework/<homework_id>', methods=['DELETE'])
def delete_school_homework(homework_id):
                                  
    homework_list = load_school_homework()
    homework_list = [h for h in homework_list if h['id'] != homework_id]
    save_school_homework(homework_list)
    return jsonify({'success': True})

@app.route('/api/hub/school/homework/<homework_id>/toggle', methods=['POST'])
def toggle_school_homework(homework_id):
                                            
    homework_list = load_school_homework()
    homework_index = next((i for i, h in enumerate(homework_list) if h['id'] == homework_id), None)

    if homework_index is None:
        return jsonify({'success': False, 'error': 'Homework not found'}), 404

    homework_list[homework_index]['completed'] = not homework_list[homework_index].get('completed', False)
    homework_list[homework_index]['updated_at'] = datetime.now().isoformat()

    save_school_homework(homework_list)
    return jsonify({'success': True, 'homework': homework_list[homework_index]})

@app.route('/api/hub/school/tests', methods=['GET'])
def get_school_tests():
                               
    tests = load_school_tests()
    return jsonify({'tests': tests})

@app.route('/api/hub/school/tests', methods=['POST'])
def create_school_test():
                                  
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    tests = load_school_tests()

    test_id = str(uuid.uuid4())[:8]

    test = {
        'id': test_id,
        'subject_id': data.get('subject_id'),
        'title': data.get('title'),
        'date': data.get('date'),
        'time': data.get('time', ''),
        'topics': data.get('topics', ''),
        'created_at': datetime.now().isoformat()
    }

    tests.append(test)
    save_school_tests(tests)

    return jsonify({'success': True, 'test': test})

@app.route('/api/hub/school/tests/<test_id>', methods=['PUT'])
def update_school_test(test_id):
                                        
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    tests = load_school_tests()
    test_index = next((i for i, t in enumerate(tests) if t['id'] == test_id), None)

    if test_index is None:
        return jsonify({'success': False, 'error': 'Test not found'}), 404

    tests[test_index].update({
        'subject_id': data.get('subject_id', tests[test_index].get('subject_id')),
        'title': data.get('title', tests[test_index].get('title')),
        'date': data.get('date', tests[test_index].get('date')),
        'time': data.get('time', tests[test_index].get('time')),
        'topics': data.get('topics', tests[test_index].get('topics')),
        'updated_at': datetime.now().isoformat()
    })

    save_school_tests(tests)
    return jsonify({'success': True, 'test': tests[test_index]})

@app.route('/api/hub/school/tests/<test_id>', methods=['DELETE'])
def delete_school_test(test_id):
                              
    tests = load_school_tests()
    tests = [t for t in tests if t['id'] != test_id]
    save_school_tests(tests)
    return jsonify({'success': True})

@app.route('/api/hub/school/exams', methods=['GET'])
def get_school_exams():
                               
    exams = load_school_exams()
    return jsonify({'exams': exams})

@app.route('/api/hub/school/exams', methods=['POST'])
def create_school_exam():
                                  
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    exams = load_school_exams()

    exam_id = str(uuid.uuid4())[:8]

    exam = {
        'id': exam_id,
        'subject_id': data.get('subject_id'),
        'title': data.get('title'),
        'date': data.get('date'),
        'time': data.get('time', ''),
        'topics': data.get('topics', ''),
        'created_at': datetime.now().isoformat()
    }

    exams.append(exam)
    save_school_exams(exams)

    return jsonify({'success': True, 'exam': exam})

@app.route('/api/hub/school/exams/<exam_id>', methods=['PUT'])
def update_school_exam(exam_id):
                                        
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    exams = load_school_exams()
    exam_index = next((i for i, e in enumerate(exams) if e['id'] == exam_id), None)

    if exam_index is None:
        return jsonify({'success': False, 'error': 'Exam not found'}), 404

    exams[exam_index].update({
        'subject_id': data.get('subject_id', exams[exam_index].get('subject_id')),
        'title': data.get('title', exams[exam_index].get('title')),
        'date': data.get('date', exams[exam_index].get('date')),
        'time': data.get('time', exams[exam_index].get('time')),
        'topics': data.get('topics', exams[exam_index].get('topics')),
        'updated_at': datetime.now().isoformat()
    })

    save_school_exams(exams)
    return jsonify({'success': True, 'exam': exams[exam_index]})

@app.route('/api/hub/school/exams/<exam_id>', methods=['DELETE'])
def delete_school_exam(exam_id):
                               
    exams = load_school_exams()
    exams = [e for e in exams if e['id'] != exam_id]
    save_school_exams(exams)
    return jsonify({'success': True})

@app.route('/api/hub/school/grades', methods=['GET'])
def get_school_grades():
                                
    grades = load_school_grades()
    return jsonify({'grades': grades})

@app.route('/api/hub/school/grades', methods=['POST'])
def create_school_grade():
                                    
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400

        grades = load_school_grades()

        grade = {
            'id': str(uuid.uuid4()),
            'subject_id': data.get('subject_id'),
            'points': data.get('points'),
            'type': data.get('type', 'test'),
            'date': data.get('date'),
            'description': data.get('description'),
            'semester': data.get('semester', 'Q1'),
            'created_at': datetime.now().isoformat()
        }

        grades.append(grade)
        save_school_grades(grades)
        return jsonify({'grade': grade})
    except Exception as e:
        print(f"Error creating grade: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/hub/school/grades/<grade_id>', methods=['PUT'])
def update_school_grade(grade_id):
                                
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400

        grades = load_school_grades()

        updated_grade = None
        for grade in grades:
            if grade['id'] == grade_id:
                grade['subject_id'] = data.get('subject_id', grade.get('subject_id'))
                grade['points'] = data.get('points', grade.get('points'))
                grade['type'] = data.get('type', grade.get('type'))
                grade['date'] = data.get('date', grade.get('date'))
                grade['description'] = data.get('description', grade.get('description'))
                grade['semester'] = data.get('semester', grade.get('semester', 'Q1'))
                grade['updated_at'] = datetime.now().isoformat()
                updated_grade = grade
                break

        if updated_grade is None:
            return jsonify({'error': 'Grade not found'}), 404

        save_school_grades(grades)
        return jsonify({'grade': updated_grade})
    except Exception as e:
        print(f"Error updating grade: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/hub/school/grades/<grade_id>', methods=['DELETE'])
def delete_school_grade(grade_id):
                                
    grades = load_school_grades()
    grades = [g for g in grades if g['id'] != grade_id]
    save_school_grades(grades)
    return jsonify({'success': True})

@app.route('/api/hub/school/calendar', methods=['GET'])
def get_school_calendar():
                                         
    events = load_school_calendar()
    return jsonify({'events': events})

@app.route('/api/hub/school/calendar', methods=['POST'])
def create_school_calendar_event():
                                             
    data = request.json
    events = load_school_calendar()

    event = {
        'id': str(uuid.uuid4()),
        'title': data.get('title'),
        'date': data.get('date'),
        'time': data.get('time'),
        'end_date': data.get('end_date'),
        'end_time': data.get('end_time'),
        'category': data.get('category', 'school'),
        'description': data.get('description'),
        'created_at': datetime.now().isoformat()
    }

    events.append(event)
    save_school_calendar(events)
    return jsonify({'event': event})

@app.route('/api/hub/school/calendar/<event_id>', methods=['PUT'])
def update_school_calendar_event(event_id):
                                         
    data = request.json
    events = load_school_calendar()

    for event in events:
        if event['id'] == event_id:
            event['title'] = data.get('title', event.get('title'))
            event['date'] = data.get('date', event.get('date'))
            event['time'] = data.get('time', event.get('time'))
            event['end_date'] = data.get('end_date', event.get('end_date'))
            event['end_time'] = data.get('end_time', event.get('end_time'))
            event['category'] = data.get('category', event.get('category'))
            event['description'] = data.get('description', event.get('description'))
            event['updated_at'] = datetime.now().isoformat()
            break

    save_school_calendar(events)
    return jsonify({'event': event})

@app.route('/api/hub/school/calendar/<event_id>', methods=['DELETE'])
def delete_school_calendar_event(event_id):
                                         
    events = load_school_calendar()
    events = [e for e in events if e['id'] != event_id]
    save_school_calendar(events)
    return jsonify({'success': True})

@app.route('/api/hub/school/timetable/settings', methods=['GET'])
def get_timetable_settings():
    """Get timetable settings, optionally filtered by user_id"""
    user_id = request.args.get('user_id')
    settings = db.get_timetable_settings(user_id=user_id)
    if settings:
        return jsonify({'success': True, 'settings': settings})
    return jsonify({'success': True, 'settings': None, 'setup_required': True})

@app.route('/api/hub/school/timetable/settings', methods=['POST'])
def save_timetable_settings():
    """Save timetable settings with optional user_id"""
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    settings_id = db.save_timetable_settings(
        has_ab_weeks=data.get('has_ab_weeks', True),
        block_count=data.get('block_count', 4),
        reference_date=data.get('reference_date'),
        setup_completed=data.get('setup_completed', False),
        user_id=data.get('user_id')
    )
    return jsonify({'success': True, 'settings_id': settings_id})

@app.route('/api/hub/school/timetable/entries', methods=['GET'])
def get_timetable_entries():
    """Get timetable entries, optionally filtered by user_id"""
    day = request.args.get('day', type=int)
    week = request.args.get('week')
    user_id = request.args.get('user_id')
    entries = db.get_timetable_entries(day=day, week=week, user_id=user_id)
    return jsonify({'success': True, 'entries': entries})

@app.route('/api/hub/school/timetable/entries', methods=['POST'])
def create_timetable_entry():
    """Create timetable entry with optional user_id"""
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    if not data.get('day') or not data.get('block') or not data.get('subject'):
        return jsonify({'success': False, 'error': 'day, block, and subject are required'}), 400

    entry_id = db.create_timetable_entry(
        day=data['day'],
        block=data['block'],
        subject=data['subject'],
        week=data.get('week', 'both'),
        subject_type=data.get('subject_type', 'GK'),
        room=data.get('room'),
        teacher=data.get('teacher'),
        color=data.get('color'),
        user_id=data.get('user_id')
    )
    entry = db.get_timetable_entry(entry_id)
    return jsonify({'success': True, 'entry': entry})

@app.route('/api/hub/school/timetable/entries/<int:entry_id>', methods=['GET'])
def get_timetable_entry(entry_id):
                                       
    entry = db.get_timetable_entry(entry_id)
    if not entry:
        return jsonify({'success': False, 'error': 'Entry not found'}), 404
    return jsonify({'success': True, 'entry': entry})

@app.route('/api/hub/school/timetable/entries/<int:entry_id>', methods=['PUT'])
def update_timetable_entry(entry_id):
                                   
    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    success = db.update_timetable_entry(
        entry_id,
        day=data.get('day'),
        block=data.get('block'),
        subject=data.get('subject'),
        week=data.get('week'),
        subject_type=data.get('subject_type'),
        room=data.get('room'),
        teacher=data.get('teacher'),
        color=data.get('color')
    )

    if not success:
        return jsonify({'success': False, 'error': 'Entry not found'}), 404

    entry = db.get_timetable_entry(entry_id)
    return jsonify({'success': True, 'entry': entry})

@app.route('/api/hub/school/timetable/entries/<int:entry_id>', methods=['DELETE'])
def delete_timetable_entry(entry_id):
                                   
    success = db.delete_timetable_entry(entry_id)
    if not success:
        return jsonify({'success': False, 'error': 'Entry not found'}), 404
    return jsonify({'success': True})

@app.route('/api/hub/school/timetable/clear', methods=['POST'])
def clear_timetable():
    """Clear timetable entries, optionally filtered by user_id"""
    data = request.get_json() or {}
    user_id = data.get('user_id')
    count = db.clear_timetable(user_id=user_id)
    return jsonify({'success': True, 'deleted': count})

@app.route('/api/hub/school/timetable/import', methods=['POST'])
def import_timetable_template():
    """Import timetable template with optional user_id"""
    data = request.get_json()
    if not data or 'entries' not in data:
        return jsonify({'success': False, 'error': 'No entries provided'}), 400

    user_id = data.get('user_id')
    if data.get('clear_existing', False):
        db.clear_timetable(user_id=user_id)

    count = db.import_timetable_template(data['entries'], user_id=user_id)
    return jsonify({'success': True, 'imported': count})

DEFAULT_TIMETABLE_TEMPLATE = [
                   
    {'day': 1, 'block': 1, 'week': 'A', 'subject': 'Deutsch', 'subject_type': 'LK', 'room': '226', 'color': '#4285f4'},
    {'day': 1, 'block': 2, 'week': 'A', 'subject': 'Geschichte', 'subject_type': 'GK', 'room': '124', 'color': '#ea4335'},
    {'day': 1, 'block': 3, 'week': 'A', 'subject': 'Englisch', 'subject_type': 'GK', 'room': '330', 'color': '#34a853'},
    {'day': 1, 'block': 4, 'week': 'A', 'subject': 'Sport', 'subject_type': 'GK', 'room': 'TH', 'color': '#ff9800'},
                    
    {'day': 2, 'block': 1, 'week': 'A', 'subject': 'Physik', 'subject_type': 'GK', 'room': '310', 'color': '#9c27b0'},
    {'day': 2, 'block': 2, 'week': 'A', 'subject': 'Mathe', 'subject_type': 'LK', 'room': '420', 'color': '#e91e63'},
    {'day': 2, 'block': 3, 'week': 'A', 'subject': 'Deutsch', 'subject_type': 'LK', 'room': '226', 'color': '#4285f4'},
    {'day': 2, 'block': 4, 'week': 'A', 'subject': 'Seminar', 'subject_type': 'SK', 'room': '226', 'color': '#607d8b'},
                      
    {'day': 3, 'block': 1, 'week': 'A', 'subject': 'PB', 'subject_type': 'GK', 'room': '124', 'color': '#00bcd4'},
    {'day': 3, 'block': 2, 'week': 'A', 'subject': 'Geschichte', 'subject_type': 'GK', 'room': '124', 'color': '#ea4335'},
    {'day': 3, 'block': 3, 'week': 'A', 'subject': 'Mathe', 'subject_type': 'LK', 'room': '420', 'color': '#e91e63'},
                     
    {'day': 4, 'block': 1, 'week': 'A', 'subject': 'Informatik', 'subject_type': 'GK', 'room': 'PC1', 'color': '#795548'},
    {'day': 4, 'block': 2, 'week': 'A', 'subject': 'Mathe', 'subject_type': 'LK', 'room': '420', 'color': '#e91e63'},
    {'day': 4, 'block': 3, 'week': 'A', 'subject': 'Englisch', 'subject_type': 'GK', 'room': '330', 'color': '#34a853'},
    {'day': 4, 'block': 4, 'week': 'A', 'subject': 'Chemie', 'subject_type': 'GK', 'room': '301', 'color': '#8bc34a'},
                   
    {'day': 5, 'block': 1, 'week': 'A', 'subject': 'Sport', 'subject_type': 'GK', 'room': 'TH', 'color': '#ff9800'},
    {'day': 5, 'block': 2, 'week': 'A', 'subject': 'Deutsch', 'subject_type': 'LK', 'room': '226', 'color': '#4285f4'},
    {'day': 5, 'block': 3, 'week': 'A', 'subject': 'Physik', 'subject_type': 'GK', 'room': '310', 'color': '#9c27b0'},

    {'day': 1, 'block': 1, 'week': 'B', 'subject': 'Englisch', 'subject_type': 'GK', 'room': '330', 'color': '#34a853'},
    {'day': 1, 'block': 2, 'week': 'B', 'subject': 'PB', 'subject_type': 'GK', 'room': '124', 'color': '#00bcd4'},
    {'day': 1, 'block': 3, 'week': 'B', 'subject': 'Deutsch', 'subject_type': 'LK', 'room': '226', 'color': '#4285f4'},
    {'day': 1, 'block': 4, 'week': 'B', 'subject': 'Chemie', 'subject_type': 'GK', 'room': '301', 'color': '#8bc34a'},
                    
    {'day': 2, 'block': 1, 'week': 'B', 'subject': 'Informatik', 'subject_type': 'GK', 'room': 'PC1', 'color': '#795548'},
    {'day': 2, 'block': 2, 'week': 'B', 'subject': 'Mathe', 'subject_type': 'LK', 'room': '420', 'color': '#e91e63'},
    {'day': 2, 'block': 3, 'week': 'B', 'subject': 'Geschichte', 'subject_type': 'GK', 'room': '124', 'color': '#ea4335'},
    {'day': 2, 'block': 4, 'week': 'B', 'subject': 'Seminar', 'subject_type': 'SK', 'room': '226', 'color': '#607d8b'},
                      
    {'day': 3, 'block': 1, 'week': 'B', 'subject': 'Physik', 'subject_type': 'GK', 'room': '310', 'color': '#9c27b0'},
    {'day': 3, 'block': 2, 'week': 'B', 'subject': 'Mathe', 'subject_type': 'LK', 'room': '420', 'color': '#e91e63'},
    {'day': 3, 'block': 3, 'week': 'B', 'subject': 'Deutsch', 'subject_type': 'LK', 'room': '226', 'color': '#4285f4'},
                     
    {'day': 4, 'block': 1, 'week': 'B', 'subject': 'Sport', 'subject_type': 'GK', 'room': 'TH', 'color': '#ff9800'},
    {'day': 4, 'block': 2, 'week': 'B', 'subject': 'Englisch', 'subject_type': 'GK', 'room': '330', 'color': '#34a853'},
    {'day': 4, 'block': 3, 'week': 'B', 'subject': 'Mathe', 'subject_type': 'LK', 'room': '420', 'color': '#e91e63'},
                   
    {'day': 5, 'block': 1, 'week': 'B', 'subject': 'Deutsch', 'subject_type': 'LK', 'room': '226', 'color': '#4285f4'},
    {'day': 5, 'block': 2, 'week': 'B', 'subject': 'Geschichte', 'subject_type': 'GK', 'room': '124', 'color': '#ea4335'},
]

@app.route('/api/hub/school/timetable/default-template', methods=['GET'])
def get_default_timetable_template():
                                                                 
    return jsonify({'success': True, 'template': DEFAULT_TIMETABLE_TEMPLATE})

QUICK_NOTES_FILE = Path(__file__).parent.parent / 'data' / 'quick_notes.json'

def load_quick_notes():
    if QUICK_NOTES_FILE.exists():
        try:
            with open(QUICK_NOTES_FILE, 'r') as f:
                return json.load(f)
        except Exception:
            return []
    return []

def save_quick_notes(notes):
    QUICK_NOTES_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(QUICK_NOTES_FILE, 'w') as f:
        json.dump(notes, f, indent=2, ensure_ascii=False)

@app.route('/api/hub/quick-notes', methods=['GET'])
def get_quick_notes():
    notes = load_quick_notes()
    return jsonify({'notes': notes})

@app.route('/api/hub/quick-notes', methods=['POST'])
def create_quick_note():
    data = request.json
    notes = load_quick_notes()

    note = {
        'id': str(uuid.uuid4()),
        'type': data.get('type', 'note'),
        'title': data.get('title'),
        'content': data.get('content'),
        'created_at': datetime.now().isoformat()
    }

    notes.append(note)
    save_quick_notes(notes)
    return jsonify({'note': note})

@app.route('/api/hub/quick-notes/<note_id>', methods=['DELETE'])
def delete_quick_note(note_id):
    notes = load_quick_notes()
    notes = [n for n in notes if n['id'] != note_id]
    save_quick_notes(notes)
    return jsonify({'success': True})

@app.route('/api/hub/training/sessions', methods=['GET'])
def get_training_sessions():
                                    
    session_type = request.args.get('type')
    sessions = db.get_hub_training_sessions(session_type=session_type)
    return jsonify({'sessions': sessions})

@app.route('/api/hub/training/sessions', methods=['POST'])
def create_training_session():
                                        
    data = request.json
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    exercises = data.get('exercises')
    if isinstance(exercises, (list, dict)):
        exercises = json.dumps(exercises)

    session_id = db.create_hub_training_session(
        session_type=data.get('type'),
        date=data.get('date'),
        duration=data.get('duration'),
        notes=data.get('notes'),
        calories=data.get('calories'),
        exercises=exercises
    )
    session = db.get_hub_training_session(session_id)
    return jsonify({'success': True, 'session': session})

@app.route('/api/hub/training/sessions/<int:session_id>', methods=['GET'])
def get_training_session(session_id):
                                          
    session = db.get_hub_training_session(session_id)
    if not session:
        return jsonify({'success': False, 'error': 'Session not found'}), 404
    return jsonify({'success': True, 'session': session})

@app.route('/api/hub/training/sessions/<int:session_id>', methods=['PUT'])
def update_training_session(session_id):
                                              
    data = request.json
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    session = db.get_hub_training_session(session_id)
    if not session:
        return jsonify({'success': False, 'error': 'Session not found'}), 404

    exercises = data.get('exercises')
    if isinstance(exercises, (list, dict)):
        exercises = json.dumps(exercises)

    db.update_hub_training_session(
        session_id,
        session_type=data.get('type'),
        date=data.get('date'),
        duration=data.get('duration'),
        notes=data.get('notes'),
        calories=data.get('calories'),
        exercises=exercises
    )
    updated_session = db.get_hub_training_session(session_id)
    return jsonify({'success': True, 'session': updated_session})

@app.route('/api/hub/training/sessions/<int:session_id>', methods=['DELETE'])
def delete_training_session(session_id):
                                    
    db.delete_hub_training_session(session_id)
    return jsonify({'success': True})

@app.route('/api/hub/training/health', methods=['GET'])
def get_training_health():
                          
    logs = db.get_hub_training_health()
    return jsonify({'logs': logs})

@app.route('/api/hub/training/health', methods=['POST'])
def create_training_health():
                                                   
    data = request.json
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    date = data.get('date')
                                         
    existing = db.get_hub_training_health_by_date(date)

    if existing:
                             
        db.update_hub_training_health(
            existing['id'],
            sleep=data.get('sleep'),
            energy=data.get('energy'),
            stress=data.get('stress'),
            recovery=data.get('recovery'),
            weight=data.get('weight'),
            notes=data.get('notes')
        )
    else:
                        
        db.create_hub_training_health(
            date=date,
            sleep=data.get('sleep'),
            energy=data.get('energy'),
            stress=data.get('stress'),
            recovery=data.get('recovery'),
            weight=data.get('weight'),
            notes=data.get('notes')
        )

    return jsonify({'success': True})

@app.route('/api/hub/training/goals', methods=['GET'])
def get_training_goals():
                                 
    completed = request.args.get('completed')
    if completed is not None:
        completed = completed.lower() == 'true'
    goals = db.get_hub_training_goals(completed=completed)
    return jsonify({'goals': goals})

@app.route('/api/hub/training/goals', methods=['POST'])
def create_training_goal():
                                     
    data = request.json
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    goal_id = db.create_hub_training_goal(
        title=data.get('title'),
        target=data.get('target'),
        current=data.get('current', 0),
        unit=data.get('unit'),
        deadline=data.get('deadline')
    )
    goal = db.get_hub_training_goal(goal_id)
    return jsonify({'success': True, 'goal': goal})

@app.route('/api/hub/training/goals/<int:goal_id>', methods=['GET'])
def get_training_goal(goal_id):
                                       
    goal = db.get_hub_training_goal(goal_id)
    if not goal:
        return jsonify({'success': False, 'error': 'Goal not found'}), 404
    return jsonify({'success': True, 'goal': goal})

@app.route('/api/hub/training/goals/<int:goal_id>', methods=['PUT'])
def update_training_goal(goal_id):
                                           
    data = request.json
    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    goal = db.get_hub_training_goal(goal_id)
    if not goal:
        return jsonify({'success': False, 'error': 'Goal not found'}), 404

    db.update_hub_training_goal(
        goal_id,
        title=data.get('title'),
        target=data.get('target'),
        current=data.get('current'),
        unit=data.get('unit'),
        deadline=data.get('deadline'),
        completed=data.get('completed')
    )
    updated_goal = db.get_hub_training_goal(goal_id)
    return jsonify({'success': True, 'goal': updated_goal})

@app.route('/api/hub/training/goals/<int:goal_id>', methods=['DELETE'])
def delete_training_goal(goal_id):
                                 
    db.delete_hub_training_goal(goal_id)
    return jsonify({'success': True})

@app.route('/api/hub/training/holiday-check', methods=['GET'])
def check_holiday_mode():
\
\
\
\
       
    from datetime import datetime, timedelta

    today = datetime.now().date()
    today_str = today.strftime('%Y-%m-%d')

    holiday_keywords = [
        'ferien',                                        
        'schulferien',                       
        'herbstferien',                 
        'winterferien',                   
        'osterferien',                    
        'sommerferien',                   
        'weihnachtsferien',                  
        'pfingstferien',                     
        'frühjahrsferien',                
        'urlaub',                                
        'vacation',                           
        'school holiday',                           
    ]

    def check_event_is_holiday(event):
                                                                                       
        title = (event.get('title') or event.get('summary') or '').lower()

        calendar = (event.get('calendar') or event.get('calendar_id') or '').lower()
        if 'holiday@group' in calendar or 'feiertage' in calendar:
            return False

        return any(keyword in title for keyword in holiday_keywords)

    def event_covers_today(event):
                                                 
        start = event.get('date') or event.get('start_date') or ''
        end = event.get('end_date') or event.get('end') or start

        if isinstance(start, dict):
            start = start.get('date') or start.get('dateTime', '')[:10]
        if isinstance(end, dict):
            end = end.get('date') or end.get('dateTime', '')[:10]

        if 'T' in str(start):
            start = str(start).split('T')[0]
        if 'T' in str(end):
            end = str(end).split('T')[0]

        try:
            return start <= today_str <= (end or start)
        except:
            return False

    is_holiday = False
    source = None

    try:
        school_events = load_school_calendar()
        for event in school_events:
            if event_covers_today(event) and check_event_is_holiday(event):
                is_holiday = True
                source = 'school_calendar'
                break
    except Exception as e:
        print(f"School calendar check failed: {e}")

    if not is_holiday:
        try:
            from google_oauth import fetch_google_calendar_events, load_tokens

            tokens = load_tokens()
            if tokens:
                                                    
                result = fetch_google_calendar_events(
                    days_ahead=1,
                    start_date=today_str,
                    end_date=today_str
                )

                if result.get('success'):
                    for event in result.get('events', []):
                        if check_event_is_holiday(event):
                            is_holiday = True
                            source = 'google_calendar'
                            break
        except Exception as e:
            print(f"Google Calendar check failed: {e}")
                                                                                   
    return jsonify({
        'is_holiday': is_holiday,
        'source': source,
        'date': today_str
    })

# Training Schedule API Endpoints
@app.route('/api/hub/training/schedule/settings', methods=['GET'])
def get_training_schedule_settings_route():
    """Get training schedule settings, optionally filtered by user_id"""
    user_id = request.args.get('user_id')
    settings = db.get_training_schedule_settings(user_id=user_id)
    if settings:
        return jsonify({'success': True, 'settings': settings})
    return jsonify({'success': True, 'settings': None, 'setup_required': True})

@app.route('/api/hub/training/schedule/settings', methods=['POST'])
def save_training_schedule_settings_route():
    """Save training schedule settings with optional user_id"""
    data = request.get_json()
    settings_id = db.save_training_schedule_settings(
        schedule_mode=data.get('schedule_mode', 'regular'),
        auto_detect_holiday=data.get('auto_detect_holiday', True),
        setup_completed=data.get('setup_completed', False),
        user_id=data.get('user_id')
    )
    return jsonify({'success': True, 'settings_id': settings_id})

@app.route('/api/hub/training/schedule/entries', methods=['GET'])
def get_training_schedule_entries_route():
    """Get training schedule entries, optionally filtered by user_id"""
    day = request.args.get('day', type=int)
    schedule_type = request.args.get('schedule_type')
    user_id = request.args.get('user_id')
    entries = db.get_training_schedule_entries(day=day, schedule_type=schedule_type, user_id=user_id)
    return jsonify({'success': True, 'entries': entries})

@app.route('/api/hub/training/schedule/entries', methods=['POST'])
def create_training_schedule_entry_route():
    """Create training schedule entry with optional user_id"""
    data = request.get_json()
    if data.get('day') is None or not data.get('training_type') or not data.get('title'):
        return jsonify({'success': False, 'error': 'day, training_type, and title are required'}), 400

    entry_id = db.create_training_schedule_entry(
        day=data['day'],
        training_type=data['training_type'],
        title=data['title'],
        schedule_type=data.get('schedule_type', 'regular'),
        time=data.get('time'),
        duration=data.get('duration'),
        location=data.get('location'),
        muscle_groups=data.get('muscle_groups'),
        notes=data.get('notes'),
        icon=data.get('icon'),
        color=data.get('color'),
        user_id=data.get('user_id')
    )
    entry = db.get_training_schedule_entry(entry_id)
    return jsonify({'success': True, 'entry': entry})

@app.route('/api/hub/training/schedule/entries/<int:entry_id>', methods=['GET'])
def get_training_schedule_entry_route(entry_id):
    entry = db.get_training_schedule_entry(entry_id)
    if entry:
        return jsonify({'success': True, 'entry': entry})
    return jsonify({'success': False, 'error': 'Entry not found'}), 404

@app.route('/api/hub/training/schedule/entries/<int:entry_id>', methods=['PUT'])
def update_training_schedule_entry_route(entry_id):
    data = request.get_json()
    success = db.update_training_schedule_entry(
        entry_id=entry_id,
        day=data.get('day'),
        schedule_type=data.get('schedule_type'),
        training_type=data.get('training_type'),
        title=data.get('title'),
        time=data.get('time'),
        duration=data.get('duration'),
        location=data.get('location'),
        muscle_groups=data.get('muscle_groups'),
        notes=data.get('notes'),
        icon=data.get('icon'),
        color=data.get('color')
    )
    if success:
        entry = db.get_training_schedule_entry(entry_id)
        return jsonify({'success': True, 'entry': entry})
    return jsonify({'success': False, 'error': 'Entry not found'}), 404

@app.route('/api/hub/training/schedule/entries/<int:entry_id>', methods=['DELETE'])
def delete_training_schedule_entry_route(entry_id):
    success = db.delete_training_schedule_entry(entry_id)
    if success:
        return jsonify({'success': True})
    return jsonify({'success': False, 'error': 'Entry not found'}), 404

@app.route('/api/hub/training/schedule/clear', methods=['POST'])
def clear_training_schedule_route():
    """Clear training schedule, optionally filtered by user_id"""
    data = request.get_json() or {}
    schedule_type = data.get('schedule_type')
    user_id = data.get('user_id')
    count = db.clear_training_schedule(schedule_type, user_id=user_id)
    return jsonify({'success': True, 'deleted': count})

@app.route('/api/hub/training/schedule/import', methods=['POST'])
def import_training_schedule_route():
    """Import training schedule template with optional user_id"""
    data = request.get_json()
    if not data or not data.get('entries'):
        return jsonify({'success': False, 'error': 'entries required'}), 400

    user_id = data.get('user_id')
    if data.get('clear_existing', False):
        db.clear_training_schedule(data.get('schedule_type'), user_id=user_id)

    count = db.import_training_schedule_template(data['entries'], user_id=user_id)
    return jsonify({'success': True, 'imported': count})

@app.route('/api/email/accounts', methods=['GET'])
def get_email_accounts_route():
    from email_service import get_email_accounts
    from google_oauth import get_google_accounts
    from .iserv_service import get_iserv_service
                                                                
    imap_accounts = get_email_accounts()
    google_accounts = get_google_accounts()

    iserv_accounts = []
    iserv_service = get_iserv_service()
    status = iserv_service.get_status()
    if status.get('connected') or status.get('has_credentials'):
        username = status.get('username', 'IServ')
        iserv_url = status.get('iserv_url', '')
        iserv_accounts = [{
            'email': f'{username}@iserv',
            'provider': 'iserv',
            'display_name': f'IServ ({username})'
        }]

    return jsonify(imap_accounts + google_accounts + iserv_accounts)

@app.route('/api/email/accounts', methods=['POST'])
def add_email_account_route():
    from email_service import add_email_account
    data = request.get_json()
    if not data:
        return jsonify({'error': 'No data provided'}), 400

    email = data.get('email', '').strip()
    password = data.get('password', '')
    provider = data.get('provider', '')

    if not email or not password or not provider:
        return jsonify({'error': 'Email, password, and provider are required'}), 400

    result = add_email_account(email, password, provider)
    if result['success']:
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/email/accounts/<path:email>', methods=['DELETE'])
def remove_email_account_route(email):
    from email_service import remove_email_account
    from google_oauth import remove_google_account, get_google_accounts

    google_accounts = [a['email'] for a in get_google_accounts()]
    if email in google_accounts:
        success = remove_google_account(email)
    else:
        success = remove_email_account(email)

    if success:
        return jsonify({'success': True})
    return jsonify({'error': 'Account not found'}), 404

@app.route('/api/email/folders/<path:email>', methods=['GET'])
def get_email_folders_route(email):
    from email_service import get_folders
    result = get_folders(email)
    if result['success']:
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/email/messages/<path:email>', methods=['GET'])
def get_email_messages_route(email):
    from email_service import fetch_emails
    from google_oauth import get_google_accounts, fetch_gmail_messages
    from .iserv_service import get_iserv_service

    if email.endswith('@iserv'):
        iserv_service = get_iserv_service()
        if not iserv_service.is_connected():
                                                    
            iserv_service.connect()
        result = iserv_service.get_emails(limit=request.args.get('limit', 20, type=int))
        if result.get('success'):
                                                       
            emails = result.get('emails', [])
            transformed = []
            for e in emails:
                transformed.append({
                    'id': e.get('uid') or e.get('id') or str(hash(e.get('subject', ''))),
                    'from': e.get('from', e.get('sender', '')),
                    'from_name': e.get('from_name', e.get('from', '').split('@')[0]),
                    'subject': e.get('subject', '(Kein Betreff)'),
                    'date': e.get('date', ''),
                    'preview': e.get('preview', e.get('snippet', '')),
                    'read': e.get('read', not e.get('unseen', False))
                })
            return jsonify({'success': True, 'emails': transformed})
        return jsonify(result), 400

    google_accounts = [a['email'] for a in get_google_accounts()]
    if email in google_accounts:
        limit = request.args.get('limit', 20, type=int)
        result = fetch_gmail_messages(email, limit)
    else:
        folder = request.args.get('folder', 'INBOX')
        limit = request.args.get('limit', 20, type=int)
        result = fetch_emails(email, folder, limit)

    if result['success']:
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/email/message/<path:email>/<msg_id>', methods=['GET'])
def get_email_detail_route(email, msg_id):
    from email_service import get_email_detail
    from google_oauth import get_google_accounts, get_gmail_message_detail
    from .iserv_service import get_iserv_service

    if email.endswith('@iserv'):
        iserv_service = get_iserv_service()
        if not iserv_service.is_connected():
            iserv_service.connect()
        result = iserv_service.get_email_detail(msg_id)
        if result.get('success'):
            return jsonify(result)
        return jsonify(result), 400

    google_accounts = [a['email'] for a in get_google_accounts()]
    if email in google_accounts:
        result = get_gmail_message_detail(email, msg_id)
    else:
        folder = request.args.get('folder', 'INBOX')
        result = get_email_detail(email, msg_id, folder)

    if result['success']:
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/email/send', methods=['POST'])
def send_email_route():
    from email_service import send_email
    from google_oauth import get_google_accounts, send_gmail
    from .iserv_service import get_iserv_service
    data = request.get_json()
    if not data:
        return jsonify({'error': 'No data provided'}), 400

    from_email = data.get('from_email', data.get('from', '')).strip()
    to_email = data.get('to_email', data.get('to', '')).strip()
    subject = data.get('subject', '').strip()
    body = data.get('body', '')

    if not from_email or not to_email or not subject:
        return jsonify({'error': 'From, to, and subject are required'}), 400

    if from_email.endswith('@iserv'):
        iserv_service = get_iserv_service()
        if not iserv_service.is_connected():
            iserv_service.connect()
        result = iserv_service.send_email(to=to_email, subject=subject, body=body)
        if result.get('success'):
            return jsonify(result)
        return jsonify(result), 400

    google_accounts = [a['email'] for a in get_google_accounts()]
    if from_email in google_accounts:
        result = send_gmail(from_email, to_email, subject, body)
    else:
        result = send_email(from_email, to_email, subject, body)

    if result['success']:
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/email/google/status', methods=['GET'])
def google_oauth_status():
                                                  
    from google_oauth import get_oauth_status
    return jsonify(get_oauth_status())

@app.route('/api/email/google/auth', methods=['POST'])
def start_google_auth():
                                  
    from google_oauth import start_oauth_flow
    result = start_oauth_flow()
    return jsonify(result)

@app.route('/api/email/google/callback', methods=['POST'])
def complete_google_auth():
                                                                       
    from google_oauth import complete_oauth_flow
    data = request.get_json()
    if not data or not data.get('code'):
        return jsonify({'success': False, 'error': 'Authorization code required'}), 400
    result = complete_oauth_flow(data['code'])
    return jsonify(result)

@app.route('/api/email/google/oauth-callback', methods=['GET'])
def google_oauth_redirect_callback():
                                            
    from google_oauth import complete_oauth_flow

    code = request.args.get('code')
    error = request.args.get('error')

    if error:
        return f'''
        <html><body style="font-family: -apple-system, sans-serif; text-align: center; padding: 50px;">
            <h2 style="color: #d93025;">Authorization Failed</h2>
            <p>Error: {error}</p>
            <p>You can close this window and try again.</p>
            <script>setTimeout(() => window.close(), 3000);</script>
        </body></html>
        '''

    if not code:
        return '''
        <html><body style="font-family: -apple-system, sans-serif; text-align: center; padding: 50px;">
            <h2 style="color: #d93025;">No Authorization Code</h2>
            <p>No authorization code received from Google.</p>
            <script>setTimeout(() => window.close(), 3000);</script>
        </body></html>
        '''

    result = complete_oauth_flow(code)

    if result.get('success'):
        email = result.get('email', 'your account')
        return f'''
        <html><body style="font-family: -apple-system, sans-serif; text-align: center; padding: 50px;">
            <h2 style="color: #34a853;">Successfully Connected!</h2>
            <p>Connected: <strong>{email}</strong></p>
            <p>You can close this window and return to Nexus.</p>
            <script>
                // Notify opener window
                if (window.opener) {{
                    window.opener.postMessage({{ type: 'google-oauth-success', email: '{email}' }}, '*');
                }}
                setTimeout(() => window.close(), 2000);
            </script>
        </body></html>
        '''
    else:
        error_msg = result.get('error', 'Unknown error')
        return f'''
        <html><body style="font-family: -apple-system, sans-serif; text-align: center; padding: 50px;">
            <h2 style="color: #d93025;">Connection Failed</h2>
            <p>{error_msg}</p>
            <p>Please close this window and try again.</p>
            <script>setTimeout(() => window.close(), 5000);</script>
        </body></html>
        '''

@app.route('/api/email/google/accounts', methods=['GET'])
def list_google_accounts():
                                         
    from google_oauth import get_google_accounts
    accounts = get_google_accounts()
    return jsonify({'accounts': accounts})

@app.route('/api/email/google/remove/<path:email>', methods=['DELETE'])
def remove_google_account_route(email):
                                        
    from google_oauth import remove_google_account
    success = remove_google_account(email)
    return jsonify({'success': success})

@app.route('/api/calendar/events', methods=['GET'])
def get_calendar_events():
                                                                                   
    from google_oauth import fetch_google_calendar_events, load_tokens

    start_date = request.args.get('start')
    end_date = request.args.get('end')
    days = request.args.get('days', 14, type=int)
    account = request.args.get('account')                                     

    tokens = load_tokens()
    if tokens:
        result = fetch_google_calendar_events(
            days_ahead=days,
            account_email=account,
            start_date=start_date,
            end_date=end_date
        )
        if result.get('success'):
            return jsonify(result)
                                                                         
        if result.get('error') == 'scope_needed':
            return jsonify(result)

    from calendar_service import get_macos_calendar_events
    result = get_macos_calendar_events(days)
    return jsonify(result)

@app.route('/api/calendar/macos', methods=['GET'])
def get_macos_calendar():
                                               
    from calendar_service import get_macos_calendar_events
    days = request.args.get('days', 14, type=int)
    result = get_macos_calendar_events(days)
    return jsonify(result)

@app.route('/api/calendar/list', methods=['GET'])
def get_calendar_list():
                                                
    from calendar_service import get_calendars
    result = get_calendars()
    return jsonify(result)

@app.route('/api/calendar/google/calendars', methods=['GET'])
def get_google_calendars_route():
                                                      
    from google_oauth import get_google_calendars
    account = request.args.get('account')
    result = get_google_calendars(account_email=account)
    return jsonify(result)

@app.route('/api/calendar/events', methods=['POST'])
def create_calendar_event():
                                                
    from google_oauth import create_google_calendar_event
    data = request.get_json()

    if not data or not data.get('title') or not data.get('date'):
        return jsonify({'success': False, 'error': 'Title and date are required'}), 400

    result = create_google_calendar_event(
        title=data['title'],
        start_date=data['date'],
        start_time=data.get('time'),
        end_date=data.get('end_date'),
        end_time=data.get('end_time'),
        description=data.get('description'),
        location=data.get('location'),
        calendar_id=data.get('calendar_id', 'primary'),
        account_email=data.get('account')
    )

    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/calendar/events/<event_id>', methods=['PUT'])
def update_calendar_event(event_id):
                                                      
    from google_oauth import update_google_calendar_event
    data = request.get_json()

    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    result = update_google_calendar_event(
        event_id=event_id,
        title=data.get('title'),
        start_date=data.get('date'),
        start_time=data.get('time'),
        end_date=data.get('end_date'),
        end_time=data.get('end_time'),
        description=data.get('description'),
        location=data.get('location'),
        calendar_id=data.get('calendar_id', 'primary'),
        account_email=data.get('account')
    )

    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/calendar/events/<event_id>', methods=['DELETE'])
def delete_calendar_event(event_id):
                                               
    from google_oauth import delete_google_calendar_event

    calendar_id = request.args.get('calendar_id', 'primary')
    account = request.args.get('account')

    result = delete_google_calendar_event(
        event_id=event_id,
        calendar_id=calendar_id,
        account_email=account
    )

    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/calendar/caldav/accounts', methods=['GET'])
def get_caldav_accounts_route():
                                      
    from calendar_service import get_caldav_accounts
    accounts = get_caldav_accounts()
    return jsonify({'success': True, 'accounts': accounts})

@app.route('/api/calendar/caldav/accounts', methods=['POST'])
def add_caldav_account_route():
                                                           
    from calendar_service import add_caldav_account
    data = request.get_json()

    if not data:
        return jsonify({'success': False, 'error': 'No data provided'}), 400

    result = add_caldav_account(
        name=data.get('name', ''),
        url=data.get('url', ''),
        username=data.get('username', ''),
        password=data.get('password', ''),
        provider=data.get('provider', 'caldav')
    )

    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/calendar/caldav/accounts/<account_id>', methods=['DELETE'])
def remove_caldav_account_route(account_id):
                                  
    from calendar_service import remove_caldav_account
    result = remove_caldav_account(account_id)
    return jsonify(result)

@app.route('/api/calendar/caldav/events', methods=['GET'])
def get_caldav_events_route():
                                            
    from calendar_service import fetch_caldav_events

    account_id = request.args.get('account_id')
    start_date = request.args.get('start')
    end_date = request.args.get('end')
    days = request.args.get('days', 30, type=int)

    result = fetch_caldav_events(
        account_id=account_id,
        days_ahead=days,
        start_date=start_date,
        end_date=end_date
    )

    return jsonify(result)

@app.route('/api/calendar/caldav/events', methods=['POST'])
def create_caldav_event_route():
                                               
    from calendar_service import create_caldav_event
    data = request.get_json()

    if not data or not data.get('account_id') or not data.get('calendar_url'):
        return jsonify({'success': False, 'error': 'Account ID and calendar URL required'}), 400

    result = create_caldav_event(
        account_id=data['account_id'],
        calendar_url=data['calendar_url'],
        title=data.get('title', 'Untitled'),
        start_date=data.get('date'),
        start_time=data.get('time'),
        end_date=data.get('end_date'),
        end_time=data.get('end_time'),
        description=data.get('description', ''),
        location=data.get('location', '')
    )

    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/email/message/<path:email>/<msg_id>', methods=['DELETE'])
def delete_email_message(email, msg_id):
                                  
    from google_oauth import get_google_accounts, delete_gmail_message
    from email_service import delete_email

    permanent = request.args.get('permanent', 'false').lower() == 'true'

    google_accounts = [a['email'] for a in get_google_accounts()]
    if email in google_accounts:
        result = delete_gmail_message(email, msg_id, permanent=permanent)
    else:
                                                  
        result = delete_email(email, msg_id)

    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/iserv/status', methods=['GET'])
def iserv_status():
                                      
    from .iserv_service import get_iserv_service
    service = get_iserv_service()
    return jsonify(service.get_status())

@app.route('/api/iserv/connect', methods=['POST'])
def iserv_connect():
                                            
    from .iserv_service import get_iserv_service
    data = request.get_json() or {}
    service = get_iserv_service()

    result = service.connect(
        username=data.get('username'),
        password=data.get('password'),
        iserv_url=data.get('iserv_url')
    )

    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/iserv/disconnect', methods=['POST'])
def iserv_disconnect():
                                                      
    from .iserv_service import get_iserv_service
    service = get_iserv_service()
    service.delete_credentials()
    return jsonify({'success': True})

@app.route('/api/iserv/notifications', methods=['GET'])
def iserv_notifications():
                                  
    from .iserv_service import get_iserv_service
    service = get_iserv_service()
    result = service.get_notifications()
    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/iserv/badges', methods=['GET'])
def iserv_badges():
                                        
    from .iserv_service import get_iserv_service
    service = get_iserv_service()
    result = service.get_badges()
    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/iserv/emails', methods=['GET'])
def iserv_emails():
                                
    from .iserv_service import get_iserv_service
    service = get_iserv_service()
    folder = request.args.get('folder', 'INBOX')
    limit = int(request.args.get('limit', 20))
    result = service.get_emails(folder=folder, limit=limit)
    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/iserv/emails/send', methods=['POST'])
def iserv_send_email():
                                  
    from .iserv_service import get_iserv_service
    data = request.get_json() or {}
    service = get_iserv_service()

    result = service.send_email(
        to=data.get('to'),
        subject=data.get('subject'),
        body=data.get('body')
    )

    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/iserv/mail-folders', methods=['GET'])
def iserv_mail_folders():
                                 
    from .iserv_service import get_iserv_service
    service = get_iserv_service()
    result = service.get_mail_folders()
    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/iserv/events', methods=['GET'])
def iserv_events():
                                             
    from .iserv_service import get_iserv_service
    service = get_iserv_service()
    result = service.get_upcoming_events()
    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/iserv/events', methods=['POST'])
def iserv_create_event():
                                         
    from .iserv_service import get_iserv_service
    from datetime import datetime
    data = request.get_json() or {}
    service = get_iserv_service()

    start = datetime.fromisoformat(data.get('start'))
    end = datetime.fromisoformat(data.get('end')) if data.get('end') else None

    result = service.create_event(
        title=data.get('title'),
        start=start,
        end=end,
        description=data.get('description', ''),
        location=data.get('location', '')
    )

    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/iserv/exercises', methods=['GET'])
def iserv_exercises():
                                       
    from .iserv_service import get_iserv_service
    service = get_iserv_service()
    result = service.get_exercises()
    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/iserv/storage', methods=['GET'])
def iserv_storage():
                                 
    from .iserv_service import get_iserv_service
    service = get_iserv_service()
    result = service.get_storage_info()
    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/iserv/files', methods=['GET'])
def iserv_files():
                              
    from .iserv_service import get_iserv_service
    service = get_iserv_service()
    path = request.args.get('path', '/')
    result = service.list_files(path=path)
    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/iserv/users/search', methods=['GET'])
def iserv_search_users():
                                    
    from .iserv_service import get_iserv_service
    service = get_iserv_service()
    query = request.args.get('q', '')
    result = service.search_users(query=query)
    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/iserv/vertretungsplan', methods=['GET'])
def iserv_get_vertretungsplan():
                                                     
    from .iserv_service import get_iserv_service
    service = get_iserv_service()
    display_id = request.args.get('display_id', 3, type=int)
    refresh = request.args.get('refresh', 'false').lower() == 'true'

    if refresh and service.is_connected():
                                          
        service.connect()

    result = service.get_vertretungsplan(display_id=display_id)
    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/iserv/vertretungsplan/analyze', methods=['GET'])
def iserv_analyze_vertretungsplan():
                                                                      
    from .iserv_service import get_iserv_service
    import base64
    import io

    service = get_iserv_service()
    display_id = request.args.get('display_id', 3, type=int)
    grade_filter = request.args.get('grade', '11')                              

    result = service.get_vertretungsplan(display_id=display_id)

    if not result.get('success'):
        return jsonify(result), 400

    if result.get('type') == 'image':
                                                                      
        return jsonify({
            'success': True,
            'type': 'image',
            'message': 'Vertretungsplan als Bild empfangen. OCR-Analyse erforderlich.',
            'data': result.get('data'),
            'content_type': result.get('content_type')
        })
    elif result.get('type') == 'html':
                                                     
        text = result.get('text', '')
        lines = text.split('\n')

        substitutions = []
        for line in lines:
            line = line.strip()
            if not line:
                continue
                                                       
            if grade_filter in line or 'Jg.' in line or 'Klasse' in line:
                substitutions.append(line)

        return jsonify({
            'success': True,
            'type': 'parsed',
            'substitutions': substitutions,
            'raw_text': text[:2000],
            'grade_filter': grade_filter
        })

    return jsonify(result)

@app.route('/api/vbb/search', methods=['GET'])
def vbb_search_location():
                                        
    from vbb_service import get_vbb_service
    service = get_vbb_service()
    query = request.args.get('q', '')
    if not query:
        return jsonify({'success': False, 'error': 'Suchbegriff fehlt'}), 400
    result = service.search_location(query)
    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/vbb/nearby', methods=['GET'])
def vbb_nearby_stops():
                                      
    from vbb_service import get_vbb_service
    service = get_vbb_service()
    try:
        lat = float(request.args.get('lat', 0))
        lng = float(request.args.get('lng', 0))
        radius = int(request.args.get('radius', 1000))
    except ValueError:
        return jsonify({'success': False, 'error': 'Ungültige Koordinaten'}), 400

    if lat == 0 or lng == 0:
        return jsonify({'success': False, 'error': 'Koordinaten fehlen'}), 400

    result = service.search_nearby_stops(lat, lng, radius)
    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/vbb/route', methods=['POST'])
def vbb_get_route():
                                          
    from vbb_service import get_vbb_service
    from datetime import datetime
    service = get_vbb_service()

    data = request.get_json() or {}

    from_location = data.get('from')
    to_location = data.get('to')

    if not from_location or not to_location:
        return jsonify({'success': False, 'error': 'Start und Ziel erforderlich'}), 400

    arrival_time = None
    departure_time = None

    if data.get('arrival'):
        try:
            arrival_time = datetime.fromisoformat(data['arrival'].replace('Z', '+00:00'))
        except ValueError:
            pass

    if data.get('departure'):
        try:
            departure_time = datetime.fromisoformat(data['departure'].replace('Z', '+00:00'))
        except ValueError:
            pass

    result = service.get_route(
        from_location=from_location,
        to_location=to_location,
        arrival_time=arrival_time,
        departure_time=departure_time,
        num_results=data.get('results', 5)
    )

    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/vbb/route-to-event', methods=['POST'])
def vbb_route_to_event():
                                        
    from vbb_service import get_vbb_service
    service = get_vbb_service()

    data = request.get_json() or {}

    event = data.get('event')
    current_location = data.get('current_location')
    buffer_minutes = data.get('buffer_minutes', 15)

    if not event:
        return jsonify({'success': False, 'error': 'Event erforderlich'}), 400

    if not current_location:
        return jsonify({'success': False, 'error': 'Aktueller Standort erforderlich'}), 400

    result = service.get_route_to_event(
        event=event,
        current_location=current_location,
        buffer_minutes=buffer_minutes
    )

    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/vbb/departures/<stop_id>', methods=['GET'])
def vbb_departures(stop_id):
                                     
    from vbb_service import get_vbb_service
    service = get_vbb_service()
    duration = int(request.args.get('duration', 30))
    result = service.get_departures(stop_id, duration)
    if result.get('success'):
        return jsonify(result)
    return jsonify(result), 400

@app.route('/api/vbb/locations', methods=['GET'])
def vbb_get_known_locations():
                                    
    from vbb_service import get_vbb_service
    service = get_vbb_service()
    return jsonify(service.get_known_locations())

@app.route('/api/vbb/locations', methods=['POST'])
def vbb_save_location():
                                
    from vbb_service import get_vbb_service
    service = get_vbb_service()
    data = request.get_json() or {}

    name = data.get('name')
    location = data.get('location')

    if not name or not location:
        return jsonify({'success': False, 'error': 'Name und Ort erforderlich'}), 400

    result = service.save_known_location(name, location)
    return jsonify(result)

SYNCED_CALENDAR_FILE = Path(__file__).parent.parent / 'data' / 'synced_calendar.json'

@app.route('/api/calendar/local', methods=['GET'])
def get_local_calendar_events():
                                                            
    if not SYNCED_CALENDAR_FILE.exists():
        return jsonify({
            'success': False,
            'error': 'Kalender nicht synchronisiert. Führe calendar_sync.py aus.'
        }), 404

    try:
        with open(SYNCED_CALENDAR_FILE, 'r') as f:
            data = json.load(f)

        return jsonify({
            'success': True,
            'last_sync': data.get('last_sync'),
            'event_count': data.get('event_count', 0),
            'events': data.get('events', [])
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/calendar/local/sync', methods=['POST'])
def trigger_local_calendar_sync():
                                           
    import subprocess

    try:
                             
        script_path = Path(__file__).parent.parent / 'calendar_sync.py'
        if not script_path.exists():
            return jsonify({'success': False, 'error': 'Sync-Skript nicht gefunden'}), 404

        result = subprocess.run(
            ['python3', str(script_path), '--sync'],
            capture_output=True,
            text=True,
            timeout=60
        )

        if result.returncode == 0:
            return jsonify({'success': True, 'message': 'Synchronisation abgeschlossen'})
        else:
            return jsonify({'success': False, 'error': result.stderr or 'Sync fehlgeschlagen'}), 500

    except subprocess.TimeoutExpired:
        return jsonify({'success': False, 'error': 'Timeout bei der Synchronisation'}), 500
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/calendar/local/status', methods=['GET'])
def get_local_calendar_status():
                                                           
    import subprocess

    try:
        script_path = Path(__file__).parent.parent / 'calendar_sync.py'
        pid_file = Path(__file__).parent.parent / 'data' / 'calendar_sync.pid'

        daemon_running = False
        daemon_pid = None

        if pid_file.exists():
            try:
                with open(pid_file, 'r') as f:
                    daemon_pid = int(f.read().strip())
                                             
                import os
                os.kill(daemon_pid, 0)
                daemon_running = True
            except (ValueError, OSError, ProcessLookupError):
                daemon_running = False

        last_sync = None
        event_count = 0

        if SYNCED_CALENDAR_FILE.exists():
            with open(SYNCED_CALENDAR_FILE, 'r') as f:
                data = json.load(f)
                last_sync = data.get('last_sync')
                event_count = data.get('event_count', 0)

        return jsonify({
            'success': True,
            'daemon_running': daemon_running,
            'daemon_pid': daemon_pid,
            'last_sync': last_sync,
            'event_count': event_count
        })

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

WEATHER_CACHE_FILE = Path(__file__).parent.parent / 'data' / 'weather_cache.json'

@app.route('/api/hub/weather', methods=['GET'])
def get_weather():
                                                                 
    import requests

    lat = request.args.get('lat', '52.52')                   
    lon = request.args.get('lon', '13.41')
    city = request.args.get('city', 'Berlin')

    try:
                                         
        response = requests.get(
            f'https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,weather_code,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,weather_code&timezone=auto',
            timeout=10
        )

        if response.ok:
            data = response.json()
            weather_data = {
                'current': data.get('current'),
                'daily': data.get('daily'),
                'location': {'lat': lat, 'lon': lon, 'city': city},
                'timestamp': datetime.now().isoformat(),
                'fetched_at': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }

            WEATHER_CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
            with open(WEATHER_CACHE_FILE, 'w') as f:
                json.dump(weather_data, f)

            return jsonify({
                'success': True,
                'from_cache': False,
                **weather_data
            })
        else:
            raise Exception('Weather API error')

    except Exception as e:
                                            
        if WEATHER_CACHE_FILE.exists():
            try:
                with open(WEATHER_CACHE_FILE, 'r') as f:
                    cached_data = json.load(f)
                return jsonify({
                    'success': True,
                    'from_cache': True,
                    'cached_at': cached_data.get('timestamp'),
                    **cached_data
                })
            except:
                pass

        return jsonify({
            'success': False,
            'error': str(e),
            'offline': True
        }), 503

BRANDENBURG_HOLIDAYS_FILE = Path(__file__).parent.parent / 'data' / 'brandenburg_holidays.json'

@app.route('/api/calendar/holidays', methods=['GET'])
def get_holidays():
                                                        
    try:
        if not BRANDENBURG_HOLIDAYS_FILE.exists():
            return jsonify({'success': True, 'holidays': []})

        with open(BRANDENBURG_HOLIDAYS_FILE, 'r') as f:
            data = json.load(f)

        return jsonify({
            'success': True,
            'source': data.get('source', 'Brandenburg Schulferien'),
            'holidays': data.get('holidays', [])
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

if __name__ == '__main__':
    import socket

    # Get local IP for network access
    def get_local_ip():
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return None

    local_ip = get_local_ip()

    print("\n" + "=" * 50)
    print("  Nexus Hub - Personal Dashboard")
    print("=" * 50)
    print(f"\n  Desktop:  http://localhost:5050")
    if local_ip:
        print(f"  Mobile:   http://{local_ip}:5050")
    print("\n  Tipp: Auf dem Handy die Mobile-URL eingeben")
    print("        und 'Zum Home-Bildschirm' hinzufugen!")
    print("=" * 50 + "\n")

    # Bind to 0.0.0.0 to allow network access from mobile devices
    socketio.run(app, host='0.0.0.0', port=5050, debug=False, allow_unsafe_werkzeug=True)
