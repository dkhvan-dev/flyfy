package http

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strconv"
	"strings"

	"github.com/rs/zerolog/log"

	"kz/inflap/backend/services/api-gateway/internal/adapter"
	trustserviceadapter "kz/inflap/backend/services/api-gateway/internal/adapter/trustservice"
	"kz/inflap/backend/services/api-gateway/internal/config"
)

type ProxyHandler struct {
	cfg               *config.Config
	readiness         *ReadinessHandler
	authProxy         *httputil.ReverseProxy
	userProxy         *httputil.ReverseProxy
	guideProxy        *httputil.ReverseProxy
	fileManagerProxy  *httputil.ReverseProxy
	activityProxy     *httputil.ReverseProxy
	excursionProxy    *httputil.ReverseProxy
	feedProxy         *httputil.ReverseProxy
	chatProxy         *httputil.ReverseProxy
	referenceProxy    *httputil.ReverseProxy
	checklistProxy    *httputil.ReverseProxy
	currencyProxy     *httputil.ReverseProxy
	placeProxy        *httputil.ReverseProxy
	routingProxy      *httputil.ReverseProxy
	userRouteProxy    *httputil.ReverseProxy
	paymentProxy      *httputil.ReverseProxy
	stickerProxy      *httputil.ReverseProxy
	notificationProxy *httputil.ReverseProxy
	supportProxy      *httputil.ReverseProxy
	adminPanelProxy   *httputil.ReverseProxy
	trustClient       *trustserviceadapter.Client
	userIDResolver    userIDResolver
}

