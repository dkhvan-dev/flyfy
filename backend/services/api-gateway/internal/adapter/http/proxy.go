package http

import (
	"net/http"
	"net/http/httputil"
	"net/url"
	"strings"

	"github.com/rs/zerolog/log"

	"github.com/dkhvan-dev/flyfy/backend/services/api-gateway/internal/adapter"
	"github.com/dkhvan-dev/flyfy/backend/services/api-gateway/internal/config"
)

type ProxyHandler struct {
	cfg              *config.Config
	readiness        *ReadinessHandler
	authProxy        *httputil.ReverseProxy
	userProxy        *httputil.ReverseProxy
	guideProxy       *httputil.ReverseProxy
	fileManagerProxy *httputil.ReverseProxy
	activityProxy    *httputil.ReverseProxy
	tourProxy        *httputil.ReverseProxy
	storiesProxy     *httputil.ReverseProxy
	chatProxy        *httputil.ReverseProxy
	referenceProxy   *httputil.ReverseProxy
	attractionProxy  *httputil.ReverseProxy
	paymentProxy     *httputil.ReverseProxy
	stickerProxy     *httputil.ReverseProxy
}

func NewProxyHandler(cfg *config.Config, readiness *ReadinessHandler) (*ProxyHandler, error) {
	authProxy, err := newSingleHostProxy("auth", cfg.Downstreams.AuthService)
	if err != nil {
		return nil, err
	}

	userProxy, err := newSingleHostProxy("user", cfg.Downstreams.UserService)
	if err != nil {
		return nil, err
	}

	guideProxy, err := newSingleHostProxy("guide", cfg.Downstreams.GuideService)
	if err != nil {
		return nil, err
	}

	fileManagerProxy, err := newSingleHostProxy("file-manager", cfg.Downstreams.FileManagerService)
	if err != nil {
		return nil, err
	}

	activityProxy, err := newSingleHostProxy("activity", cfg.Downstreams.ActivityService)
	if err != nil {
		return nil, err
	}

	tourProxy, err := newSingleHostProxy("tour", cfg.Downstreams.TourService)
	if err != nil {
		return nil, err
	}

	storiesProxy, err := newSingleHostProxy("stories", cfg.Downstreams.StoriesService)
	if err != nil {
		return nil, err
	}

	chatProxy, err := newSingleHostProxy("chat", cfg.Downstreams.ChatService)
	if err != nil {
		return nil, err
	}

	referenceProxy, err := newSingleHostProxy("reference", cfg.Downstreams.ReferenceService)
	if err != nil {
		return nil, err
	}

	attractionProxy, err := newSingleHostProxy("attraction", cfg.Downstreams.AttractionService)
	if err != nil {
		return nil, err
	}

	paymentProxy, err := newSingleHostProxy("payment", cfg.Downstreams.PaymentService)
	if err != nil {
		return nil, err
	}

	stickerProxy, err := newSingleHostProxy("sticker", cfg.Downstreams.StickerService)
	if err != nil {
		return nil, err
	}

	return &ProxyHandler{
		cfg:              cfg,
		readiness:        readiness,
		authProxy:        authProxy,
		userProxy:        userProxy,
		guideProxy:       guideProxy,
		fileManagerProxy: fileManagerProxy,
		activityProxy:    activityProxy,
		tourProxy:        tourProxy,
		storiesProxy:     storiesProxy,
		chatProxy:        chatProxy,
		referenceProxy:   referenceProxy,
		attractionProxy:  attractionProxy,
		paymentProxy:     paymentProxy,
		stickerProxy:     stickerProxy,
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
		writeError(w, http.StatusNotFound, "route not found")
		return
	}

	proxy := h.resolveProxy(policy.Upstream)
	if proxy == nil {
		writeError(w, http.StatusBadGateway, "upstream is not configured")
		return
	}

	proxyReq := r.Clone(r.Context())
	h.rewritePath(proxyReq, policy)
	h.injectTrustedHeaders(proxyReq)

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
	case "tour":
		return h.tourProxy
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
	default:
		return nil
	}
}

func (h *ProxyHandler) injectTrustedHeaders(r *http.Request) {
	r.Header.Del(h.cfg.Security.TrustedHeaderUser)
	r.Header.Del(h.cfg.Security.TrustedHeaderRoles)
	r.Header.Del(h.cfg.Security.TrustedHeaderSub)
	r.Header.Del(h.cfg.Security.RequestIDHeader)

	claims := ClaimsFromContext(r.Context())

	if claims == nil {
		return
	}

	if subject := strings.TrimSpace(claims.Subject); subject != "" {
		r.Header.Set(h.cfg.Security.TrustedHeaderSub, subject)
	}
	userID := strings.TrimSpace(claims.UserID)
	if userID == "" {
		userID = strings.TrimSpace(claims.Subject)
	}
	if userID != "" {
		r.Header.Set(h.cfg.Security.TrustedHeaderUser, userID)
	}

	roles := adapter.NormalizeRoles(claims.Roles, "")
	if len(roles) > 0 {
		r.Header.Set(h.cfg.Security.TrustedHeaderRoles, strings.Join(roles, ","))
	} else {
		r.Header.Del(h.cfg.Security.TrustedHeaderRoles)
	}

	if requestID := strings.TrimSpace(RequestIDFromContext(r.Context())); requestID != "" {
		r.Header.Set(h.cfg.Security.RequestIDHeader, requestID)
	}
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

func newSingleHostProxy(upstreamName string, rawTarget string) (*httputil.ReverseProxy, error) {
	target, err := url.Parse(strings.TrimSpace(rawTarget))
	if err != nil {
		return nil, err
	}

	proxy := httputil.NewSingleHostReverseProxy(target)
	proxy.ErrorHandler = func(w http.ResponseWriter, r *http.Request, err error) {
		log.Error().
			Err(err).
			Str("upstream", upstreamName).
			Str("request_id", RequestIDFromContext(r.Context())).
			Msg("downstream proxy error")

		writeError(w, http.StatusBadGateway, "downstream service unavailable")
	}

	return proxy, nil
}
