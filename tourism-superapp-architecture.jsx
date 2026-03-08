import { useState } from "react";

const modules = [
  {
    id: "auth",
    title: "Авторизация",
    icon: "🔐",
    color: "#E8F5E9",
    accent: "#2E7D32",
    x: 0, y: 0,
    details: {
      description: "Мультипровайдерная аутентификация с JWT-токенами",
      stack: ["Firebase Auth / Supabase Auth", "JWT + Refresh tokens", "Redis (сессии)", "Rate Limiter"],
      goServices: ["auth-service (gRPC)", "token-service", "otp-service (SMS)"],
      endpoints: ["POST /auth/phone/otp", "POST /auth/phone/verify", "POST /auth/google", "POST /auth/apple", "POST /auth/refresh"],
      dbTables: ["users", "auth_providers", "otp_codes", "sessions"],
      notes: "Phone → Twilio/SMS-центр. Google/Apple → OAuth2 PKCE flow. Все токены — RS256 JWT с ротацией ключей."
    }
  },
  {
    id: "profile",
    title: "Профиль",
    icon: "👤",
    color: "#E3F2FD",
    accent: "#1565C0",
    x: 1, y: 0,
    details: {
      description: "Управление профилем, предпочтениями и историей",
      stack: ["PostgreSQL", "S3 (аватары)", "ElasticSearch (поиск)"],
      goServices: ["user-service", "preference-service", "media-service"],
      endpoints: ["GET/PUT /users/me", "PUT /users/me/avatar", "GET /users/me/history", "GET /users/me/preferences"],
      dbTables: ["user_profiles", "user_preferences", "user_media", "travel_history"],
      notes: "Профиль хранит язык, валюту, интересы (теги). История поездок — для рекомендаций. GDPR-compliant export/delete."
    }
  },
  {
    id: "activities",
    title: "Активности",
    icon: "🏔️",
    color: "#FFF3E0",
    accent: "#E65100",
    x: 2, y: 0,
    details: {
      description: "Создание и участие в активностях с набором людей",
      stack: ["PostgreSQL", "Redis (кэш)", "ElasticSearch (поиск)", "S3 (медиа)"],
      goServices: ["activity-service", "participant-service", "search-service"],
      endpoints: ["CRUD /activities", "POST /activities/:id/join", "GET /activities/search", "GET /activities/nearby"],
      dbTables: ["activities", "activity_participants", "activity_tags", "activity_media", "activity_reviews"],
      notes: "Геолокационный поиск (PostGIS). Статусы: draft → open → full → active → completed. Уведомления участникам через event bus."
    }
  },
  {
    id: "chat",
    title: "Чат",
    icon: "💬",
    color: "#F3E5F5",
    accent: "#7B1FA2",
    x: 3, y: 0,
    details: {
      description: "Real-time мессенджер для активностей и личных сообщений",
      stack: ["WebSocket (gorilla/websocket)", "NATS / Kafka", "MongoDB (история)", "Redis (presence)"],
      goServices: ["chat-gateway (WS)", "message-service", "notification-service"],
      endpoints: ["WS /ws/chat", "GET /chats", "GET /chats/:id/messages", "POST /chats/:id/messages"],
      dbTables: ["conversations", "messages", "message_read_status", "chat_members"],
      notes: "WebSocket gateway с горизонтальным масштабированием через NATS. Поддержка текста, фото, геолокации. Пуш через FCM/APNs."
    }
  },
  {
    id: "tours",
    title: "Туры",
    icon: "🗺️",
    color: "#E0F7FA",
    accent: "#00838F",
    x: 0, y: 1,
    details: {
      description: "Каталог туров от турфирм с бронированием",
      stack: ["PostgreSQL", "ElasticSearch", "Redis", "S3"],
      goServices: ["tour-service", "tour-catalog-service", "booking-service"],
      endpoints: ["GET /tours/search", "GET /tours/:id", "POST /tours/:id/book", "GET /agencies/:id/tours"],
      dbTables: ["tours", "tour_schedules", "tour_agencies", "tour_bookings", "tour_media"],
      notes: "Турфирмы — отдельная роль с панелью управления. API-интеграция для загрузки туров. Модерация контента. Мультивалютность."
    }
  },
  {
    id: "guides",
    title: "Гиды",
    icon: "🧭",
    color: "#FFF8E1",
    accent: "#F57F17",
    x: 1, y: 1,
    details: {
      description: "Маркетплейс гидов с рейтингами и верификацией",
      stack: ["PostgreSQL", "ElasticSearch", "Redis", "S3"],
      goServices: ["guide-service", "review-service", "verification-service"],
      endpoints: ["GET /guides/search", "GET /guides/:id", "POST /guides/:id/book", "POST /guides/:id/reviews", "GET /guides/:id/calendar"],
      dbTables: ["guide_profiles", "guide_specializations", "guide_reviews", "guide_calendar", "guide_verifications"],
      notes: "Гид = User + guide_profile. Рейтинг = Bayesian average. Верификация документов. Календарь доступности. Комиссия платформы."
    }
  },
  {
    id: "hotels",
    title: "Отели и жильё",
    icon: "🏨",
    color: "#FCE4EC",
    accent: "#C62828",
    x: 2, y: 1,
    details: {
      description: "Агрегация предложений жилья по локации пользователя",
      stack: ["Adapter Pattern", "Redis (кэш цен)", "PostgreSQL"],
      goServices: ["accommodation-service", "aggregator-adapter", "price-service"],
      endpoints: ["GET /accommodations/search", "GET /accommodations/:id", "POST /accommodations/:id/book"],
      dbTables: ["accommodation_cache", "accommodation_bookings", "aggregator_configs"],
      notes: "Адаптеры: Booking.com API, Airbnb API, локальные провайдеры. Выбор агрегатора по геолокации. Кэширование цен на 15 мин."
    }
  },
  {
    id: "taxi",
    title: "Такси и транспорт",
    icon: "🚕",
    color: "#E8EAF6",
    accent: "#283593",
    x: 3, y: 1,
    details: {
      description: "Вызов такси через локальных провайдеров",
      stack: ["Adapter Pattern", "WebSocket (трекинг)", "Redis"],
      goServices: ["transport-service", "ride-tracker", "provider-adapter"],
      endpoints: ["POST /rides/estimate", "POST /rides/request", "GET /rides/:id/track", "GET /transport/providers"],
      dbTables: ["ride_requests", "ride_history", "transport_providers", "provider_regions"],
      notes: "Адаптеры: Uber, Bolt, Яндекс Go, локальные. Deeplink или API в зависимости от провайдера. Геозоны доступности."
    }
  },
  {
    id: "payments",
    title: "Платежи",
    icon: "💳",
    color: "#EFEBE9",
    accent: "#4E342E",
    x: 0, y: 2,
    details: {
      description: "Единая платёжная система с мультивалютностью",
      stack: ["Stripe / PayPal", "PostgreSQL", "Redis (идемпотентность)"],
      goServices: ["payment-service", "wallet-service", "payout-service", "invoice-service"],
      endpoints: ["POST /payments/intent", "POST /payments/confirm", "GET /payments/history", "POST /payouts (гидам/агентствам)"],
      dbTables: ["payment_intents", "transactions", "wallets", "payouts", "refunds"],
      notes: "PCI DSS — токенизация карт через Stripe. Выплаты гидам/агентствам — Stripe Connect. Эскроу для безопасных сделок."
    }
  },
  {
    id: "gateway",
    title: "API Gateway",
    icon: "🌐",
    color: "#F1F8E9",
    accent: "#558B2F",
    x: 1, y: 2,
    details: {
      description: "Единая точка входа, роутинг, rate limiting",
      stack: ["Kong / Traefik / собственный на Go", "Redis", "Prometheus"],
      goServices: ["api-gateway", "rate-limiter", "auth-middleware"],
      endpoints: ["/* → роутинг к микросервисам"],
      dbTables: ["api_keys", "rate_limit_rules", "route_configs"],
      notes: "JWT-валидация на gateway. Rate limiting по IP и user. Circuit breaker. Request/Response трансформации. gRPC → REST трансляция."
    }
  },
  {
    id: "notifications",
    title: "Уведомления",
    icon: "🔔",
    color: "#FDE0DC",
    accent: "#BF360C",
    x: 2, y: 2,
    details: {
      description: "Мультиканальные уведомления: push, SMS, email",
      stack: ["NATS / Kafka", "FCM / APNs", "Twilio", "SendGrid"],
      goServices: ["notification-service", "push-service", "email-service", "sms-service"],
      endpoints: ["POST /notifications/send", "GET /notifications", "PUT /notifications/settings"],
      dbTables: ["notifications", "notification_templates", "device_tokens", "notification_preferences"],
      notes: "Event-driven через message bus. Шаблоны с i18n. Пользователь управляет каналами и типами. Батчинг для массовой рассылки."
    }
  },
  {
    id: "superapp",
    title: "Агрегатор сервисов",
    icon: "🧩",
    color: "#E0E0E0",
    accent: "#37474F",
    x: 3, y: 2,
    details: {
      description: "Динамическая загрузка мини-приложений по геолокации",
      stack: ["Feature Flags", "PostgreSQL", "Redis", "CDN"],
      goServices: ["service-registry", "geo-resolver", "miniapp-service"],
      endpoints: ["GET /services/available?lat=&lng=", "GET /miniapps/:id/config", "GET /miniapps/:id/bundle"],
      dbTables: ["service_registry", "geo_zones", "miniapp_configs", "miniapp_bundles"],
      notes: "Super App паттерн: сервисы появляются/скрываются по геозоне. Mini-app SDK для партнёров. Dynamic feature modules на клиенте."
    }
  }
];

