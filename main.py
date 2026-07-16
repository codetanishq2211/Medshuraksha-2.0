import base64
import json
import mimetypes
import os
import re
import shutil
from pathlib import Path
from urllib.parse import urlparse, urlunparse

import streamlit as st

try:
    from PIL import Image
except ImportError:
    Image = None

try:
    import pytesseract
except ImportError:
    pytesseract = None
else:
    # Allow overriding the tesseract executable via environment variable
    tcmd = os.getenv("TESSERACT_CMD")
    if tcmd:
        try:
            pytesseract.pytesseract.tesseract_cmd = tcmd
        except Exception:
            pass
    else:
        # if tesseract is on PATH, pytesseract will use it; record detection
        if shutil.which("tesseract"):
            try:
                pytesseract.pytesseract.tesseract_cmd = "tesseract"
            except Exception:
                pass

try:
    import easyocr
except ImportError:
    easyocr = None

try:
    import cv2
except ImportError:
    cv2 = None

try:
    import requests
except ImportError:
    requests = None

try:
    import psycopg2
except ImportError:
    psycopg2 = None

DATA_PATH = Path(__file__).parent / "medicines.json"
REMOTE_DATA_URL = os.getenv("MEDICINES_DATA_URL", "").strip()
PG_HOST = os.getenv("PG_HOST", "").strip()
PG_PORT = os.getenv("PG_PORT", "5432").strip()
PG_USER = os.getenv("PG_USER", "").strip()
PG_PASSWORD = os.getenv("PG_PASSWORD", "").strip()
PG_DB = os.getenv("PG_DB", "").strip()
PG_TABLE = os.getenv("PG_TABLE", "public.medicines").strip()


@st.cache_data(show_spinner=False)
def load_medicine_database():
    if PG_HOST and PG_USER and PG_DB and psycopg2 is not None:
        try:
            from psycopg2 import sql

            table_name = PG_TABLE or "public.medicines"
            if "." in table_name:
                schema_name, simple_table_name = table_name.split(".", 1)
            else:
                schema_name = "public"
                simple_table_name = table_name

            connection = psycopg2.connect(
                host=PG_HOST,
                port=PG_PORT,
                user=PG_USER,
                password=PG_PASSWORD,
                dbname=PG_DB,
            )
            with connection:
                with connection.cursor() as cursor:
                    cursor.execute(
                        sql.SQL("SELECT name, manufacturer, approved, side_effects, avoid_in, additional_info FROM {}.{}")
                        .format(sql.Identifier(schema_name), sql.Identifier(simple_table_name))
                    )
                    rows = cursor.fetchall()
            if rows:
                return [
                    {
                        "name": row[0] or "",
                        "manufacturer": row[1] or "",
                        "approved": bool(row[2]) if row[2] is not None else True,
                        "side_effects": row[3] or "",
                        "avoid_in": row[4] or "",
                        "additional_info": row[5] or "",
                    }
                    for row in rows
                ]
        except Exception:
            pass

    if REMOTE_DATA_URL:
        try:
            response = requests.get(REMOTE_DATA_URL, timeout=20)
            response.raise_for_status()
            payload = response.json()
            if isinstance(payload, list):
                return payload
            if isinstance(payload, dict) and isinstance(payload.get("medicines"), list):
                return payload["medicines"]
        except Exception:
            pass

    if DATA_PATH.exists():
        with open(DATA_PATH, "r", encoding="utf-8") as handle:
            return json.load(handle)

    return []


@st.cache_data(show_spinner=False)
def get_medicine_search_index():
    medicines = load_medicine_database()
    if not medicines:
        return {"medicines": [], "name_lookup": {}, "token_index": {}}

    name_lookup = {}
    token_index = {}

    for medicine in medicines:
        med_name = normalize(str(medicine.get("name", "")))
        manufacturer = normalize(str(medicine.get("manufacturer", "")))
        if med_name:
            name_lookup.setdefault(med_name, []).append(medicine)

        for token in {segment for segment in med_name.split() if segment}:
            token_index.setdefault(token, []).append(medicine)

        for token in {segment for segment in manufacturer.split() if segment}:
            token_index.setdefault(token, []).append(medicine)

    return {"medicines": medicines, "name_lookup": name_lookup, "token_index": token_index}


