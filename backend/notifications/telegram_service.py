import os
import requests
import logging

logger = logging.getLogger(__name__)

def send_telegram_message(chat_id, message_text):
    """
    Dispatches a message to a Telegram user/chat via Telegram Bot API.
    """
    bot_token = os.getenv('TELEGRAM_BOT_TOKEN')
    if not bot_token or bot_token == 'test_bot_token':
        logger.info(f"[SIMULATED TELEGRAM DISPATCH] To {chat_id}: {message_text}")
        return True, "Simulated Telegram dispatch successful."

    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
    payload = {
        'chat_id': chat_id,
        'text': message_text,
        'parse_mode': 'Markdown'
    }

    try:
        response = requests.post(url, json=payload, timeout=10)
        if response.status_code == 200:
            return True, "Message sent successfully."
        else:
            err = response.text
            logger.warning(f"Telegram API responded with error: {err}")
            return False, f"Telegram API error: {err}"
    except Exception as e:
        logger.error(f"Failed to connect to Telegram API: {e}")
        return False, f"Connection error: {str(e)}"
