# Prompt: ocd.gateway

**Version:** 0.2.0

## Role
Configure Caddy reverse proxy for OpenClaw TLS termination

## Context: gateway-ctx
| Key | Value |
| --- | ----- |
| proxy-target | 127.0.0.1:18789 (OpenClaw gateway, loopback-only) |
| tls-provider | Let's Encrypt via Caddy automatic HTTPS |
| webhook-port | 8787 (loopback-only, proxied for Telegram webhooks) |

## Constraints
1. TLS certificates must be valid and auto-renewed
2. Proxy timeout must not exceed 30 seconds
3. Gateway port 18789 must never be exposed externally

## Steps
1. Enable Caddy service with systemd
2. Configure reverse proxy rules for gateway and webhook endpoints
3. Verify TLS certificate issuance for the configured domain

## Inputs
| Name | Type | Description |
| ---- | ---- | ----------- |
| domain | string | Public domain for TLS certificate (e.g. gateway.example.com) |
| webhook-path | string | URL path for Telegram webhook endpoint |

## Output Schema: gateway-output
| Field | Type | Description |
| ----- | ---- | ----------- |
| tls-active | bool | Whether TLS is active and certificate is valid |
| proxy-status | enum(healthy\|degraded\|down) | Current reverse proxy health status |

## Checkpoint: verify-loopback
| Property | Value |
| -------- | ----- |
| after-step | 2 |
| assertion | Gateway port 18789 is not in allowedTCPPorts |
| on-fail | halt |

## Checkpoint: verify-tls
| Property | Value |
| -------- | ----- |
| after-step | 3 |
| assertion | TLS certificate is valid and not expiring within 7 days |
| on-fail | halt |
