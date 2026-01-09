import os
import json
import base64
import imaplib
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.utils import parsedate_to_datetime, formatdate
from email.header import decode_header
from typing import Dict, List, Optional
from datetime import datetime
import re

# Use project data directory
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(PROJECT_ROOT, "data")
os.makedirs(DATA_DIR, exist_ok=True)
EMAIL_CONFIG_PATH = os.path.join(DATA_DIR, "email_config.json")

PROVIDER_SETTINGS = {
    "gmail": {
        "imap_host": "imap.gmail.com",
        "imap_port": 993,
        "smtp_host": "smtp.gmail.com",
        "smtp_port": 587,
        "requires_app_password": True
    },
    "outlook": {
        "imap_host": "outlook.office365.com",
        "imap_port": 993,
        "smtp_host": "smtp.office365.com",
        "smtp_port": 587,
        "requires_app_password": False
    }
}

def load_email_config() -> Dict:
    if not os.path.exists(EMAIL_CONFIG_PATH):
        return {"accounts": []}
    try:
        with open(EMAIL_CONFIG_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return {"accounts": []}

def save_email_config(config: Dict) -> bool:
    os.makedirs(os.path.dirname(EMAIL_CONFIG_PATH), exist_ok=True)
    try:
        with open(EMAIL_CONFIG_PATH, 'w', encoding='utf-8') as f:
            json.dump(config, f, ensure_ascii=False, indent=2)
        return True
    except IOError:
        return False

def add_email_account(email: str, password: str, provider: str) -> Dict:
    if provider not in PROVIDER_SETTINGS:
        return {"success": False, "error": "Unsupported provider"}

    settings = PROVIDER_SETTINGS[provider]
    try:
        imap = imaplib.IMAP4_SSL(settings["imap_host"], settings["imap_port"])
        imap.login(email, password)
        imap.logout()
    except imaplib.IMAP4.error as e:
        error_msg = str(e)
        if "AUTHENTICATIONFAILED" in error_msg or "Invalid credentials" in error_msg:
            if provider == "gmail":
                return {"success": False, "error": "Authentication failed. For Gmail, you need to use an App Password. Go to Google Account > Security > 2-Step Verification > App Passwords."}
            return {"success": False, "error": "Authentication failed. Check your email and password."}
        return {"success": False, "error": f"Connection failed: {error_msg}"}
    except Exception as e:
        return {"success": False, "error": f"Connection error: {str(e)}"}

    config = load_email_config()
    existing = next((a for a in config["accounts"] if a["email"] == email), None)
    if existing:
        existing["password"] = base64.b64encode(password.encode()).decode()
        existing["provider"] = provider
    else:
        config["accounts"].append({
            "email": email,
            "password": base64.b64encode(password.encode()).decode(),
            "provider": provider,
            "added_at": datetime.now().isoformat()
        })

    save_email_config(config)
    return {"success": True, "message": "Account added successfully"}

def remove_email_account(email: str) -> bool:
    config = load_email_config()
    config["accounts"] = [a for a in config["accounts"] if a["email"] != email]
    return save_email_config(config)

def get_email_accounts() -> List[Dict]:
    config = load_email_config()
    return [{"email": a["email"], "provider": a["provider"]} for a in config["accounts"]]

def decode_email_header(header: str) -> str:
    if not header:
        return ""
    decoded_parts = []
    for part, charset in decode_header(header):
        if isinstance(part, bytes):
            try:
                decoded_parts.append(part.decode(charset or 'utf-8', errors='replace'))
            except:
                decoded_parts.append(part.decode('utf-8', errors='replace'))
        else:
            decoded_parts.append(part)
    return ' '.join(decoded_parts)

def extract_email_address(from_header: str) -> str:
    match = re.search(r'<([^>]+)>', from_header)
    if match:
        return match.group(1)
    return from_header.strip()

def extract_sender_name(from_header: str) -> str:
    match = re.match(r'^([^<]+)<', from_header)
    if match:
        return match.group(1).strip().strip('"')
    return from_header.split('@')[0]

def get_email_body(msg) -> str:
    body = ""
    if msg.is_multipart():
        for part in msg.walk():
            content_type = part.get_content_type()
            content_disposition = str(part.get("Content-Disposition", ""))
            if content_type == "text/plain" and "attachment" not in content_disposition:
                try:
                    payload = part.get_payload(decode=True)
                    charset = part.get_content_charset() or 'utf-8'
                    body = payload.decode(charset, errors='replace')
                    break
                except:
                    pass
            elif content_type == "text/html" and "attachment" not in content_disposition and not body:
                try:
                    payload = part.get_payload(decode=True)
                    charset = part.get_content_charset() or 'utf-8'
                    html = payload.decode(charset, errors='replace')
                    body = re.sub(r'<[^>]+>', '', html)
                    body = re.sub(r'\s+', ' ', body).strip()
                except:
                    pass
    else:
        try:
            payload = msg.get_payload(decode=True)
            charset = msg.get_content_charset() or 'utf-8'
            body = payload.decode(charset, errors='replace')
        except:
            body = str(msg.get_payload())

    return body[:5000]

def fetch_emails(email: str, folder: str = "INBOX", limit: int = 20) -> Dict:
    config = load_email_config()
    account = next((a for a in config["accounts"] if a["email"] == email), None)
    if not account:
        return {"success": False, "error": "Account not found"}

    provider = account["provider"]
    settings = PROVIDER_SETTINGS.get(provider)
    if not settings:
        return {"success": False, "error": "Unknown provider"}

    try:
        password = base64.b64decode(account["password"]).decode()
        imap = imaplib.IMAP4_SSL(settings["imap_host"], settings["imap_port"])
        imap.login(email, password)

        status, _ = imap.select(folder, readonly=True)
        if status != "OK":
            imap.logout()
            return {"success": False, "error": f"Could not select folder {folder}"}

        status, messages = imap.search(None, "ALL")
        if status != "OK":
            imap.logout()
            return {"success": False, "error": "Could not search messages"}

        message_ids = messages[0].split()
        message_ids = message_ids[-limit:] if len(message_ids) > limit else message_ids
        message_ids.reverse()

        emails = []
        for msg_id in message_ids:
            status, msg_data = imap.fetch(msg_id, "(RFC822 FLAGS)")
            if status != "OK":
                continue

            import email
            raw_email = msg_data[0][1]
            msg = email.message_from_bytes(raw_email)

            flags = msg_data[0][0].decode() if isinstance(msg_data[0][0], bytes) else str(msg_data[0][0])
            is_read = "\\Seen" in flags

            date_str = msg.get("Date", "")
            try:
                date_obj = parsedate_to_datetime(date_str)
                date_formatted = date_obj.strftime("%Y-%m-%d %H:%M")
            except:
                date_formatted = date_str[:20]

            from_header = decode_email_header(msg.get("From", ""))
            subject = decode_email_header(msg.get("Subject", "(No Subject)"))
            body_preview = get_email_body(msg)[:200]

            emails.append({
                "id": msg_id.decode(),
                "from": extract_email_address(from_header),
                "from_name": extract_sender_name(from_header),
                "subject": subject,
                "date": date_formatted,
                "preview": body_preview,
                "read": is_read
            })

        imap.logout()
        return {"success": True, "emails": emails}

    except imaplib.IMAP4.error as e:
        return {"success": False, "error": f"IMAP error: {str(e)}"}
    except Exception as e:
        return {"success": False, "error": f"Error: {str(e)}"}

def get_email_detail(email_addr: str, msg_id: str, folder: str = "INBOX") -> Dict:
    config = load_email_config()
    account = next((a for a in config["accounts"] if a["email"] == email_addr), None)
    if not account:
        return {"success": False, "error": "Account not found"}

    provider = account["provider"]
    settings = PROVIDER_SETTINGS.get(provider)
    if not settings:
        return {"success": False, "error": "Unknown provider"}

    try:
        password = base64.b64decode(account["password"]).decode()
        imap = imaplib.IMAP4_SSL(settings["imap_host"], settings["imap_port"])
        imap.login(email_addr, password)
        imap.select(folder)

        status, msg_data = imap.fetch(msg_id.encode(), "(RFC822)")
        if status != "OK":
            imap.logout()
            return {"success": False, "error": "Could not fetch email"}

        imap.store(msg_id.encode(), '+FLAGS', '\\Seen')

        import email
        raw_email = msg_data[0][1]
        msg = email.message_from_bytes(raw_email)

        date_str = msg.get("Date", "")
        try:
            date_obj = parsedate_to_datetime(date_str)
            date_formatted = date_obj.strftime("%Y-%m-%d %H:%M")
        except:
            date_formatted = date_str

        from_header = decode_email_header(msg.get("From", ""))
        to_header = decode_email_header(msg.get("To", ""))
        subject = decode_email_header(msg.get("Subject", "(No Subject)"))
        body = get_email_body(msg)

        imap.logout()

        return {
            "success": True,
            "email": {
                "id": msg_id,
                "from": extract_email_address(from_header),
                "from_name": extract_sender_name(from_header),
                "to": to_header,
                "subject": subject,
                "date": date_formatted,
                "body": body
            }
        }

    except Exception as e:
        return {"success": False, "error": f"Error: {str(e)}"}

def send_email(from_email: str, to_email: str, subject: str, body: str, reply_to_id: Optional[str] = None) -> Dict:
    config = load_email_config()
    account = next((a for a in config["accounts"] if a["email"] == from_email), None)
    if not account:
        return {"success": False, "error": "Account not found"}

    provider = account["provider"]
    settings = PROVIDER_SETTINGS.get(provider)
    if not settings:
        return {"success": False, "error": "Unknown provider"}

    try:
        password = base64.b64decode(account["password"]).decode()

        msg = MIMEMultipart()
        msg['From'] = from_email
        msg['To'] = to_email
        msg['Subject'] = subject
        msg['Date'] = formatdate(localtime=True)
        msg.attach(MIMEText(body, 'plain', 'utf-8'))

        server = smtplib.SMTP(settings["smtp_host"], settings["smtp_port"])
        server.starttls()
        server.login(from_email, password)
        server.sendmail(from_email, to_email.split(','), msg.as_string())
        server.quit()

        return {"success": True, "message": "Email sent successfully"}

    except smtplib.SMTPAuthenticationError:
        if provider == "gmail":
            return {"success": False, "error": "Authentication failed. For Gmail, use an App Password."}
        return {"success": False, "error": "Authentication failed. Check your credentials."}
    except Exception as e:
        return {"success": False, "error": f"Failed to send: {str(e)}"}

def delete_email(email: str, msg_id: str, folder: str = "INBOX") -> Dict:
                                                
    config = load_email_config()
    account = next((a for a in config["accounts"] if a["email"] == email), None)
    if not account:
        return {"success": False, "error": "Account not found"}

    provider = account["provider"]
    settings = PROVIDER_SETTINGS.get(provider)
    if not settings:
        return {"success": False, "error": "Unknown provider"}

    try:
        password = base64.b64decode(account["password"]).decode()
        imap = imaplib.IMAP4_SSL(settings["imap_host"], settings["imap_port"])
        imap.login(email, password)
        imap.select(folder)

        trash_folders = ['[Gmail]/Trash', 'Trash', 'Deleted', 'Deleted Items']

        moved = False
        for trash in trash_folders:
            try:
                status, _ = imap.copy(msg_id.encode(), trash)
                if status == "OK":
                    moved = True
                    break
            except:
                continue

        imap.store(msg_id.encode(), '+FLAGS', '\\Deleted')
        imap.expunge()

        imap.logout()

        return {"success": True, "message": "Email deleted successfully"}

    except Exception as e:
        return {"success": False, "error": f"Error: {str(e)}"}

def get_folders(email: str) -> Dict:
    config = load_email_config()
    account = next((a for a in config["accounts"] if a["email"] == email), None)
    if not account:
        return {"success": False, "error": "Account not found"}

    provider = account["provider"]
    settings = PROVIDER_SETTINGS.get(provider)
    if not settings:
        return {"success": False, "error": "Unknown provider"}

    try:
        password = base64.b64decode(account["password"]).decode()
        imap = imaplib.IMAP4_SSL(settings["imap_host"], settings["imap_port"])
        imap.login(email, password)

        status, folders = imap.list()
        imap.logout()

        if status != "OK":
            return {"success": False, "error": "Could not list folders"}

        folder_list = []
        for folder in folders:
            folder_str = folder.decode() if isinstance(folder, bytes) else str(folder)
            match = re.search(r'"([^"]+)"$|(\S+)$', folder_str)
            if match:
                folder_name = match.group(1) or match.group(2)
                folder_list.append(folder_name)

        return {"success": True, "folders": folder_list}

    except Exception as e:
        return {"success": False, "error": f"Error: {str(e)}"}
