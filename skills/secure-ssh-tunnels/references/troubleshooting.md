# SSH Tunnel Troubleshooting & Diagnosis

This guide covers resolution procedures for common connection failures, port collisions, and orphaned sockets encountered during remote AI model serving and peripheral tunneling.

---

## 1. Port Collisions (`Address already in use`)

### Symptoms
```text
bind [127.0.0.1]:8080: Address already in use
channel_setup_fwd_listener_tcpip: cannot listen to port: 8080
Could not request local forwarding.
```

### Diagnosis & Resolution
1. **Find which process holds the port**:
   ```bash
   lsof -nP -iTCP:8080 -sTCP:LISTEN
   # or
   ss -tlpn | grep ':8080'
   ```
2. **If an old SSH tunnel is lingering in the background**:
   Kill only that specific port's listener:
   ```bash
   fuser -k 8080/tcp
   ```
3. **If multiple zombie SSH instances exist**:
   ```bash
   pgrep -af "ssh.*-L.*8080"
   pkill -f "ssh.*-L.*8080"
   ```

---

## 2. Remote Port Forwarding Rejected (`RemoteForward`)

### Symptoms
```text
Warning: remote port forwarding failed for listen_port 8082
```

### Root Causes
1. **Remote Port Occupied**: The target port on the remote AI server is already in use by another service.
   - Run on remote: `fuser -k 8082/tcp`
2. **`GatewayPorts` Configuration**:
   By default, OpenSSH server binds remote forwards to `127.0.0.1` only. If other processes on the remote machine cannot access the port, verify `/etc/ssh/sshd_config` on the server:
   ```text
   GatewayPorts clientspecified
   ```

---

## 3. Silent Dropped Connections & NAT Timeouts

### Symptoms
The terminal hangs or requests to `localhost:8080` time out after a few minutes of inactivity.

### Solution
Enforce TCP keepalives and server heartbeats in client configuration:
```bash
ssh -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -o TCPKeepAlive=yes ...
```

---

## 4. ControlMaster Socket Corruption

### Symptoms
```text
ControlSocket /home/user/.ssh/control-xyz already exists
mux_client_hello_exchange: write packet: Broken pipe
```

### Solution
Delete stale control socket files:
```bash
rm -f ~/.ssh/control-*
```
