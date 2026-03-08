import { useState } from "react";

const serviceAccounts = [
  {
    id: "auth-service",
    label: "auth-service",
    icon: "🔐",
    roles: ["otp:send", "otp:verify", "token:generate", "token:validate", "token:revoke", "user:create", "user:read"],
    description: "Оркестратор — максимум прав, т.к. координирует весь auth-флоу"
  },
  {
    id: "token-service",
    label: "token-service",
    icon: "🎟️",
    roles: ["token:generate", "token:validate", "token:revoke", "token:rotate-keys"],
    description: "Самодостаточный — не вызывает другие сервисы, только отвечает на gRPC"
  },
  {
    id: "otp-service",
    label: "otp-service",
    icon: "📱",
    roles: ["otp:send", "otp:verify", "sms:send"],
    description: "Не вызывает другие внутренние сервисы — только внешние SMS-провайдеры"
  },
  {
    id: "api-gateway",
    label: "api-gateway",
    icon: "🌐",
    roles: ["token:validate"],
    description: "Только валидация токенов — минимальные привилегии"
  },
  {
    id: "user-service",
    label: "user-service (future)",
    icon: "👤",
    roles: ["user:read", "user:write", "token:validate"],
    description: "Будущий сервис профилей"
  },
];

const flowSteps = [
  {
    id: 1,
    title: "Стартап микросервиса",
    actors: ["auth-service", "token-service"],
    color: "#00E676",
    steps: [
      "auth-service стартует и читает из конфига свой service_id и service_secret",
      "Отправляет gRPC запрос TokenService.GenerateServiceToken({ service_id, service_secret })",
      "token-service проверяет credentials в таблице service_accounts",
      "Возвращает service_token (JWT) с claims: { sub: \"auth-service\", type: \"service\", roles: [\"otp:send\", \"otp:verify\", ...], exp: +1h }",
      "auth-service кэширует токен в памяти, обновляет за 5 мин до истечения"
    ]
  },
  {
    id: 2,
    title: "Inter-service вызов (auth → otp)",
    actors: ["auth-service", "otp-service"],
    color: "#FF6D00",
    steps: [
      "auth-service получает запрос на отправку OTP от пользователя",
      "Берёт свой service_token из кэша (или обновляет если истёк)",
      "Отправляет gRPC: OTPService.Send({ phone }, metadata: { authorization: \"Bearer <service_token>\" })",
      "otp-service извлекает токен из gRPC metadata",
      "Вызывает TokenService.Validate или проверяет локально через JWKS",
      "Проверяет claims.type == \"service\" и \"otp:send\" ∈ claims.roles",
      "Если роль есть → выполняет запрос. Если нет → возвращает PermissionDenied"
    ]
  },
  {
    id: 3,
    title: "Отказ в доступе (пример)",
    actors: ["api-gateway", "otp-service"],
    color: "#FF1744",
    steps: [
      "api-gateway пытается напрямую вызвать OTPService.Send (обход auth-service)",
      "Передаёт свой service_token в metadata",
      "otp-service валидирует токен → claims.roles = [\"token:validate\"]",
      "\"otp:send\" ∉ roles → возвращает gRPC Status: PERMISSION_DENIED",
      "В аудит-лог пишется: { caller: \"api-gateway\", action: \"otp:send\", result: \"denied\" }",
      "Алерт в мониторинг — возможна аномалия или misconfiguration"
    ]
  }
];

const rbacMatrix = [
  { permission: "otp:send", auth: true, token: false, otp: false, gw: false },
  { permission: "otp:verify", auth: true, token: false, otp: false, gw: false },
  { permission: "token:generate", auth: true, token: true, otp: false, gw: false },
  { permission: "token:validate", auth: true, token: true, otp: false, gw: true },
  { permission: "token:revoke", auth: true, token: true, otp: false, gw: false },
  { permission: "token:rotate-keys", auth: false, token: true, otp: false, gw: false },
  { permission: "user:create", auth: true, token: false, otp: false, gw: false },
  { permission: "user:read", auth: true, token: false, otp: false, gw: false },
  { permission: "sms:send", auth: false, token: false, otp: true, gw: false },
];

