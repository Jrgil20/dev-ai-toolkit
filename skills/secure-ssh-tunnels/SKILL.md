---
name: secure-ssh-tunnels
description: >-
  Configure, manage, and harden SSH tunnels for AI infrastructure, remote model
  inference (llama-server/vLLM), edge compute clusters (e.g. NVIDIA DGX Spark),
  and peripheral streaming (webcams/sensors). Use when creating local port forwarding (-L),
  reverse port forwarding (-R), dynamic proxies (-D), or declarative ~/.ssh/config profiles.
---

# Secure SSH Tunnels Runbook

This skill provides hardened, deterministic procedures for establishing encrypted port forwarding tunnels between local development machines and remote AI servers/edge clusters.

---

## 1. Core Security & Reliability Principles

1. **Strict Loopback Binding**: Always bind forwarded ports explicitly to `127.0.0.1`. Never leave the binding interface empty (e.g. `-L 8080:localhost:8080` instead of `-L 8080:127.0.0.1:8080`), as empty bindings may expose unauthenticated inference endpoints to the local network (`0.0.0.0`).
2. **Non-Interactive Flag (`-N`)**: Prevent shell execution or command running when the session exists only to route traffic.
3. **Fail-Fast Detection (`ExitOnForwardFailure yes`)**: Ensure the SSH process terminates immediately with an error code if the local or remote port cannot be bound.
4. **Active Keepalive**: Prevent idle state firewalls and router NAT timeouts from dropping connections:
   `-o ServerAliveInterval=30 -o ServerAliveCountMax=3`

---

## 2. Standard Recipes

### Recipe A: Local Forwarding for Remote Inference (`-L`)
Forward remote model inference ports (e.g., `llama-server` on ports `8080` and `8084`) to your local laptop:

```bash
# Foreground execution (for active monitoring):
ssh -N -o ExitOnForwardFailure=yes \
    -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
    -L 127.0.0.1:8080:127.0.0.1:8080 \
    -L 127.0.0.1:8084:127.0.0.1:8084 \
    <user>@<remote_host>

# Background daemon execution:
ssh -f -N -o ExitOnForwardFailure=yes \
    -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
    -L 127.0.0.1:8080:127.0.0.1:8080 \
    <user>@<remote_host>
```

### Recipe B: Reverse Forwarding for Edge Peripherals (`-R`)
Stream a local peripheral (e.g. laptop webcam feed on port `8082`) into a remote AI server without opening router inbound ports:

```bash
ssh -N -o ExitOnForwardFailure=yes \
    -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
    -R 127.0.0.1:8082:127.0.0.1:8082 \
    <user>@<remote_host>
```

### Recipe C: Declarative `~/.ssh/config` Profile (Recommended)
Instead of typing lengthy CLI flags, define declared host profiles with automated port forwarding and socket reuse (`ControlMaster`).
See: [Declarative SSH Config Templates](./references/ssh-config-templates.md)

---

## 3. Port Conflict & Zombie Cleanup

When a tunnel fails to bind with `bind [127.0.0.1]:8080: Address already in use`:

```bash
# 1. Identify the blocking process:
lsof -i :8080
# or: ss -tulpn | grep 8080

# 2. Terminate zombie SSH tunnels holding the port:
fuser -k 8080/tcp
```
For advanced debugging and socket teardown, see: [SSH Tunnel Troubleshooting](./references/troubleshooting.md)
