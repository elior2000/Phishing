# Phishing Framework – XE107

A Bash-based framework for simulating phishing scenarios in cybersecurity labs.\
Quickly clone websites or deploy phishing templates (Facebook, Gmail), capture test credentials, and manage everything automatically.

---

## Features

- Clone any website with one command
- Built-in phishing templates: Facebook & Gmail
- Automatic credential capture (CSV log)
- User redirect to real site after login
- Supports SSL (Certbot) for custom domains
- Short URL generation (TinyURL)
- Full Apache setup and clean-up
- Minimal user input – fully automated

---

## Installation

```bash
git clone https://github.com/elior2000/Phishing.git
cd Phishing
chmod +x Phishing.sh
sudo ./Phishing.sh
```

---

## Usage

- **Clone a site:** Choose option 1 and enter the URL
- **Use template:** Choose option 2, then select Facebook or Gmail
- Choose whether to use a custom domain (SSL) or local IP (HTTP)
- Credentials are saved to `/var/www/html/credentials.csv`
- Stop the service with:\
  `sudo systemctl stop apache2`

---

## Example Output

```
[*] Phishing page is live at: http://192.168.1.10
[*] Short URL: http://tinyurl.com/xxxxx
[*] Credentials will be logged in /var/www/html/credentials.csv
```

---

## Disclaimer

For educational/lab use only.\
Do not use for unauthorized activity.

---

Project by [Elior Salimi](https://github.com/elior2000)

