#!/data/data/com.termux/files/usr/bin/bash

# --- PRE-FLIGHT CHECKS & UI ---
G='\033[0;32m'; B='\033[0;34m'; Y='\033[1;33m'; R='\033[0;31m'; P='\033[0;35m'; NC='\033[0m'
WORKSPACE="$HOME/ultimate_workspace"
LOG_FILE="$HOME/install.log"

header() {
    clear
    echo -e "${P}╔══════════════════════════════════════════╗${NC}"
    echo -e "${P}║   🧠 ULTIMATE TERMUX ENVIRONMENT 🧠      ║${NC}"
    echo -e "${P}╚══════════════════════════════════════════╝${NC}"
}

log() { echo -e "${G}[INFO]${NC} $1"; }
warn() { echo -e "${Y}[WARN]${NC} $1"; }
error() { echo -e "${R}[ERROR]${NC} $1"; }

# --- ARGUMENT PARSING ---
INSTALL_FULL=false; INSTALL_GEMINI=false; INSTALL_DEVLAB=false; INSTALL_CSB=false; INSTALL_MULTI=false

if [[ "$#" -eq 0 ]]; then
    echo "Usage: ./ultimate_bootstrap.sh [--full | --gemini | --devlab | --csb | --multi]"
    exit 1
fi

for arg in "$@"; do
    case $arg in
        --full) INSTALL_FULL=true; INSTALL_GEMINI=true; INSTALL_DEVLAB=true; INSTALL_CSB=true; INSTALL_MULTI=true ;;
        --gemini) INSTALL_GEMINI=true ;;
        --devlab) INSTALL_DEVLAB=true ;;
        --csb) INSTALL_CSB=true ;;
        --multi) INSTALL_MULTI=true ;;
    esac
done

header
log "Starting installation. Details logged to $LOG_FILE"

# --- 1. CORE SYSTEM SETUP ---
log "Updating system packages..."
pkg update -y && pkg upgrade -y
pkg install -y python python-pip nodejs-lts wget git proot clang make \
               openjdk-17 termux-api ffmpeg zip unzip build-essential \
               nano micro curl binutils ncurses-utils jq

mkdir -p "$WORKSPACE"/{gemini,devlab,csb,ai_models,logs}
mkdir -p "$HOME/bin"

# --- 2. GEMINI AI SUITE GENERATION ---
if [ "$INSTALL_GEMINI" = true ]; then
    log "Building Gemini AI Suite..."
    pip install google-genai Pillow python-dotenv
    
    cat << 'EOF' > "$WORKSPACE/gemini/gemini_ai.py"
import os, sys, argparse, subprocess, json
from google import genai
from google.genai import types
from PIL import Image
from dotenv import load_dotenv

load_dotenv(os.path.join(os.path.expanduser("~"), ".ultimate_ai_env"))

def get_client():
    key = os.getenv("GEMINI_API_KEY")
    if not key:
        print("\033[31m[!] Run 'gemini config' to set your API Key.\033[0m")
        sys.exit(1)
    return genai.Client(api_key=key)

def chat_mode():
    client = get_client()
    chat = client.chats.create(model='gemini-2.0-flash-001')
    print("\033[34m[Gemini Interactive Chat - Type 'exit' to quit]\033[0m")
    while True:
        user_input = input("\n\033[32mYou > \033[0m")
        if user_input.lower() in ['exit', 'quit']: break
        response = chat.send_message(user_input)
        print(f"\n\033[34mAI >\033[0m {response.text}")

def vision_mode(file_path=None):
    if not file_path:
        print("[*] Taking photo...")
        file_path = "cam_capture.jpg"
        subprocess.run(["termux-camera-photo", file_path])
    
    if os.path.exists(file_path):
        client = get_client()
        with open(file_path, "rb") as f:
            img_bytes = f.read()
        response = client.models.generate_content(
            model='gemini-2.0-flash-001',
            contents=[types.Part.from_bytes(data=img_bytes, mime_type="image/jpeg"), "Describe this image in detail."]
        )
        print(f"\n\033[35m[Vision Result]:\033[0m\n{response.text}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=['chat', 'vision', 'code', 'config'])
    parser.add_argument("extra", nargs='?', default=None)
    args = parser.parse_args()

    if args.command == 'chat': chat_mode()
    elif args.command == 'vision': vision_mode(args.extra)
    elif args.command == 'config':
        key = input("Enter Gemini API Key: ")
        with open(os.path.expanduser("~/.ultimate_ai_env"), "a") as f:
            f.write(f"\nGEMINI_API_KEY={key}")
EOF

    # Create the launcher
    cat << 'EOF' > "$HOME/bin/gemini"
#!/data/data/com.termux/files/usr/bin/bash
python ~/ultimate_workspace/gemini/gemini_ai.py "$@"
EOF
    chmod +x "$HOME/bin/gemini"
fi

# --- 3. DEVLAB OS SERVER ---
if [ "$INSTALL_DEVLAB" = true ]; then
    log "Setting up DevLab Server..."
    cd "$WORKSPACE/devlab"
    npm init -y > /dev/null
    npm install express dotenv cors socket.io > /dev/null

    cat << 'EOF' > "$WORKSPACE/devlab/server.js"
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
    res.send(`
        <html>
            <body style="font-family: sans-serif; background: #121212; color: white; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh;">
                <h1>DevLab OS Node Server</h1>
                <p>Termux is hosting this PWA-ready environment.</p>
                <button onclick="alert('Lab Active')">Test Connection</button>
            </body>
        </html>
    `);
});