const dbSchema = `-- Таблица service accounts (в token-service DB)
CREATE TABLE service_accounts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id      VARCHAR(64) UNIQUE NOT NULL,    -- "auth-service"
    service_secret  VARCHAR(256) NOT NULL,           -- bcrypt hash
    display_name    VARCHAR(128),
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMPTZ DEFAULT now(),
    updated_at      TIMESTAMPTZ DEFAULT now()
);

-- Роли / permissions сервиса
CREATE TABLE service_roles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id      UUID REFERENCES service_accounts(id) ON DELETE CASCADE,
    role            VARCHAR(64) NOT NULL,            -- "otp:send"
    granted_at      TIMESTAMPTZ DEFAULT now(),
    granted_by      VARCHAR(64),                     -- кто выдал
    UNIQUE(account_id, role)
);

-- Аудит-лог межсервисных вызовов
CREATE TABLE service_auth_audit (
    id              BIGSERIAL PRIMARY KEY,
    caller_id       VARCHAR(64) NOT NULL,            -- "auth-service"
    target_id       VARCHAR(64) NOT NULL,            -- "otp-service"
    action          VARCHAR(64) NOT NULL,            -- "otp:send"
    result          VARCHAR(16) NOT NULL,            -- "granted" | "denied"
    metadata        JSONB,
    created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_audit_caller ON service_auth_audit(caller_id, created_at);
CREATE INDEX idx_audit_denied ON service_auth_audit(result) WHERE result = 'denied';`;

const tokenClaims = `// Service Token JWT Claims
{
  "iss": "tourism-superapp/token-service",
  "sub": "auth-service",                    // service_id
  "type": "service",                        // "service" | "user"
  "roles": [
    "otp:send",
    "otp:verify", 
    "token:generate",
    "token:validate",
    "token:revoke",
    "user:create",
    "user:read"
  ],
  "iat": 1709560000,
  "exp": 1709563600,                        // +1 час
  "jti": "550e8400-e29b-41d4-a716-446655440000"
}

// User Token JWT Claims (для сравнения)
{
  "iss": "tourism-superapp/token-service",
  "sub": "user-uuid-here",
  "type": "user",
  "role": "tourist",                        // "tourist" | "guide" | "agency" | "admin"
  "permissions": ["profile:read", "profile:write", "activities:join"],
  "iat": 1709560000,
  "exp": 1709561800,                        // +30 мин
  "jti": "660e8400-e29b-41d4-a716-446655440001"
}`;

const interceptorCode = `// gRPC Interceptor для проверки service token
// adapter/grpc/interceptor/auth.go

func ServiceAuthInterceptor(
    tokenValidator port.TokenValidator,
    requiredRoles map[string][]string, // method → required roles
) grpc.UnaryServerInterceptor {
    return func(
        ctx context.Context,
        req any,
        info *grpc.UnaryServerInfo,
        handler grpc.UnaryHandler,
    ) (any, error) {
        // 1. Извлекаем токен из metadata
        md, ok := metadata.FromIncomingContext(ctx)
        if !ok {
            return nil, status.Error(codes.Unauthenticated, "missing metadata")
        }

        authHeader := md.Get("authorization")
        if len(authHeader) == 0 {
            return nil, status.Error(codes.Unauthenticated, "missing auth token")
        }

        token := strings.TrimPrefix(authHeader[0], "Bearer ")

        // 2. Валидируем токен
        claims, err := tokenValidator.ValidateServiceToken(ctx, token)
        if err != nil {
            return nil, status.Error(codes.Unauthenticated, "invalid token")
        }

        // 3. Проверяем roles для данного метода
        required, exists := requiredRoles[info.FullMethod]
        if exists && !hasAllRoles(claims.Roles, required) {
            // Аудит: denied
            audit.LogDenied(ctx, claims.ServiceID, info.FullMethod)
            return nil, status.Errorf(codes.PermissionDenied,
                "service %q lacks required roles: %v", 
                claims.ServiceID, required,
            )
        }

        // 4. Добавляем caller info в context
        ctx = context.WithValue(ctx, callerKey, claims.ServiceID)
        return handler(ctx, req)
    }
}`;