const infraLayers = [
  { label: "Клиент", items: ["React Native / Flutter", "Offline-first (SQLite)", "Deep linking", "Push SDK"], color: "#00BCD4" },
  { label: "Инфраструктура", items: ["Kubernetes", "Docker", "Terraform / Pulumi", "CI/CD (GitHub Actions)"], color: "#FF7043" },
  { label: "Данные", items: ["PostgreSQL + PostGIS", "MongoDB", "Redis Cluster", "ElasticSearch"], color: "#AB47BC" },
  { label: "Observability", items: ["Prometheus + Grafana", "Jaeger (трейсинг)", "ELK Stack (логи)", "Sentry (ошибки)"], color: "#5C6BC0" },
];

export default function SuperAppArchitecture() {
  const [selected, setSelected] = useState(null);
  const [activeTab, setActiveTab] = useState("stack");
  const [hoveredModule, setHoveredModule] = useState(null);

  const selectedModule = modules.find(m => m.id === selected);

  const tabs = [
    { key: "stack", label: "Стек" },
    { key: "services", label: "Go-сервисы" },
    { key: "api", label: "API" },
    { key: "db", label: "БД" },
    { key: "notes", label: "Заметки" },
  ];

  return (
    <div style={{
      minHeight: "100vh",
      background: "#0A0A0F",
      color: "#E8E6E1",
      fontFamily: "'JetBrains Mono', 'SF Mono', 'Fira Code', monospace",
      padding: "24px",
      position: "relative",
      overflow: "hidden"
    }}>
      {/* Background grid */}
      <div style={{
        position: "fixed", inset: 0, zIndex: 0,
        backgroundImage: "radial-gradient(circle at 1px 1px, rgba(255,255,255,0.03) 1px, transparent 0)",
        backgroundSize: "32px 32px"
      }} />

      <div style={{ position: "relative", zIndex: 1, maxWidth: 1200, margin: "0 auto" }}>
        {/* Header */}
        <div style={{ textAlign: "center", marginBottom: 40 }}>
          <div style={{
            display: "inline-block",
            padding: "4px 14px",
            border: "1px solid rgba(0,188,212,0.3)",
            borderRadius: 20,
            fontSize: 11,
            letterSpacing: 2,
            textTransform: "uppercase",
            color: "#00BCD4",
            marginBottom: 16
          }}>
            System Architecture v1.0
          </div>
          <h1 style={{
            fontSize: 36,
            fontWeight: 700,
            margin: "8px 0",
            background: "linear-gradient(135deg, #E8E6E1 0%, #00BCD4 50%, #FF7043 100%)",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            letterSpacing: -1
          }}>
            Tourism SuperApp
          </h1>
          <p style={{ color: "#6B6B76", fontSize: 13, maxWidth: 600, margin: "0 auto" }}>
            Микросервисная архитектура на Go · 12 доменных модулей · Кликните на модуль для деталей
          </p>
        </div>

        {/* Module Grid */}
        <div style={{
          display: "grid",
          gridTemplateColumns: "repeat(4, 1fr)",
          gap: 12,
          marginBottom: 24
        }}>
          {modules.map(mod => {
            const isSelected = selected === mod.id;
            const isHovered = hoveredModule === mod.id;
            return (
              <div
                key={mod.id}
                onClick={() => { setSelected(isSelected ? null : mod.id); setActiveTab("stack"); }}
                onMouseEnter={() => setHoveredModule(mod.id)}
                onMouseLeave={() => setHoveredModule(null)}
                style={{
                  background: isSelected
                    ? `linear-gradient(135deg, ${mod.accent}22, ${mod.accent}11)`
                    : isHovered
                      ? "rgba(255,255,255,0.04)"
                      : "rgba(255,255,255,0.02)",
                  border: `1px solid ${isSelected ? mod.accent + "66" : isHovered ? "rgba(255,255,255,0.08)" : "rgba(255,255,255,0.04)"}`,
                  borderRadius: 12,
                  padding: "16px 14px",
                  cursor: "pointer",
                  transition: "all 0.25s ease",
                  transform: isSelected ? "scale(1.02)" : isHovered ? "translateY(-2px)" : "none",
                  position: "relative",
                  overflow: "hidden"
                }}
              >
                {isSelected && (
                  <div style={{
                    position: "absolute", top: 0, left: 0, right: 0, height: 2,
                    background: `linear-gradient(90deg, transparent, ${mod.accent}, transparent)`
                  }} />
                )}
                <div style={{ fontSize: 24, marginBottom: 8 }}>{mod.icon}</div>
                <div style={{
                  fontSize: 13,
                  fontWeight: 600,
                  color: isSelected ? mod.accent : "#C8C6C1",
                  marginBottom: 4
                }}>
                  {mod.title}
                </div>
                <div style={{ fontSize: 10, color: "#5A5A64", lineHeight: 1.4 }}>
                  {mod.details.goServices.length} сервис{mod.details.goServices.length > 4 ? "ов" : mod.details.goServices.length > 1 ? "а" : ""}
                </div>
              </div>
            );
          })}
        </div>

        {/* Detail Panel */}
        {selectedModule && (
          <div style={{
            background: "rgba(255,255,255,0.02)",
            border: `1px solid ${selectedModule.accent}33`,
            borderRadius: 16,
            padding: 24,
            marginBottom: 24,
            animation: "fadeIn 0.3s ease"
          }}>
            <div style={{ display: "flex", alignItems: "center", gap: 12, marginBottom: 20 }}>
              <span style={{ fontSize: 28 }}>{selectedModule.icon}</span>
              <div>
                <h2 style={{ fontSize: 18, fontWeight: 700, color: selectedModule.accent, margin: 0 }}>
                  {selectedModule.title}
                </h2>
                <p style={{ fontSize: 12, color: "#6B6B76", margin: "4px 0 0" }}>
                  {selectedModule.details.description}
                </p>
              </div>
            </div>

            {/* Tabs */}
            <div style={{ display: "flex", gap: 4, marginBottom: 20, flexWrap: "wrap" }}>
              {tabs.map(tab => (
                <button
                  key={tab.key}
                  onClick={() => setActiveTab(tab.key)}
                  style={{
                    padding: "6px 14px",
                    border: `1px solid ${activeTab === tab.key ? selectedModule.accent + "66" : "rgba(255,255,255,0.06)"}`,
                    borderRadius: 8,
                    background: activeTab === tab.key ? selectedModule.accent + "18" : "transparent",
                    color: activeTab === tab.key ? selectedModule.accent : "#6B6B76",
                    fontSize: 11,
                    fontWeight: 600,
                    cursor: "pointer",
                    fontFamily: "inherit",
                    transition: "all 0.2s"
                  }}
                >
                  {tab.label}
                </button>
              ))}
            </div>

            {/* Tab Content */}
            <div style={{
              background: "rgba(0,0,0,0.3)",
              borderRadius: 10,
              padding: 18,
              fontFamily: "'JetBrains Mono', monospace",
              fontSize: 12,
              lineHeight: 1.8
            }}>
              {activeTab === "stack" && selectedModule.details.stack.map((s, i) => (
                <div key={i} style={{ display: "flex", alignItems: "center", gap: 8 }}>
                  <span style={{ color: selectedModule.accent }}>▸</span>
                  <span style={{ color: "#C8C6C1" }}>{s}</span>
                </div>
              ))}
              {activeTab === "services" && selectedModule.details.goServices.map((s, i) => (
                <div key={i} style={{ display: "flex", alignItems: "center", gap: 8 }}>
                  <span style={{ color: "#00BCD4", fontSize: 10 }}>func</span>
                  <span style={{ color: "#FF7043" }}>{s}</span>
                </div>
              ))}
              {activeTab === "api" && selectedModule.details.endpoints.map((e, i) => {
                const method = e.split(" ")[0];
                const path = e.substring(method.length + 1);
                const methodColors = { GET: "#4CAF50", POST: "#FF9800", PUT: "#2196F3", DELETE: "#F44336", WS: "#AB47BC", "/*": "#78909C" };
                return (
                  <div key={i} style={{ display: "flex", alignItems: "center", gap: 8 }}>
                    <span style={{
                      color: methodColors[method] || "#6B6B76",
                      fontWeight: 700,
                      fontSize: 10,
                      minWidth: 36
                    }}>{method}</span>
                    <span style={{ color: "#C8C6C1" }}>{path}</span>
                  </div>
                );
              })}
              {activeTab === "db" && selectedModule.details.dbTables.map((t, i) => (
                <div key={i} style={{ display: "flex", alignItems: "center", gap: 8 }}>
                  <span style={{ color: "#AB47BC", fontSize: 10 }}>TABLE</span>
                  <span style={{ color: "#C8C6C1" }}>{t}</span>
                </div>
              ))}
              {activeTab === "notes" && (
                <p style={{ color: "#9E9E8E", margin: 0, lineHeight: 1.8 }}>
                  {selectedModule.details.notes}
                </p>
              )}
            </div>
          </div>
        )}

        {/* Infrastructure */}
        <div style={{ marginBottom: 24 }}>
          <div style={{
            fontSize: 11,
            letterSpacing: 2,
            textTransform: "uppercase",
            color: "#5A5A64",
            marginBottom: 12,
            paddingLeft: 4
          }}>
            Инфраструктурные слои
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 12 }}>
            {infraLayers.map((layer, i) => (
              <div key={i} style={{
                background: "rgba(255,255,255,0.02)",
                border: "1px solid rgba(255,255,255,0.04)",
                borderRadius: 12,
                padding: 16,
                borderTop: `2px solid ${layer.color}44`
              }}>
                <div style={{ fontSize: 12, fontWeight: 700, color: layer.color, marginBottom: 10 }}>
                  {layer.label}
                </div>
                {layer.items.map((item, j) => (
                  <div key={j} style={{ fontSize: 11, color: "#7A7A84", marginBottom: 4 }}>
                    {item}
                  </div>
                ))}
              </div>
            ))}
          </div>
        </div>

        {/* Architecture pattern callout */}
        <div style={{
          background: "rgba(0,188,212,0.04)",
          border: "1px solid rgba(0,188,212,0.12)",
          borderRadius: 12,
          padding: 20,
          display: "grid",
          gridTemplateColumns: "repeat(3, 1fr)",
          gap: 20
        }}>
          {[
            { title: "Паттерн", desc: "Микросервисы + Event-Driven. Каждый модуль — изолированный bounded context с собственной БД.", icon: "⬡" },
            { title: "Коммуникация", desc: "Синхронно: gRPC между сервисами, REST для клиента. Асинхронно: NATS/Kafka для событий.", icon: "⇋" },
            { title: "Масштабирование", desc: "Горизонтальное через K8s. Stateless-сервисы. Шардирование PostgreSQL. Redis Cluster.", icon: "⊞" },
          ].map((item, i) => (
            <div key={i}>
              <div style={{ fontSize: 20, marginBottom: 8, color: "#00BCD4" }}>{item.icon}</div>
              <div style={{ fontSize: 12, fontWeight: 700, color: "#C8C6C1", marginBottom: 4 }}>
                {item.title}
              </div>
              <div style={{ fontSize: 11, color: "#6B6B76", lineHeight: 1.6 }}>
                {item.desc}
              </div>
            </div>
          ))}
        </div>

        {/* Footer */}
        <div style={{ textAlign: "center", marginTop: 32, color: "#3A3A44", fontSize: 10, letterSpacing: 1 }}>
          GOLANG MICROSERVICES · GRPC · KUBERNETES · EVENT-DRIVEN
        </div>
      </div>

      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@400;600;700&display=swap');
        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(8px); }
          to { opacity: 1; transform: translateY(0); }
        }
        * { box-sizing: border-box; }
        ::-webkit-scrollbar { width: 6px; }
        ::-webkit-scrollbar-track { background: transparent; }
        ::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.1); border-radius: 3px; }
      `}</style>
    </div>
  );
}