def check_government_approval(medicine_name: str, medicines_or_index) -> dict:
    """Check if medicine is government-approved from the local medicines dataset."""
    if isinstance(medicines_or_index, dict):
        medicines = medicines_or_index.get("medicines", [])
    else:
        medicines = medicines_or_index

    if not medicines:
        return {"approved": False, "source": "unknown"}

    normalized_query = normalize(medicine_name)
    for med in medicines:
        med_name = med.get("name", "")
        if normalize(str(med_name)) == normalized_query:
            return {
                "approved": True,
                "source": "local",
                "details": med,
            }

    return {"approved": False, "source": "local"}


def normalize(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", text.lower()).strip()


def find_medicines(query: str, medicines_or_index) -> list[dict]:
    normalized = normalize(query)
    if not normalized:
        return []

    if isinstance(medicines_or_index, dict):
        medicines = medicines_or_index.get("medicines", [])
        name_lookup = medicines_or_index.get("name_lookup", {})
        token_index = medicines_or_index.get("token_index", {})
    else:
        medicines = medicines_or_index or []
        name_lookup = {}
        token_index = {}

    if not medicines:
        return []

    exact_matches = name_lookup.get(normalized, [])
    if exact_matches:
        return exact_matches

    matches = []
    seen_ids = set()

    for token in [segment for segment in normalized.split() if segment]:
        for medicine in token_index.get(token, []):
            medicine_id = id(medicine)
            if medicine_id in seen_ids:
                continue
            seen_ids.add(medicine_id)
            name = normalize(str(medicine.get("name", "")))
            manufacturer = normalize(str(medicine.get("manufacturer", "")))
            if normalized in name or normalized in manufacturer:
                matches.append(medicine)

    if matches:
        return matches

    for medicine in medicines:
        name = normalize(str(medicine.get("name", "")))
        manufacturer = normalize(str(medicine.get("manufacturer", "")))
        if normalized in name or normalized in manufacturer:
            matches.append(medicine)

    return matches


def _stringify(value) -> str:
    if value is None:
        return ""
    if isinstance(value, float) and value != value:
        return ""
    return str(value).strip()


def get_ocr_search_query(extracted_json: dict, parsed_medicine: dict) -> tuple[str, list[str]]:
    candidates = []
    extracted_name = parsed_medicine.get("name", "").strip()
    if extracted_name:
        candidates.append(extracted_name)

    for line in extracted_json.get("lines", [])[:6]:
        cleaned_line = line.strip()
        if cleaned_line and cleaned_line not in candidates:
            candidates.append(cleaned_line)

    raw_text = extracted_json.get("raw_text", "").strip()
    if raw_text and raw_text not in candidates:
        candidates.append(raw_text)

    return (candidates[0], candidates) if candidates else ("", [])


def llm_whisperer_ocr(image_file) -> dict:
    """Extract text from image using EasyOCR."""
    if easyocr is None:
        return {
            "raw_text": "EasyOCR is not installed. Install it to use OCR.",
            "lines": [],
        }

    try:
        image_file.seek(0)
        # Read image file into memory
        import numpy as np

        # Read image data
        image_data = image_file.read()
        image_file.seek(0)

        if cv2 is None:
            return {
                "raw_text": "OpenCV is not installed. Install opencv-python-headless to use OCR.",
                "lines": [],
            }

        # Convert to numpy array
        nparr = np.frombuffer(image_data, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            return {
                "raw_text": "Could not decode image. Please upload a valid image file.",
                "lines": [],
            }
        
        # Initialize EasyOCR reader (cached for performance)
        reader = easyocr.Reader(['en'], gpu=False)
        
        # Extract text
        results = reader.readtext(img)
        
        # Process results
        text_lines = []
        for detection in results:
            text = detection[1]  # Extract text from detection
            confidence = detection[2]
            if confidence > 0.3:  # Filter low confidence detections
                text_lines.append(text)
        
        full_text = "\n".join(text_lines)
        
        return {
            "raw_text": full_text.strip(),
            "lines": text_lines,
        }
    except Exception as error:
        return {
            "raw_text": f"EasyOCR error: {error}",
            "lines": [],
        }


def llm_ocr_from_image(image_file) -> dict:
    if requests is None:
        return {
            "raw_text": "Requests is not installed. Install requests to use LLM OCR.",
            "lines": [],
        }

    api_url = os.getenv("OLLAMA_API_URL", "http://127.0.0.1:11434/v1/chat/completions")
    model = resolve_ollama_model(api_url)

    if not model:
        return {
            "raw_text": (
                "LLM OCR failed: no Ollama model is selected. "
                "Choose an installed model in the sidebar or install one with `ollama models`."
            ),
            "lines": [],
        }

    image_file.seek(0)
    data = image_file.read()
    image_file.seek(0)
    mime_type = "image/jpeg"
    if Image is not None:
        try:
            image = Image.open(image_file)
            mime_type = Image.MIME.get(image.format, mime_type) if image.format else mime_type
            image_file.seek(0)
        except Exception:
            pass

    encoded = base64.b64encode(data).decode("utf-8")
    prompt = (
        "You are an OCR assistant. Extract all visible text from the image encoded as base64 below. "
        "Return only the extracted text, with one line per text block. Do not add extra commentary.\n\n"
        f"MIME-TYPE: {mime_type}\n"
        f"BASE64-IMAGE: {encoded}"
    )

    try:
        payload = {
            "model": model,
            "messages": [
                {
                    "role": "user",
                    "content": prompt,
                }
            ],
        }
        response = requests.post(api_url, json=payload, timeout=300)
        if response.ok:
            data = response.json()
            content = None
            if isinstance(data, dict):
                content = data.get("choices", [{}])[0].get("message", {}).get("content")
            if not content:
                content = data.get("text") if isinstance(data, dict) else None
            text = content or ""
            lines = [line.strip() for line in text.splitlines() if line.strip()]
            return {"raw_text": text.strip(), "lines": lines}
        if response.status_code == 404 and "model" in response.text.lower():
            known = get_ollama_models(api_url)
            if known and known[0] != model:
                model = known[0]
                payload["model"] = model
                retry = requests.post(api_url, json=payload, timeout=120)
                if retry.ok:
                    data = retry.json()
                    content = None
                    if isinstance(data, dict):
                        content = data.get("choices", [{}])[0].get("message", {}).get("content")
                    if not content:
                        content = data.get("text") if isinstance(data, dict) else None
                    text = content or ""
                    lines = [line.strip() for line in text.splitlines() if line.strip()]
                    return {"raw_text": text.strip(), "lines": lines}
            known_text = (
                f" Available models: {', '.join(known)}." if known else " Use `ollama models` in terminal to inspect installed models."
            )
            return {
                "raw_text": (
                    f"LLM OCR failed: model '{model}' not found at Ollama. "
                    f"Set the correct model in the sidebar or install the model in Ollama.{known_text}"
                ),
                "lines": [],
            }
        return {
            "raw_text": f"LLM OCR returned status {response.status_code}: {response.text}",
            "lines": [],
        }
    except Exception as error:
        return {
            "raw_text": f"LLM OCR request failed (timeout). Image processing can take 2-5 minutes with large models. Please wait and try again, or switch to a faster model (e.g., 'mistral') in the sidebar. Error: {error}",
            "lines": [],
        }


def extract_text_from_image(image_file, use_llm_ocr: bool = False) -> dict:
    if Image is None:
        # Try LLM Whisperer API first
        result = llm_whisperer_ocr(image_file)
        if result.get("raw_text") and "not set" not in result["raw_text"]:
            return result
        if use_llm_ocr:
            return llm_ocr_from_image(image_file)
        return {
            "raw_text": "Pillow is not installed. Install pillow to use image OCR.",
            "lines": [],
        }

    # If pytesseract is not available, try LLM Whisperer then fall back to Ollama
    if pytesseract is None:
        result = llm_whisperer_ocr(image_file)
        if result.get("raw_text") and "not set" not in result["raw_text"]:
            return result
        return llm_ocr_from_image(image_file)

    try:
        image = Image.open(image_file)
        image = image.convert("RGB")
        text = pytesseract.image_to_string(image, lang="eng")
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        if lines:
            return {"raw_text": text.strip(), "lines": lines}
        # If Tesseract extracts no text, try LLM Whisperer
        result = llm_whisperer_ocr(image_file)
        if result.get("raw_text") and "not set" not in result["raw_text"]:
            return result
        # Fall back to Ollama LLM OCR
        return llm_ocr_from_image(image_file)
    except Exception as error:
        # On any Tesseract error, try LLM Whisperer first
        result = llm_whisperer_ocr(image_file)
        if result.get("raw_text") and "not set" not in result["raw_text"]:
            return result
        # Fall back to Ollama LLM OCR
        return llm_ocr_from_image(image_file)


def extract_json_from_text(raw_text: str) -> dict:
    """Parse extracted text into a structured medicine JSON object."""
    parsed = {
        "name": "",
        "manufacturer": "",
        "expiry_date": "",
        "side_effects": "",
        "avoid_if": "",
        "usage": "",
        "raw_text": raw_text,
    }

    if not raw_text or not raw_text.strip():
        return parsed

    lines = [line.strip() for line in raw_text.splitlines() if line.strip()]
    label_map = {
        "name": ["name", "medicine", "drug"],
        "manufacturer": ["manufacturer", "maker", "company"],
        "expiry_date": ["expiry", "expiration", "exp"],
        "side_effects": ["side effect", "side-effects", "adverse"],
        "avoid_if": ["avoid", "do not", "contraindication"],
        "usage": ["use", "take", "directions", "dose"],
    }

    for line in lines:
        if ":" in line:
            left, right = line.split(":", 1)
            left = left.lower()
            right = right.strip()
            for key, keywords in label_map.items():
                if any(keyword in left for keyword in keywords):
                    parsed[key] = right
                    break

    if not parsed["name"] and lines:
        parsed["name"] = lines[0]

    # If structured parse is too sparse, use LLM parsing if available
    if requests is not None and (not parsed["manufacturer"] or not parsed["side_effects"]):
        try:
            llm_json = get_ollama_medicine_json(raw_text)
            if isinstance(llm_json, dict) and llm_json.get("name"):
                parsed.update({k: v for k, v in llm_json.items() if k in parsed and v})
        except Exception:
            pass

    return parsed


def get_ollama_medicine_json(raw_text: str) -> dict:
    api_url = os.getenv("OLLAMA_API_URL", "http://127.0.0.1:11434/v1/chat/completions")
    model = resolve_ollama_model(api_url)
    if requests is None:
        return {}
    if not model:
        return {
            "error": "No Ollama model selected. Pick an installed model in the sidebar or install one with `ollama models`."
        }

    prompt = (
        "Extract the medicine information from the text below and return a JSON object with keys: "
        "name, manufacturer, expiry_date, side_effects, avoid_if, usage, raw_text. "
        "If a value is missing, return an empty string for that key. Return ONLY valid JSON.\n\n"
        f"TEXT:\n{raw_text}"
    )

    payload = {
        "model": model,
        "messages": [
            {
                "role": "user",
                "content": prompt,
            }
        ],
    }

    response = requests.post(api_url, json=payload, timeout=120)
    if not response.ok:
        if response.status_code == 404 and "model" in response.text.lower():
            known = get_ollama_models(api_url)
            known_text = (
                f" Available models: {', '.join(known)}." if known else " Use `ollama models` in terminal to inspect installed models."
            )
            return {
                "error": f"Model '{model}' not found. Set a valid model name in the sidebar.{known_text}"
            }
        return {}

    data = response.json()
    content = data.get("choices", [{}])[0].get("message", {}).get("content") if isinstance(data, dict) else None
    if not content:
        content = data.get("text") if isinstance(data, dict) else None
    if not content:
        return {}

    content = content.strip()
    try:
        return json.loads(content)
    except Exception:
        # fallback: extract first JSON-looking substring
        match = re.search(r"\{.*\}", content, re.S)
        if match:
            try:
                return json.loads(match.group(0))
            except Exception:
                pass
    return {}


def get_ollama_answer(query: str) -> str:
    api_url = os.getenv("OLLAMA_API_URL", "http://127.0.0.1:11434/v1/chat/completions")
    model = resolve_ollama_model(api_url)
    if requests is None:
        return "Requests is not installed. Install requests to use Ollama integration."
    if not model:
        return "No Ollama model selected. Pick an installed model in the sidebar or install one with `ollama models`."

    payload = {
        "model": model,
        "messages": [
            {
                "role": "user",
                "content": (
                    "A user provided a medicine name or description. "
                    "Respond with whether the medicine is government approved, "
                    "and provide the medicine name, manufacturer, expiry guidance, "
                    "side effects, and any warnings in English.\n\n"
                    f"Medicine input: {query}"
                ),
            }
        ],
    }

    try:
        response = requests.post(api_url, json=payload, timeout=120)
        if response.ok:
            data = response.json()
            # Ollama-compatible response shapes vary; try common accessors
            content = None
            if isinstance(data, dict):
                # typical Ollama v1 chat completion style
                content = data.get("choices", [{}])[0].get("message", {}).get("content")
            if not content:
                # fallback: try top-level text
                content = data.get("text") if isinstance(data, dict) else None
            return content or json.dumps(data, indent=2, ensure_ascii=False)
        if response.status_code == 404 and "model" in response.text.lower():
            known = get_ollama_models(api_url)
            known_text = (
                f" Available models: {', '.join(known)}." if known else " Use `ollama models` in terminal to inspect installed models."
            )
            return (
                f"Ollama model '{model}' not found. "
                f"Update the model name in the sidebar or install that model in Ollama.{known_text}"
            )
        return f"Ollama API returned status {response.status_code}: {response.text}"
    except requests.exceptions.ConnectionError:
        return "Ollama server unreachable at {0}. Start the Ollama service or set OLLAMA_API_URL.".format(api_url)
    except Exception as error:
        return f"Ollama request failed: {error}"


def check_ollama_available(api_url: str | None = None, timeout: int = 4) -> bool:
    """Quickly check whether the Ollama HTTP API is reachable."""
    if requests is None:
        return False
    if api_url is None:
        api_url = os.getenv("OLLAMA_API_URL", "http://127.0.0.1:11434/v1/chat/completions")
    try:
        r = requests.head(api_url, timeout=timeout)
        return r.ok or r.status_code == 405
    except Exception:
        return False


def get_ollama_models(api_url: str | None = None, timeout: int = 4) -> list[str]:
    if requests is None:
        return []
    if api_url is None:
        api_url = os.getenv("OLLAMA_API_URL", "http://127.0.0.1:11434/v1/chat/completions")

    parsed = urlparse(api_url)
    path = parsed.path
    if path.endswith("/chat/completions"):
        path = path[: -len("/chat/completions")] + "/models"
    elif path.endswith("/completions"):
        path = path[: -len("/completions")] + "/models"
    else:
        path = "/v1/models"

    url = urlunparse(parsed._replace(path=path, query="", fragment=""))

    try:
        response = requests.get(url, timeout=timeout)
        if not response.ok:
            return []
        data = response.json()
        names = []
        if isinstance(data, dict):
            items = data.get("models", None)
            if items is None:
                items = data.get("data", None)
            if items is None and data.get("object") == "list":
                items = data.get("data") or []
        else:
            items = data
        if isinstance(items, dict):
            items = [items]
        if isinstance(items, list):
            for item in items:
                if isinstance(item, dict):
                    name = item.get("name") or item.get("id")
                    if name:
                        names.append(name)
                elif isinstance(item, str):
                    names.append(item)
        return names
    except Exception:
        return []


def resolve_ollama_model(api_url: str | None = None) -> str:
    env_model = os.getenv("OLLAMA_MODEL")
    if env_model:
        return env_model
    available = get_ollama_models(api_url)
    return available[0] if available else ""


def show_medicine_card(medicine: dict):
    st.subheader(medicine.get("name", "Unknown medicine"))
    st.markdown(f"**Manufacturer:** {medicine.get('manufacturer', 'Unknown')}")
    st.markdown(f"**Approved:** {'Yes' if medicine.get('approved', False) else 'No'}")
    st.markdown(f"**Expiry guidance:** {medicine.get('expiry_guidance', 'Check the printed expiry date.')}")
    st.markdown(f"**Side effects:** {medicine.get('side_effects', 'No side-effects data available.')}")
    st.markdown(f"**Avoid if:** {medicine.get('avoid_in', 'Ask a doctor before use.')}")
    if additional := medicine.get("additional_info"):
        st.markdown(f"**Additional info:** {additional}")


def main():
    st.set_page_config(page_title="MedShuraksha", layout="wide", page_icon="💊")
    st.title("MedShuraksha")
    st.markdown(
        """
        ## Government-approved medicine lookup
        Enter a medicine name or upload a medicine photo to check whether the medicine is government-approved.

        This app searches a local approved dataset first, then a Kaggle medicine database, and falls back to Ollama AI if needed.
        """
    )

    with st.sidebar:
        st.header("Search options")
        search_mode = st.radio("Search by", ["Medicine name", "Medicine image"])

        with st.expander("Ollama (AI) settings", expanded=False):
            default_ollama = os.getenv("OLLAMA_API_URL", "http://127.0.0.1:11434/v1/chat/completions")
            ollama_input = st.text_input("Ollama API URL", value=default_ollama)
            use_ollama = st.checkbox("Enable Ollama fallback", value=True)
            use_llm_ocr = st.checkbox("Enable LLM Whisperer OCR", value=True)
            use_json_parse = st.checkbox("Parse OCR text into structured JSON", value=True)
            default_model = os.getenv("OLLAMA_MODEL", "")

            available_models = []
            model_list_error = None
            if ollama_input:
                available_models = get_ollama_models(ollama_input)
                if not available_models:
                    if check_ollama_available(ollama_input):
                        model_list_error = (
                            "Ollama is reachable, but no models were returned. "
                            "Install a model in Ollama or use `ollama models` to review available models."
                        )
                    else:
                        model_list_error = (
                            "Ollama is unreachable at the provided URL. "
                            "Verify the URL and start Ollama, then try again."
                        )

            if available_models:
                if default_model not in available_models:
                    default_model = available_models[0]
                ollama_model = st.selectbox(
                    "Ollama model name",
                    options=available_models,
                    index=available_models.index(default_model),
                )
            else:
                ollama_model = st.text_input("Ollama model name", value=default_model)

            if st.button("Test Ollama"):
                ok = check_ollama_available(ollama_input)
                if ok:
                    st.success("Ollama reachable at provided URL")
                else:
                    st.error("Ollama not reachable at provided URL")

            if check_ollama_available(ollama_input):
                available_models = get_ollama_models(ollama_input)
            if available_models:
                st.markdown("**Available Ollama models:** " + ", ".join(available_models))
            elif model_list_error:
                st.info(f"{model_list_error} Use `ollama models` in a terminal or install a supported model.")
            else:
                st.info(
                    "Could not fetch model list automatically. Use `ollama models` in a terminal or install a supported model."
                )

        st.markdown("---")
        st.caption("The local medicine dataset is loaded only when a search runs, so the app opens faster.")
        st.markdown(
            "💊 App checks medicines against the local medicines dataset first, then Ollama AI if needed."
        )

    # Expose selected URL and model to the runtime env so the LLM calls pick them up.
    if ollama_input:
        os.environ["OLLAMA_API_URL"] = ollama_input
    else:
        os.environ.pop("OLLAMA_API_URL", None)

    if ollama_model:
        os.environ["OLLAMA_MODEL"] = ollama_model
    else:
        os.environ.pop("OLLAMA_MODEL", None)

    if "last_search_mode" not in st.session_state or st.session_state.last_search_mode != search_mode:
        st.session_state.last_image_search_key = ""
        st.session_state.last_search_mode = search_mode

    query = ""
    extracted_json = None
    parsed_medicine = None
    fallback_answer = None
    ocr_detected_name = ""
    search_triggered = False

    with st.container():
        st.subheader("Search medicines")
        left_col, right_col = st.columns([3, 1])

        with left_col:
            if search_mode == "Medicine name":
                query = st.text_input("Enter medicine name or manufacturer")
            else:
                uploaded_image = st.file_uploader("Upload medicine photo", type=["png", "jpg", "jpeg"])
                if uploaded_image is not None:
                    extracted_json = extract_text_from_image(uploaded_image, use_llm_ocr=use_llm_ocr)
                    if use_json_parse:
                        parsed_medicine = extract_json_from_text(extracted_json.get("raw_text", ""))
                    else:
                        parsed_medicine = {"raw_text": extracted_json.get("raw_text", "")}

                    ocr_detected_name, ocr_candidates = get_ocr_search_query(extracted_json, parsed_medicine)
                    if ocr_detected_name:
                        query = ocr_detected_name
                        st.info(f"OCR detected medicine name: {ocr_detected_name}")
                    else:
                        query = extracted_json.get("raw_text", "")

                    current_image_key = f"{uploaded_image.name}-{uploaded_image.size}"
                    if query and st.session_state.last_image_search_key != current_image_key:
                        search_triggered = True
                        st.session_state.last_image_search_key = current_image_key

                    if not ocr_detected_name and ocr_candidates:
                        st.info("OCR candidates for search:")
                        for candidate in ocr_candidates[:3]:
                            st.write(f"- {candidate}")

            if st.button("Check medicine"):
                if not query:
                    st.warning("Please enter a medicine name or upload a photo first.")
                else:
                    search_triggered = True

            if search_triggered:
                with st.spinner("Loading local medicine lookup index..."):
                    medicine_search_index = get_medicine_search_index()

                local_matches = find_medicines(query, medicine_search_index)

                st.markdown("---")
                st.header("Search results")

                if local_matches:
                    with st.expander(f"Local dataset matches ({len(local_matches)})", expanded=True):
                        for medicine in local_matches:
                            show_medicine_card(medicine)

                if not local_matches:
                    approval_check = check_government_approval(query, medicine_search_index)
                    if approval_check["approved"]:
                        st.success(f"✅ **{query}** is GOVERNMENT APPROVED (verified from the local dataset)")
                        if approval_check.get("details"):
                            st.json(approval_check["details"])
                    else:
                        st.error("Medicine not found in the local approved dataset.")
                        if use_ollama:
                            if check_ollama_available(ollama_input):
                                st.info("🔍 Automatically searching Ollama AI for this medicine...")
                                ollama_query = ocr_detected_name or query
                                if ocr_detected_name and ocr_detected_name != query:
                                    st.info(f"Using detected name for Ollama lookup: {ollama_query}")
                                fallback_answer = get_ollama_answer(ollama_query)
                                st.success("✅ Found Ollama AI response:")
                                st.text_area("Ollama AI response", fallback_answer, height=280)
                            else:
                                st.error(f"❌ Ollama not reachable at {ollama_input}. Please start the Ollama service (run `ollama serve` in a terminal) or update the URL in the sidebar.")
                        else:
                            st.info("💡 Ollama fallback is disabled in the sidebar. Enable it to automatically search for medicines not in the local database using AI.")

        with right_col:
            st.markdown("### Search help")
            st.write("- Search by medicine name or manufacturer.")
            st.write("- For image search, upload clear photos of the packaging label.")
            st.write("- Use a complete medicine name for best results.")
            st.write("- You can enable Ollama fallback for AI-based lookup.")
            st.markdown("---")
            st.metric("Local medicines", len(get_medicine_search_index().get("medicines", [])))

    if extracted_json is not None:
        st.markdown("### OCR extracted data from image")
        json_col, raw_col = st.columns([1, 1])
        with raw_col:
            st.text_area("Extracted text", extracted_json.get("raw_text", ""), height=250)
        with json_col:
            st.markdown("Parsed JSON")
            st.json(parsed_medicine or {})


if __name__ == "__main__":
    main()