export default function ServiceAuthArch() {
  const [view, setView] = useState("flow");
  const [selectedFlow, setSelectedFlow] = useState(0);
  const [selectedAccount, setSelectedAccount] = useState(null);

  const views = [
    { key: "flow", label: "Auth Flow" },
    { key: "rbac", label: "RBAC-матрица" },
    { key: "schema", label: "DB Schema" },
    { key: "claims", label: "JWT Claims" },
    { key: "code", label: "gRPC Interceptor" },
  ];

  return (
    <div style={{
      minHeight: "100vh",
      background: "#090B0E",
      color: "#CDD6E0",
      fontFamily: "'JetBrains Mono', 'SF Mono', monospace",
      padding: "20px",
    }}>
      <div style={{
        position: "fixed", inset: 0, zIndex: 0,
        background: "radial-gradient(ellipse at 30% 10%, rgba(255,23,68,0.03) 0%, transparent 40%), radial-gradient(ellipse at 70% 90%, rgba(0,230,118,0.03) 0%, transparent 40%)"
      }} />

      <div style={{ position: "relative", zIndex: 1, maxWidth: 1100, margin: "0 auto" }}>
        {/* Header */}
        <div style={{ marginBottom: 24 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 6 }}>
            <span style={{ fontSize: 10, letterSpacing: 2, color: "#455A64", textTransform: "uppercase" }}>Auth Domain</span>
            <span style={{ color: "#263238" }}>·</span>
            <span style={{ fontSize: 10, color: "#FF6D00", letterSpacing: 1 }}>Service-to-Service RBAC</span>
          </div>
          <h1 style={{ fontSize: 26, fontWeight: 700, margin: 0, color: "#ECEFF1", letterSpacing: -0.5 }}>
            Inter-Service <span style={{ color: "#FF6D00" }}>Authentication</span>
          </h1>
          <p style={{ fontSize: 11, color: "#455A64", margin: "6px 0 0", lineHeight: 1.6 }}>
            Каждый микросервис = service account с ролями. При вызове другого сервиса передаётся service JWT. Целевой сервис проверяет роли через gRPC interceptor.
          </p>
        </div>

        {/* Service Accounts */}
        <div style={{ display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 8, marginBottom: 20 }}>
          {serviceAccounts.map(sa => {
            const isSel = selectedAccount === sa.id;
            return (
              <div
                key={sa.id}
                onClick={() => setSelectedAccount(isSel ? null : sa.id)}
                style={{
                  background: isSel ? "rgba(255,109,0,0.06)" : "rgba(255,255,255,0.015)",
                  border: `1px solid ${isSel ? "#FF6D0044" : "#1A2028"}`,
                  borderRadius: 10,
                  padding: 12,
                  cursor: "pointer",
                  transition: "all 0.2s",
                }}
              >
                <div style={{ fontSize: 20, marginBottom: 6 }}>{sa.icon}</div>
                <div style={{ fontSize: 11, fontWeight: 600, color: isSel ? "#FF6D00" : "#B0BEC5", marginBottom: 4 }}>{sa.label}</div>
                <div style={{ fontSize: 9, color: "#37474F" }}>{sa.roles.length} roles</div>
              </div>
            );
          })}
        </div>

        {selectedAccount && (() => {
          const sa = serviceAccounts.find(s => s.id === selectedAccount);
          return (
            <div style={{ background: "rgba(255,109,0,0.04)", border: "1px solid #FF6D0022", borderRadius: 10, padding: 14, marginBottom: 20, animation: "slideIn 0.2s ease" }}>
              <div style={{ fontSize: 12, color: "#B0BEC5", marginBottom: 8 }}>{sa.description}</div>
              <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
                {sa.roles.map((r, i) => (
                  <span key={i} style={{ padding: "3px 8px", background: "#FF6D0015", border: "1px solid #FF6D0033", borderRadius: 4, fontSize: 10, color: "#FF6D00" }}>{r}</span>
                ))}
              </div>
            </div>
          );
        })()}

        {/* View Tabs */}
        <div style={{ display: "flex", gap: 4, marginBottom: 16, flexWrap: "wrap" }}>
          {views.map(v => (
            <button
              key={v.key}
              onClick={() => setView(v.key)}
              style={{
                padding: "7px 14px",
                border: `1px solid ${view === v.key ? "#FF6D0044" : "#1A2028"}`,
                borderRadius: 7,
                background: view === v.key ? "#FF6D0010" : "transparent",
                color: view === v.key ? "#FF6D00" : "#455A64",
                fontSize: 11,
                fontWeight: 600,
                cursor: "pointer",
                fontFamily: "inherit",
                transition: "all 0.2s"
              }}
            >
              {v.label}
            </button>
          ))}
        </div>

        {/* FLOW VIEW */}
        {view === "flow" && (
          <div>
            <div style={{ display: "flex", gap: 8, marginBottom: 14 }}>
              {flowSteps.map((f, i) => (
                <button
                  key={i}
                  onClick={() => setSelectedFlow(i)}
                  style={{
                    flex: 1,
                    padding: "10px 12px",
                    border: `1px solid ${selectedFlow === i ? f.color + "44" : "#1A2028"}`,
                    borderRadius: 8,
                    background: selectedFlow === i ? f.color + "0A" : "rgba(255,255,255,0.01)",
                    color: selectedFlow === i ? f.color : "#546E7A",
                    fontSize: 11,
                    fontWeight: 600,
                    cursor: "pointer",
                    fontFamily: "inherit",
                    textAlign: "left",
                    transition: "all 0.2s"
                  }}
                >
                  <div>{f.title}</div>
                  <div style={{ fontSize: 9, color: "#37474F", marginTop: 4 }}>{f.actors.join(" → ")}</div>
                </button>
              ))}
            </div>
            <div style={{ background: "#060809", borderRadius: 10, padding: 18 }}>
              {flowSteps[selectedFlow].steps.map((step, i) => (
                <div key={i} style={{ display: "flex", gap: 12, marginBottom: i < flowSteps[selectedFlow].steps.length - 1 ? 10 : 0, paddingBottom: i < flowSteps[selectedFlow].steps.length - 1 ? 10 : 0, borderBottom: i < flowSteps[selectedFlow].steps.length - 1 ? "1px solid #0F1318" : "none" }}>
                  <div style={{
                    minWidth: 24, height: 24, borderRadius: "50%",
                    background: flowSteps[selectedFlow].color + "15",
                    border: `1px solid ${flowSteps[selectedFlow].color}33`,
                    display: "flex", alignItems: "center", justifyContent: "center",
                    fontSize: 10, fontWeight: 700, color: flowSteps[selectedFlow].color
                  }}>{i + 1}</div>
                  <div style={{ fontSize: 12, color: "#90A4AE", lineHeight: 1.6, paddingTop: 2 }}>{step}</div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* RBAC MATRIX */}
        {view === "rbac" && (
          <div style={{ background: "#060809", borderRadius: 10, padding: 18, overflowX: "auto" }}>
            <table style={{ width: "100%", borderCollapse: "collapse", fontSize: 11 }}>
              <thead>
                <tr>
                  <th style={{ textAlign: "left", padding: "8px 12px", color: "#546E7A", borderBottom: "1px solid #1A2028", fontWeight: 600 }}>Permission</th>
                  {["auth-service", "token-service", "otp-service", "api-gateway"].map(h => (
                    <th key={h} style={{ textAlign: "center", padding: "8px 12px", color: "#546E7A", borderBottom: "1px solid #1A2028", fontWeight: 600 }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {rbacMatrix.map((row, i) => (
                  <tr key={i}>
                    <td style={{ padding: "8px 12px", color: "#B0BEC5", borderBottom: "1px solid #0F1318", fontFamily: "'JetBrains Mono', monospace" }}>{row.permission}</td>
                    {[row.auth, row.token, row.otp, row.gw].map((val, j) => (
                      <td key={j} style={{ textAlign: "center", padding: "8px 12px", borderBottom: "1px solid #0F1318" }}>
                        {val ? (
                          <span style={{ color: "#00E676", fontSize: 14 }}>✓</span>
                        ) : (
                          <span style={{ color: "#263238", fontSize: 14 }}>·</span>
                        )}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
            <div style={{ marginTop: 14, padding: "10px 12px", background: "#0D1117", borderRadius: 6, fontSize: 10, color: "#455A64", lineHeight: 1.6 }}>
              <span style={{ color: "#FFD54F", fontWeight: 700 }}>Принцип минимальных привилегий:</span> каждый сервис имеет только те роли, которые необходимы для его работы. api-gateway может только валидировать токены. otp-service не может генерировать JWT. auth-service — единственный, кто может вызывать и OTP, и Token сервисы.
            </div>
          </div>
        )}

        {/* DB SCHEMA */}
        {view === "schema" && (
          <div style={{ background: "#060809", borderRadius: 10, padding: 18 }}>
            <pre style={{ margin: 0, fontSize: 11, lineHeight: 1.7, color: "#90A4AE", overflowX: "auto", whiteSpace: "pre-wrap" }}>
              {dbSchema.split('\n').map((line, i) => (
                <div key={i}>
                  {line.startsWith('--') ? (
                    <span style={{ color: "#455A64" }}>{line}</span>
                  ) : line.match(/^(CREATE|ALTER|DROP|INSERT)/) ? (
                    <span style={{ color: "#FF6D00" }}>{line}</span>
                  ) : line.match(/^\s+(id|service_id|service_secret|display_name|is_active|created_at|updated_at|account_id|role|granted_at|granted_by|caller_id|target_id|action|result|metadata)/) ? (
                    <span>
                      <span style={{ color: "#80CBC4" }}>{line.match(/^\s+\w+/)?.[0]}</span>
                      <span style={{ color: "#546E7A" }}>{line.replace(/^\s+\w+/, '')}</span>
                    </span>
                  ) : line.match(/^\);|^CREATE INDEX/) ? (
                    <span style={{ color: "#FF6D00" }}>{line}</span>
                  ) : (
                    <span style={{ color: "#546E7A" }}>{line}</span>
                  )}
                </div>
              ))}
            </pre>
          </div>
        )}

        {/* JWT CLAIMS */}
        {view === "claims" && (
          <div style={{ background: "#060809", borderRadius: 10, padding: 18 }}>
            <pre style={{ margin: 0, fontSize: 11, lineHeight: 1.7, overflowX: "auto", whiteSpace: "pre-wrap" }}>
              {tokenClaims.split('\n').map((line, i) => (
                <div key={i}>
                  {line.startsWith('//') ? (
                    <span style={{ color: "#455A64" }}>{line}</span>
                  ) : line.match(/"[^"]+":/) ? (
                    <span>
                      <span style={{ color: "#FF6D00" }}>{line.match(/"[^"]+"/)?.[0]}</span>
                      <span style={{ color: "#546E7A" }}>{line.replace(/"[^"]+"/  , '').substring(0, 2)}</span>
                      <span style={{ color: "#80CBC4" }}>{line.split(': ').slice(1).join(': ')}</span>
                    </span>
                  ) : line.includes('"') ? (
                    <span style={{ color: "#A5D6A7" }}>{line}</span>
                  ) : (
                    <span style={{ color: "#546E7A" }}>{line}</span>
                  )}
                </div>
              ))}
            </pre>
          </div>
        )}

        {/* gRPC INTERCEPTOR */}
        {view === "code" && (
          <div style={{ background: "#060809", borderRadius: 10, padding: 18 }}>
            <pre style={{ margin: 0, fontSize: 11, lineHeight: 1.7, overflowX: "auto", whiteSpace: "pre-wrap" }}>
              {interceptorCode.split('\n').map((line, i) => {
                const trimmed = line.trimStart();
                if (trimmed.startsWith('//')) return <div key={i}><span style={{ color: "#455A64" }}>{line}</span></div>;
                if (trimmed.startsWith('func ') || trimmed.startsWith('return func')) return <div key={i}><span style={{ color: "#FF6D00" }}>{line}</span></div>;
                if (trimmed.startsWith('if ')) return <div key={i}><span style={{ color: "#FFD54F" }}>{line}</span></div>;
                if (trimmed.includes('status.Error')) return <div key={i}><span style={{ color: "#FF1744" }}>{line}</span></div>;
                return <div key={i}><span style={{ color: "#90A4AE" }}>{line}</span></div>;
              })}
            </pre>
          </div>
        )}

        {/* Architecture Diagram */}
        <div style={{ marginTop: 20, background: "rgba(255,255,255,0.01)", border: "1px solid #1A2028", borderRadius: 12, padding: 20 }}>
          <div style={{ fontSize: 11, fontWeight: 700, color: "#546E7A", marginBottom: 14, letterSpacing: 1, textTransform: "uppercase" }}>Принципы S2S Auth</div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 14 }}>
            {[
              { icon: "🔑", title: "Client Credentials", desc: "Сервис авторизуется через service_id + service_secret → получает JWT с ролями. Секреты хранятся в Vault / env, никогда в коде.", color: "#00E676" },
              { icon: "🛡️", title: "Least Privilege", desc: "Каждый сервис имеет минимально необходимый набор ролей. Новые роли выдаются явно через service_roles. Аудит всех отказов.", color: "#FF6D00" },
              { icon: "⚡", title: "Token Cache + JWKS", desc: "Service token кэшируется в памяти, обновляется за 5 мин до exp. Валидация — локально через JWKS (без сетевого вызова на каждый запрос).", color: "#448AFF" },
            ].map((item, i) => (
              <div key={i} style={{ background: "#0D1117", border: "1px solid #1A2028", borderRadius: 8, padding: 14 }}>
                <div style={{ fontSize: 20, marginBottom: 8 }}>{item.icon}</div>
                <div style={{ fontSize: 12, fontWeight: 700, color: item.color, marginBottom: 6 }}>{item.title}</div>
                <div style={{ fontSize: 10, color: "#455A64", lineHeight: 1.6 }}>{item.desc}</div>
              </div>
            ))}
          </div>
        </div>

        <div style={{ marginTop: 24, textAlign: "center", color: "#1A2028", fontSize: 10, letterSpacing: 1 }}>
          SERVICE-TO-SERVICE RBAC · CLIENT CREDENTIALS · gRPC INTERCEPTORS
        </div>
      </div>

      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;700&display=swap');
        @keyframes slideIn { from { opacity: 0; transform: translateY(4px); } to { opacity: 1; transform: translateY(0); } }
        * { box-sizing: border-box; }
        ::-webkit-scrollbar { width: 5px; height: 5px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.06); border-radius: 3px; }
      `}</style>
    </div>
  );
}