func NewProxyHandler(cfg *config.Config, readiness *ReadinessHandler) (*ProxyHandler, error) {
	authProxy, err := newSingleHostProxy("auth", cfg.Downstreams.AuthService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	userProxy, err := newSingleHostProxy("user", cfg.Downstreams.UserService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	guideProxy, err := newSingleHostProxy("guide", cfg.Downstreams.GuideService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	fileManagerProxy, err := newSingleHostProxy("file-manager", cfg.Downstreams.FileManagerService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	activityProxy, err := newSingleHostProxy("activity", cfg.Downstreams.ActivityService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	excursionProxy, err := newSingleHostProxy("excursion", cfg.Downstreams.ExcursionService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	feedProxy, err := newSingleHostProxy("feed", cfg.Downstreams.FeedService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	chatProxy, err := newSingleHostProxy("chat", cfg.Downstreams.ChatService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	referenceProxy, err := newSingleHostProxy("reference", cfg.Downstreams.ReferenceService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	checklistProxy, err := newSingleHostProxy("checklist", cfg.Downstreams.ChecklistService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	currencyProxy, err := newSingleHostProxy("currency", cfg.Downstreams.CurrencyService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	placeProxy, err := newSingleHostProxy("place", cfg.Downstreams.PlaceService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	routingProxy, err := newSingleHostProxy("routing", cfg.Downstreams.RoutingService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	userRouteProxy, err := newSingleHostProxy("user-route", cfg.Downstreams.UserRouteService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	paymentProxy, err := newSingleHostProxy("payment", cfg.Downstreams.PaymentService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	stickerProxy, err := newSingleHostProxy("sticker", cfg.Downstreams.StickerService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	notificationProxy, err := newSingleHostProxy("notification", cfg.Downstreams.NotificationService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	supportProxy, err := newSingleHostProxy("support", cfg.Downstreams.SupportService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	adminPanelProxy, err := newSingleHostProxy("admin-panel", cfg.Downstreams.AdminPanelService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	trustClient, err := trustserviceadapter.New(cfg.TrustService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	userIDResolver, err := newUserServiceUserIDResolver(cfg)
	if err != nil {
		_ = trustClient.Close()
		return nil, err
	}

	return &ProxyHandler{
		cfg:               cfg,
		readiness:         readiness,
		authProxy:         authProxy,
		userProxy:         userProxy,
		guideProxy:        guideProxy,
		fileManagerProxy:  fileManagerProxy,
		activityProxy:     activityProxy,
		excursionProxy:    excursionProxy,
		feedProxy:         feedProxy,
		chatProxy:         chatProxy,
		referenceProxy:    referenceProxy,
		checklistProxy:    checklistProxy,
		currencyProxy:     currencyProxy,
		placeProxy:        placeProxy,
		routingProxy:      routingProxy,
		userRouteProxy:    userRouteProxy,
		paymentProxy:      paymentProxy,
		stickerProxy:      stickerProxy,
		notificationProxy: notificationProxy,
		supportProxy:      supportProxy,
		adminPanelProxy:   adminPanelProxy,
		trustClient:       trustClient,
		userIDResolver:    userIDResolver,
	}, nil
}

func (h *ProxyHandler) Close() error {
	if h == nil || h.trustClient == nil {
		return nil
	}
	return h.trustClient.Close()
}

func (h *ProxyHandler) Register(mux *http.ServeMux) {
	mux.HandleFunc("GET /health", h.Health)
	mux.HandleFunc("GET /ready", h.Ready)
	mux.HandleFunc("/", h.Dispatch)
}

func (h *ProxyHandler) Health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{
		"status": "ok",
	})
}

func (h *ProxyHandler) Ready(w http.ResponseWriter, r *http.Request) {
	if h.readiness == nil {
		writeJSON(w, http.StatusOK, map[string]string{
			"status": "ready",
		})
		return
	}
	h.readiness.Ready(w, r)
}

func (h *ProxyHandler) Dispatch(w http.ResponseWriter, r *http.Request) {
	policy := RoutePolicyFromContext(r.Context())
	if policy == nil {
		policy = matchRoutePolicyForMethod(r.Method, r.URL.Path, h.cfg.Routes.APIPrefix)
	}
	if policy == nil {
		writeBusinessError(w, r, http.StatusNotFound, errorCodeRouteNotFound)
		return
	}

	if policy.Upstream == "trust" {
		h.dispatchTrust(w, r, policy)
		return
	}

	proxy := h.resolveProxy(policy.Upstream)
	if proxy == nil {
		writeTechnicalError(w, r, http.StatusBadGateway, errorCodeUpstreamUnavailable)
		return
	}

	proxyReq := r.Clone(r.Context())
	h.rewritePath(proxyReq, policy)
	if err := h.injectTrustedHeaders(proxyReq, policy.AuthMode); err != nil {
		log.Warn().
			Err(err).
			Str("route", policy.Name).
			Str("request_id", RequestIDFromContext(r.Context())).
			Msg("failed to inject trusted auth headers")
		writeTechnicalError(w, r, http.StatusBadGateway, errorCodeUserResolution)
		return
	}

	log.Info().
		Str("upstream", policy.Upstream).
		Str("route", policy.Name).
		Str("request_id", RequestIDFromContext(r.Context())).
		Str("original_path", r.URL.Path).
		Str("rewritten_path", proxyReq.URL.Path).
		Msg("proxying request")

	proxy.ServeHTTP(w, proxyReq)
}

func (h *ProxyHandler) resolveProxy(upstream string) *httputil.ReverseProxy {
	switch upstream {
	case "auth":
		return h.authProxy
	case "user":
		return h.userProxy
	case "guide":
		return h.guideProxy
	case "file-manager":
		return h.fileManagerProxy
	case "activity":
		return h.activityProxy
	case "excursion":
		return h.excursionProxy
	case "feed":
		return h.feedProxy
	case "chat":
		return h.chatProxy
	case "reference":
		return h.referenceProxy
	case "checklist":
		return h.checklistProxy
	case "currency":
		return h.currencyProxy
	case "place":
		return h.placeProxy
	case "routing":
		return h.routingProxy
	case "user-route":
		return h.userRouteProxy
	case "payment":
		return h.paymentProxy
	case "sticker":
		return h.stickerProxy
	case "notification":
		return h.notificationProxy
	case "support":
		return h.supportProxy
	case "admin-panel":
		return h.adminPanelProxy
	default:
		return nil
	}
}

func (h *ProxyHandler) injectTrustedHeaders(r *http.Request, authMode RouteAuthMode) error {
	r.Header.Del(h.cfg.Security.TrustedHeaderUser)
	r.Header.Del(h.cfg.Security.TrustedHeaderRoles)
	r.Header.Del(h.cfg.Security.TrustedHeaderSub)
	r.Header.Del(h.cfg.Security.RequestIDHeader)

	claims := ClaimsFromContext(r.Context())

	if claims == nil {
		return nil
	}

	subject := strings.TrimSpace(claims.Subject)
	if subject != "" {
		r.Header.Set(h.cfg.Security.TrustedHeaderSub, subject)
	}

	roles := adapter.NormalizeRoles(claims.Roles, "")

	userID := strings.TrimSpace(claims.UserID)
	needsResolve := subject != "" && (userID == "" || userID == subject)
	if needsResolve && h.userIDResolver != nil {
		resolvedUserID, err := h.userIDResolver.ResolveUserID(
			r.Context(),
			subject,
			roles,
			RequestIDFromContext(r.Context()),
		)
		if err != nil {
			if authMode != RouteAuthPublic {
				return fmt.Errorf("resolve user id by subject: %w", err)
			}
			log.Warn().
				Err(err).
				Str("subject", subject).
				Str("request_id", RequestIDFromContext(r.Context())).
				Msg("failed to resolve optional user id for public route")
			userID = ""
		} else {
			userID = resolvedUserID
		}
	}
	if userID == "" && h.userIDResolver == nil {
		userID = strings.TrimSpace(claims.Subject)
	}
	if userID != "" {
		r.Header.Set(h.cfg.Security.TrustedHeaderUser, userID)
	}

	if len(roles) > 0 {
		r.Header.Set(h.cfg.Security.TrustedHeaderRoles, strings.Join(roles, ","))
	} else {
		r.Header.Del(h.cfg.Security.TrustedHeaderRoles)
	}

	if requestID := strings.TrimSpace(RequestIDFromContext(r.Context())); requestID != "" {
		r.Header.Set(h.cfg.Security.RequestIDHeader, requestID)
	}
	return nil
}

func (h *ProxyHandler) rewritePath(r *http.Request, policy *RoutePolicy) {
	if policy == nil || policy.RewritePrefix == "" {
		return
	}

	originalPath := r.URL.Path
	suffix := strings.TrimPrefix(originalPath, policy.Prefix)

	rewrittenPath := strings.TrimRight(policy.RewritePrefix, "/")
	if suffix != "" {
		if !strings.HasPrefix(suffix, "/") {
			suffix = "/" + suffix
		}
		rewrittenPath += suffix
	}
	if rewrittenPath == "" {
		rewrittenPath = "/"
	}

	r.URL.Path = rewrittenPath
	r.URL.RawPath = rewrittenPath
	r.RequestURI = ""
}

func newSingleHostProxy(upstreamName string, rawTarget string, internalServiceToken string) (*httputil.ReverseProxy, error) {
	target, err := url.Parse(strings.TrimSpace(rawTarget))
	if err != nil {
		return nil, err
	}

	proxy := httputil.NewSingleHostReverseProxy(target)
	originalDirector := proxy.Director
	proxy.Director = func(r *http.Request) {
		originalDirector(r)
		r.Header.Del("X-Internal-Service-Token")
		if token := strings.TrimSpace(internalServiceToken); token != "" {
			r.Header.Set("X-Internal-Service-Token", token)
		}
	}
	proxy.ModifyResponse = func(resp *http.Response) error {
		if resp.StatusCode < http.StatusBadRequest {
			return nil
		}

		if resp.StatusCode < http.StatusInternalServerError {
			rewritten, err := rewriteDownstreamErrorResponse(resp, false)
			if err != nil {
				return err
			}
			if rewritten {
				log.Info().
					Str("upstream", upstreamName).
					Int("status", resp.StatusCode).
					Str("request_id", RequestIDFromContext(resp.Request.Context())).
					Msg("localized downstream business error response")
			}
			return nil
		}

		rewritten, err := rewriteDownstreamErrorResponse(resp, true)
		if err != nil {
			return err
		}
		if rewritten {
			log.Info().
				Str("upstream", upstreamName).
				Int("status", resp.StatusCode).
				Str("request_id", RequestIDFromContext(resp.Request.Context())).
				Msg("preserving localized downstream maintenance response")
			return nil
		}

		log.Warn().
			Str("upstream", upstreamName).
			Int("status", resp.StatusCode).
			Str("request_id", RequestIDFromContext(resp.Request.Context())).
			Msg("masking downstream technical error response")

		payload, err := json.Marshal(buildErrorResponse(resp.Request, errorCodeUpstreamUnavailable, errorKindTechnical))
		if err != nil {
			return err
		}
		payload = append(payload, '\n')

		replaceResponseBody(resp, payload)
		return nil
	}
	proxy.ErrorHandler = func(w http.ResponseWriter, r *http.Request, err error) {
		log.Error().
			Err(err).
			Str("upstream", upstreamName).
			Str("request_id", RequestIDFromContext(r.Context())).
			Msg("downstream proxy error")

		writeTechnicalError(w, r, http.StatusBadGateway, errorCodeUpstreamUnavailable)
	}

	return proxy, nil
}

func rewriteDownstreamErrorResponse(resp *http.Response, maintenanceOnly bool) (bool, error) {
	payload, ok, err := downstreamJSONPayload(resp)
	if err != nil || !ok {
		return false, err
	}

	if maintenanceOnly && !canExposeDownstreamServerError(payload) {
		return false, nil
	}

	rewritten, ok := buildDownstreamErrorResponse(resp.Request, resp.StatusCode, payload)
	if !ok {
		return false, nil
	}

	body, err := json.Marshal(rewritten)
	if err != nil {
		return false, err
	}
	body = append(body, '\n')
	replaceResponseBody(resp, body)
	return true, nil
}

func canExposeDownstreamServerError(payload map[string]any) bool {
	kind := strings.ToLower(strings.TrimSpace(stringPayloadField(payload, "kind")))
	code := stringPayloadField(payload, "code")
	if kind == errorKindMaintenance || strings.HasSuffix(strings.ToLower(strings.TrimSpace(code)), ".technical_maintenance") {
		return true
	}
	if kind != errorKindBusiness {
		return false
	}

	if _, ok := canonicalDownstreamError(code); ok {
		return true
	}
	if _, ok := canonicalDownstreamError(stringPayloadField(payload, "error")); ok {
		return true
	}
	if _, ok := canonicalDownstreamError(stringPayloadField(payload, "message")); ok {
		return true
	}
	return false
}

func downstreamJSONPayload(resp *http.Response) (map[string]any, bool, error) {
	if resp == nil || resp.Body == nil {
		return nil, false, nil
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, false, err
	}
	_ = resp.Body.Close()
	resp.Body = io.NopCloser(bytes.NewReader(body))
	resp.ContentLength = int64(len(body))

	if len(bytes.TrimSpace(body)) == 0 {
		return nil, false, nil
	}

	var payload map[string]any
	if err := json.Unmarshal(body, &payload); err != nil {
		return nil, false, nil
	}
	return payload, true, nil
}

func replaceResponseBody(resp *http.Response, payload []byte) {
	if resp.Body != nil {
		_ = resp.Body.Close()
	}
	resp.Body = io.NopCloser(bytes.NewReader(payload))
	resp.ContentLength = int64(len(payload))
	resp.Header.Set("Content-Type", "application/json")
	resp.Header.Set("Content-Length", strconv.Itoa(len(payload)))
}