app.listen(port, () => console.log(`DevLab running at http://localhost:${port}`));
EOF
    cat << 'EOF' > "$HOME/bin/devlab"
#!/data/data/com.termux/files/usr/bin/bash
node ~/ultimate_workspace/devlab/server.js
EOF
    chmod +x "$HOME/bin/devlab"
fi

# --- 4. CSB APK EDITOR ---
if [ "$INSTALL_CSB" = true ]; then
    log "Installing APK Tools (CSB)..."
    cd "$WORKSPACE/csb"
    wget https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool -O apktool
    wget https://github.com/iBotPeaches/Apktool/releases/download/v2.9.3/apktool_2.9.3.jar -O apktool.jar
    chmod +x apktool
    cp apktool* "$HOME/bin/"

    cat << 'EOF' > "$HOME/bin/csb"
#!/data/data/com.termux/files/usr/bin/bash
echo -e "\033[33m--- APK EDITOR MENU ---\033[0m"
echo "1) Decompile APK"
echo "2) Recompile & Sign"
read -p "Choose: " opt
if [ "$opt" == "1" ]; then
    read -p "Filename: " fname
    apktool d "$fname"
elif [ "$opt" == "2" ]; then
    read -p "Folder: " fdr
    apktool b "$fdr"
fi
EOF
    chmod +x "$HOME/bin/csb"
fi

# --- 5. MULTI-AI INTEGRATION ---
if [ "$INSTALL_MULTI" = true ]; then
    log "Configuring Multi-AI support..."
    pip install anthropic openai
    cat << 'EOF' > "$WORKSPACE/ai_models/multi_ai.py"
import sys, os
from dotenv import load_dotenv

def compare(prompt):
    print(f"Comparing AI responses for: {prompt}")
    # Integration logic for Gemini, Claude, and OpenAI would go here
    # Based on the API keys available in ~/.ultimate_ai_env
    print("[!] Placeholder for Multi-AI logic. Configure keys in .env first.")

if __name__ == "__main__":
    if len(sys.argv) > 1: compare(sys.argv[1])
EOF
fi

# --- 6. FINALIZING MENUS & PATHS ---
log "Creating the Master Launcher..."

cat << 'EOF' > "$HOME/bin/ultimate"
#!/data/data/com.termux/files/usr/bin/bash
clear
echo -e "\033[35m╔══════════════════════════════════════════╗\033[0m"
echo -e "\033[35m║   🧠 ULTIMATE TERMUX ENVIRONMENT 🧠      ║\033[0m"
echo -e "\033[35m╚══════════════════════════════════════════╝\033[0m"
echo ""
echo -e "1) \033[32mGemini AI Chat\033[0m"
echo -e "2) \033[34mDevLab OS Server\033[0m"
echo -e "3) \033[33mCSB APK Editor\033[0m"
echo -e "4) \033[36mSystem Info\033[0m"
echo -e "0) Exit"
echo ""
read -p "Selection: " choice

case $choice in
    1) gemini chat ;;
    2) devlab ;;
    3) csb ;;
    4) neofetch || uname -a ;;
    0) exit ;;
esac
EOF
chmod +x "$HOME/bin/ultimate"

# Update .bashrc
grep -q "export PATH=\$PATH:~/bin" ~/.bashrc || echo 'export PATH=$PATH:~/bin' >> ~/.bashrc
grep -q "alias ai=" ~/.bashrc || echo "alias ai='gemini chat'" >> ~/.bashrc

echo -e "\n${G}🎉 INSTALLATION COMPLETE!${NC}"
echo -e "1. Restart Termux or run: ${Y}source ~/.bashrc${NC}"
echo -e "2. Set your key: ${Y}gemini config${NC}"
echo -e "3. Open the main menu: ${Y}ultimate${NC}"
