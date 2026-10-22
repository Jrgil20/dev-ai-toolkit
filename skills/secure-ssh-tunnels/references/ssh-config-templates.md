# Declarative SSH Config Templates (`~/.ssh/config`)

Managing multiple tunnel arguments manually via CLI flags is error-prone. Use declarative host definitions in `~/.ssh/config` to automate port forwarding, enforce hardened crypto algorithms, and enable persistent multiplexing.

---

## 1. Remote AI Server Profile (e.g. NVIDIA DGX Spark)

Add this block to your local `~/.ssh/config` (`chmod 600 ~/.ssh/config`):

```ssh-config
# Host alias for AI compute node
Host dgx-spark
    HostName 192.168.6.35
    User ucab-spark1
    Port 22
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

    # Strict loopback port forwarding for AI inference endpoints
    LocalForward 127.0.0.1:8080 127.0.0.1:8080   # Primary LLM (e.g. Qwen 3 Coder 30B)
    LocalForward 127.0.0.1:8084 127.0.0.1:8084   # VLM Server (e.g. Gemma 3 4B Vision)
    LocalForward 127.0.0.1:7000 127.0.0.1:7000   # Flask / Gradio Testbench Web UI

    # Reverse port forwarding for peripheral ingestion
    RemoteForward 127.0.0.1:8082 127.0.0.1:8082  # Laptop Webcam / Sensor stream

    # Security & keepalive hardening
    ServerAliveInterval 30
    ServerAliveCountMax 3
    ExitOnForwardFailure yes
    TCPKeepAlive yes

    # ControlMaster socket multiplexing (shares single TCP connection)
    ControlMaster auto
    ControlPath ~/.ssh/control-%C
    ControlPersist 10m
```

### Usage with this profile:
- **Interactive session with automatic tunnels**:
  ```bash
  ssh dgx-spark
  ```
- **Tunnel-only daemon (no shell)**:
  ```bash
  ssh -N dgx-spark
  ```

---

## 2. Hardened Bastion / Jump Host Setup

When the AI cluster is isolated behind a VPN or bastion jump host:

```ssh-config
Host bastion-gateway
    HostName bastion.example.com
    User devops
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

Host dgx-private
    HostName 10.0.1.50
    User ucab-spark1
    ProxyJump bastion-gateway
    IdentityFile ~/.ssh/id_ed25519
    LocalForward 127.0.0.1:8080 127.0.0.1:8080
    LocalForward 127.0.0.1:8084 127.0.0.1:8084
    ServerAliveInterval 30
    ServerAliveCountMax 3
    ExitOnForwardFailure yes
```

---

## 3. Cryptographic Hardening Settings

For compliance and security auditing, restrict allowed key exchanges, ciphers, and MACs:

```ssh-config
Host *
    KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
    MACs hmac-sha2-512-etm@openssh.com
    HashKnownHosts yes
```
