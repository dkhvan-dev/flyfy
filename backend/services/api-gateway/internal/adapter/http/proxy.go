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
	storiesProxy      *httputil.ReverseProxy
	chatProxy         *httputil.ReverseProxy
	referenceProxy    *httputil.ReverseProxy
	attractionProxy   *httputil.ReverseProxy
	paymentProxy      *httputil.ReverseProxy
	stickerProxy      *httputil.ReverseProxy
	notificationProxy *httputil.ReverseProxy
	adminPanelProxy   *httputil.ReverseProxy
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

	storiesProxy, err := newSingleHostProxy("stories", cfg.Downstreams.StoriesService, cfg.Security.InternalServiceToken)
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

	attractionProxy, err := newSingleHostProxy("attraction", cfg.Downstreams.AttractionService, cfg.Security.InternalServiceToken)
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

	adminPanelProxy, err := newSingleHostProxy("admin-panel", cfg.Downstreams.AdminPanelService, cfg.Security.InternalServiceToken)
	if err != nil {
		return nil, err
	}

	userIDResolver, err := newUserServiceUserIDResolver(cfg)
	if err != nil {
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
		storiesProxy:      storiesProxy,
		chatProxy:         chatProxy,
		referenceProxy:    referenceProxy,
		attractionProxy:   attractionProxy,
		paymentProxy:      paymentProxy,
		stickerProxy:      stickerProxy,
		notificationProxy: notificationProxy,
		adminPanelProxy:   adminPanelProxy,
		userIDResolver:    userIDResolver,
	}, nil
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
		policy = matchRoutePolicy(r.URL.Path, h.cfg.Routes.APIPrefix)
	}
	if policy == nil {
		writeBusinessError(w, r, http.StatusNotFound, errorCodeRouteNotFound)
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
	case "stories":
		return h.storiesProxy
	case "chat":
		return h.chatProxy
	case "reference":
		return h.referenceProxy
	case "attraction":
		return h.attractionProxy
	case "payment":
		return h.paymentProxy
	case "sticker":
		return h.stickerProxy
	case "notification":
		return h.notificationProxy
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
		if resp.StatusCode < http.StatusInternalServerError {
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

		if resp.Body != nil {
			_ = resp.Body.Close()
		}
		resp.Body = io.NopCloser(bytes.NewReader(payload))
		resp.ContentLength = int64(len(payload))
		resp.Header.Set("Content-Type", "application/json")
		resp.Header.Set("Content-Length", strconv.Itoa(len(payload)))
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
