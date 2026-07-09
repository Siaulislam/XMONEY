# XMONEY — Architecture Overview

XMONEY is a production-oriented international money transfer platform with:

- **frontend-web** — Customer web application
- **admin-panel** — Operations / compliance console
- **backend-api** — Secure PHP 8.1+ REST API
- **mobile-app** — Android + iOS foundation (shared API contract)
- **database** — MySQL 8 relational schema with auditability

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│  Web App    │  │ Admin Panel │  │ Mobile Apps │
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                │
       └────────────────┼────────────────┘
                        │  HTTPS / JWT
                        ▼
              ┌───────────────────┐
              │   XMONEY API      │
              │  (backend-api)    │
              └─────────┬─────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
   MySQL DB      Payment Layer    Notification
                 (provider API)   (email/SMS/push)
                        │
                   FX Provider
```

## Security model

- Bcrypt password hashing (cost 12)
- JWT access tokens (short TTL) + hashed refresh tokens
- Role-based access: Super Admin, Admin, Support, Compliance, Customer
- Prepared statements (PDO) against SQL injection
- Input validation on all write endpoints
- Immutable `audit_logs` + `transaction_logs`
- KYC file type/size validation

## Money movement flow

1. Customer completes KYC → admin approves  
2. Customer adds beneficiary  
3. Quote: market rate − margin = customer rate + fee  
4. Transfer created → payment (wallet / card / gateway stub)  
5. Status machine: created → pending_payment → processing → under_review → completed  
6. Every status change writes `transaction_logs` + `audit_logs`

## Exchange rate model

```
Market Rate (external/manual)
        −
XMONEY Margin (admin controlled)
        =
Customer Rate
```

Example: `1 AED = 22.50 INR` market, margin `0.15` → customer `22.35 INR`.

## Payment service layer

```
PaymentService  →  PaymentProviderInterface
                      ├── StubPaymentProvider (local)
                      ├── BankTransferProvider (future)
                      ├── CardProvider (future)
                      └── GatewayProvider (future)
```

## Notification channels

Email / SMS / Push / In-app — queued in `notifications`, dispatched via provider drivers (`log` in local).
