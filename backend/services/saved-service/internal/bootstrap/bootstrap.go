package bootstrap

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"sync"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/connectivity"
	"google.golang.org/grpc/metadata"

	"kz/inflap/backend/pkg/platformpolicy"
	"kz/inflap/backend/pkg/serviceauth"
	"kz/inflap/backend/pkg/transportauth"
	accessadapter "kz/inflap/backend/services/saved-service/internal/adapter/access"
	authadapter "kz/inflap/backend/services/saved-service/internal/adapter/auth"
	policyadapter "kz/inflap/backend/services/saved-service/internal/adapter/policy"
	sessionadapter "kz/inflap/backend/services/saved-service/internal/adapter/session"
	sourceadapter "kz/inflap/backend/services/saved-service/internal/adapter/source"
	"kz/inflap/backend/services/saved-service/internal/app/cursor"
	"kz/inflap/backend/services/saved-service/internal/app/operation"
	"kz/inflap/backend/services/saved-service/internal/app/savedaccess"
	appsource "kz/inflap/backend/services/saved-service/internal/app/source"
	"kz/inflap/backend/services/saved-service/internal/config"
	"kz/inflap/backend/services/saved-service/internal/domain"
)

type serviceTokenSource interface {
	serviceauth.TokenSource
	Close() error
}

type grpcConnection interface {
	grpc.ClientConnInterface
	GetState() connectivity.State
	Connect()
	WaitForStateChange(context.Context, connectivity.State) bool
	Close() error
}

type managedHTTPTransport interface {
	http.RoundTripper
	CloseIdleConnections()
}

type namedGRPCConnection struct {
	name       string
	connection grpcConnection
}

type closeResource struct {
	name  string
	close func() error
}

type Dependencies struct {
	ServiceTokens     serviceauth.TokenSource
	Sources           *sourceadapter.Router
	SessionValidator  *sessionadapter.GRPCClient
	PlatformPolicy    *platformpolicy.Checker
	PolicyGate        *policyadapter.Gate
	OperationHMAC     *operation.HMACKeyRing
	CursorCodec       *cursor.Codec
	GatewayAuthorizer *authadapter.GatewayAuthorizer
	UserAccess        savedaccess.Policy
	Readiness         *Readiness

	closeOnce sync.Once
	closeErr  error
	resources []closeResource
}

type buildHooks struct {
	newTokenSource   func(serviceauth.TokenSourceConfig, ...grpc.DialOption) (serviceTokenSource, error)
	dialGRPC         func(string, ...grpc.DialOption) (grpcConnection, error)
	newHTTPTransport func(transportauth.Config) (managedHTTPTransport, error)
	newVerifier      func(serviceauth.VerifierConfig) (authadapter.BearerVerifier, error)
}

func defaultBuildHooks() buildHooks {
	return buildHooks{
		newTokenSource: func(cfg serviceauth.TokenSourceConfig, options ...grpc.DialOption) (serviceTokenSource, error) {
			return serviceauth.NewGRPCServiceTokenSource(cfg, options...)
		},
		dialGRPC: func(target string, options ...grpc.DialOption) (grpcConnection, error) {
			return grpc.NewClient(target, options...)
		},
		newHTTPTransport: func(cfg transportauth.Config) (managedHTTPTransport, error) {
			return transportauth.NewHTTPTransport(cfg, nil)
		},
		newVerifier: func(cfg serviceauth.VerifierConfig) (authadapter.BearerVerifier, error) {
			return serviceauth.NewJWTVerifier(cfg)
		},
	}
}

func New(cfg *config.Config, database DatabasePinger) (*Dependencies, error) {
	return newWithHooks(cfg, database, defaultBuildHooks())
}

func newWithHooks(
	cfg *config.Config,
	database DatabasePinger,
	hooks buildHooks,
) (_ *Dependencies, returnedErr error) {
	if cfg == nil || database == nil {
		return nil, errors.New("saved-service bootstrap requires configuration and database")
	}
	if hooks.newTokenSource == nil || hooks.dialGRPC == nil ||
		hooks.newHTTPTransport == nil || hooks.newVerifier == nil {
		return nil, errors.New("saved-service bootstrap hooks are incomplete")
	}
	if err := cfg.Validate(); err != nil {
		return nil, fmt.Errorf("validate saved-service bootstrap configuration: %w", err)
	}

	operationHMAC, err := newOperationHMAC(cfg.Crypto)
	if err != nil {
		return nil, fmt.Errorf("initialize operation HMAC: %w", err)
	}
	cursorCodec, err := newCursorCodec(cfg.Crypto)
	if err != nil {
		return nil, fmt.Errorf("initialize cursor codec: %w", err)
	}

	resources := make([]closeResource, 0, 10)
	defer func() {
		if returnedErr == nil {
			return
		}
		if cleanupErr := closeResources(resources); cleanupErr != nil {
			returnedErr = errors.Join(returnedErr, cleanupErr)
		}
	}()

	tokenTransport := clientTransportConfig(cfg.MTLS, cfg.TokenService.ServerName)
	tokenDialOptions, err := transportauth.GRPCDialOptions(tokenTransport)
	if err != nil {
		return nil, fmt.Errorf("initialize token-service transport: %w", err)
	}
	tokenSource, err := hooks.newTokenSource(serviceauth.TokenSourceConfig{
		Target:        cfg.TokenService.Target,
		ServiceID:     cfg.TokenService.ServiceID,
		ServiceSecret: cfg.TokenService.ServiceSecret.Value(),
		CallTimeout:   cfg.TokenService.CallTimeout,
		RefreshBefore: cfg.TokenService.RefreshBefore,
		TransportAuth: tokenTransport,
	}, tokenDialOptions...)
	if err != nil {
		return nil, fmt.Errorf("initialize service-token source: %w", err)
	}
	if tokenSource == nil {
		return nil, errors.New("initialize service-token source: constructor returned nil")
	}
	resources = append(resources, closeResource{name: "service-token", close: tokenSource.Close})

	openAuthenticatedConnection := func(
		name string,
		target string,
		serverName string,
		timeout time.Duration,
	) (grpcConnection, error) {
		options, optionsErr := transportauth.GRPCDialOptions(clientTransportConfig(cfg.MTLS, serverName))
		if optionsErr != nil {
			return nil, fmt.Errorf("configure %s gRPC transport: %w", name, optionsErr)
		}
		options = append(options, grpc.WithChainUnaryInterceptor(
			boundedUnaryClientInterceptor(timeout),
			serviceauth.UnaryClientInterceptor(tokenSource),
		))
		connection, dialErr := hooks.dialGRPC(target, options...)
		if dialErr != nil {
			return nil, fmt.Errorf("create %s gRPC client: %w", name, dialErr)
		}
		if connection == nil {
			return nil, fmt.Errorf("create %s gRPC client: constructor returned nil", name)
		}
		resources = append(resources, closeResource{name: name, close: connection.Close})
		return connection, nil
	}
	openInternalConnection := func(
		name string,
		target string,
		serverName string,
		timeout time.Duration,
	) (grpcConnection, error) {
		options, optionsErr := transportauth.GRPCDialOptions(clientTransportConfig(cfg.MTLS, serverName))
		if optionsErr != nil {
			return nil, fmt.Errorf("configure %s gRPC transport: %w", name, optionsErr)
		}
		options = append(options, grpc.WithChainUnaryInterceptor(
			boundedUnaryClientInterceptor(timeout),
			internalTokenUnaryClientInterceptor(
				cfg.InternalAuth.ServiceToken.Value(),
				cfg.TokenService.ServiceID,
			),
		))
		connection, dialErr := hooks.dialGRPC(target, options...)
		if dialErr != nil {
			return nil, fmt.Errorf("create %s gRPC client: %w", name, dialErr)
		}
		if connection == nil {
			return nil, fmt.Errorf("create %s gRPC client: constructor returned nil", name)
		}
		resources = append(resources, closeResource{name: name, close: connection.Close})
		return connection, nil
	}

	sessionConnection, err := openAuthenticatedConnection(
		"token-session",
		cfg.TokenService.Target,
		cfg.TokenService.ServerName,
		cfg.Dependencies.SessionRPC,
	)
	if err != nil {
		return nil, err
	}
	attractionConnection, err := openAuthenticatedConnection(
		"attraction-source",
		cfg.Sources.AttractionTarget,
		cfg.Sources.AttractionServerName,
		cfg.Dependencies.SourceRPC,
	)
	if err != nil {
		return nil, err
	}
	activityConnection, err := openAuthenticatedConnection(
		"activity-source",
		cfg.Sources.ActivityTarget,
		cfg.Sources.ActivityServerName,
		cfg.Dependencies.SourceRPC,
	)
	if err != nil {
		return nil, err
	}
	userConnection, err := openInternalConnection(
		"user-source",
		cfg.Sources.UserTarget,
		cfg.Sources.UserServerName,
		cfg.Dependencies.SourceRPC,
	)
	if err != nil {
		return nil, err
	}
	postConnection, err := openAuthenticatedConnection(
		"post-source",
		cfg.Sources.PostTarget,
		cfg.Sources.PostServerName,
		cfg.Dependencies.SourceRPC,
	)
	if err != nil {
		return nil, err
	}

	attractionResolver, err := sourceadapter.NewAttractionResolver(attractionConnection)
	if err != nil {
		return nil, fmt.Errorf("initialize Attraction source resolver: %w", err)
	}
	activityResolver, err := sourceadapter.NewActivityResolver(activityConnection)
	if err != nil {
		return nil, fmt.Errorf("initialize Activity source resolver: %w", err)
	}
	userResolver, err := sourceadapter.NewUserResolver(userConnection)
	if err != nil {
		return nil, fmt.Errorf("initialize User source resolver: %w", err)
	}
	postResolver, err := sourceadapter.NewPostResolver(postConnection)
	if err != nil {
		return nil, fmt.Errorf("initialize Post source resolver: %w", err)
	}
	sourceRouter, err := sourceadapter.NewRouter(map[domain.EntityType]appsource.Resolver{
		domain.EntityTypeAttraction: attractionResolver,
		domain.EntityTypeActivity:   activityResolver,
		domain.EntityTypeUser:       userResolver,
		domain.EntityTypePost:       postResolver,
	})
	if err != nil {
		return nil, fmt.Errorf("initialize source router: %w", err)
	}
	sessionValidator := sessionadapter.NewGRPCClientFromConn(sessionConnection)

	jwksTransport, err := hooks.newHTTPTransport(clientTransportConfig(
		cfg.MTLS,
		mustURLHostname(cfg.GatewayAuth.JWKSURL),
	))
	if err != nil {
		return nil, fmt.Errorf("initialize Gateway JWKS transport: %w", err)
	}
	if jwksTransport == nil {
		return nil, errors.New("initialize Gateway JWKS transport: constructor returned nil")
	}
	resources = append(resources, closeResource{
		name: "gateway-jwks-http",
		close: func() error {
			jwksTransport.CloseIdleConnections()
			return nil
		},
	})
	jwksClient := &http.Client{
		Transport: jwksTransport,
		Timeout:   cfg.GatewayAuth.HTTPTimeout,
		CheckRedirect: func(*http.Request, []*http.Request) error {
			return http.ErrUseLastResponse
		},
	}
	verifier, err := hooks.newVerifier(serviceauth.VerifierConfig{
		Issuer:   cfg.GatewayAuth.Issuer,
		JWKSURL:  cfg.GatewayAuth.JWKSURL,
		CacheTTL: cfg.GatewayAuth.JWKSCacheTTL,
		Client:   jwksClient,
	})
	if err != nil {
		return nil, fmt.Errorf("initialize Gateway JWT verifier: %w", err)
	}
	gatewayAuthorizer, err := authadapter.NewGatewayAuthorizer(
		verifier,
		cfg.GatewayAuth.ExpectedSubject,
		cfg.GatewayAuth.RequiredRole,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize Gateway authorizer: %w", err)
	}

	userAccessTransport, err := hooks.newHTTPTransport(clientTransportConfig(
		cfg.MTLS,
		mustURLHostname(cfg.UserAccess.BaseURL),
	))
	if err != nil {
		return nil, fmt.Errorf("initialize user access transport: %w", err)
	}
	if userAccessTransport == nil {
		return nil, errors.New("initialize user access transport: constructor returned nil")
	}
	resources = append(resources, closeResource{
		name: "user-access-http",
		close: func() error {
			userAccessTransport.CloseIdleConnections()
			return nil
		},
	})
	userAccessClient, err := accessadapter.NewClient(accessadapter.ClientConfig{
		BaseURL:       cfg.UserAccess.BaseURL,
		InternalToken: cfg.InternalAuth.ServiceToken.Value(),
		HTTPClient: &http.Client{
			Transport: userAccessTransport,
			Timeout:   cfg.UserAccess.HTTPTimeout,
			CheckRedirect: func(*http.Request, []*http.Request) error {
				return http.ErrUseLastResponse
			},
		},
		MaxResponseBytes: cfg.UserAccess.MaxResponseBytes,
	})
	if err != nil {
		return nil, fmt.Errorf("initialize user access client: %w", err)
	}

	policyTokenProvider, err := policyadapter.NewInternalTokenHeaderProvider(
		cfg.PlatformPolicy.InternalServiceToken.Value(),
	)
	if err != nil {
		return nil, fmt.Errorf("initialize platform policy authentication: %w", err)
	}
	policyTransport, err := hooks.newHTTPTransport(clientTransportConfig(
		cfg.MTLS,
		mustURLHostname(cfg.PlatformPolicy.BaseURL),
	))
	if err != nil {
		return nil, fmt.Errorf("initialize platform policy transport: %w", err)
	}
	if policyTransport == nil {
		return nil, errors.New("initialize platform policy transport: constructor returned nil")
	}
	resources = append(resources, closeResource{
		name: "platform-policy-http",
		close: func() error {
			policyTransport.CloseIdleConnections()
			return nil
		},
	})
	policySource, err := platformpolicy.NewHTTPClient(platformpolicy.HTTPClientConfig{
		BaseURL:             cfg.PlatformPolicy.BaseURL,
		Timeout:             cfg.PlatformPolicy.HTTPTimeout,
		MaxResponseBytes:    cfg.PlatformPolicy.MaxResponseBytes,
		AllowInsecureHTTP:   cfg.PlatformPolicy.AllowInsecureHTTP,
		Transport:           policyTransport,
		TokenHeaderProvider: policyTokenProvider,
	})
	if err != nil {
		return nil, fmt.Errorf("initialize platform policy source: %w", err)
	}
	policyChecker, err := platformpolicy.NewChecker(platformpolicy.CheckerConfig{
		Source:         policySource,
		RefreshTimeout: cfg.PlatformPolicy.RefreshTimeout,
	})
	if err != nil {
		return nil, fmt.Errorf("initialize platform policy checker: %w", err)
	}
	policyGate, err := policyadapter.NewGate(policyChecker)
	if err != nil {
		return nil, fmt.Errorf("initialize Saved policy gate: %w", err)
	}

	connections := []namedGRPCConnection{
		{name: "token-session", connection: sessionConnection},
		{name: "attraction-source", connection: attractionConnection},
		{name: "activity-source", connection: activityConnection},
		{name: "user-source", connection: userConnection},
		{name: "post-source", connection: postConnection},
	}
	readiness, err := newReadiness(
		database,
		policyChecker,
		tokenSource,
		cfg.Dependencies.GRPCConnect,
		connections,
	)
	if err != nil {
		return nil, fmt.Errorf("initialize dependency readiness: %w", err)
	}

	return &Dependencies{
		ServiceTokens:     tokenSource,
		Sources:           sourceRouter,
		SessionValidator:  sessionValidator,
		PlatformPolicy:    policyChecker,
		PolicyGate:        policyGate,
		OperationHMAC:     operationHMAC,
		CursorCodec:       cursorCodec,
		GatewayAuthorizer: gatewayAuthorizer,
		UserAccess:        userAccessClient,
		Readiness:         readiness,
		resources:         resources,
	}, nil
}

func (dependencies *Dependencies) Close() error {
	if dependencies == nil {
		return nil
	}
	dependencies.closeOnce.Do(func() {
		dependencies.closeErr = closeResources(dependencies.resources)
		dependencies.resources = nil
	})
	return dependencies.closeErr
}

func (*Dependencies) String() string {
	return "Dependencies{credentials=redacted}"
}

func (dependencies *Dependencies) GoString() string {
	return dependencies.String()
}

func closeResources(resources []closeResource) error {
	var closeErrors []error
	for index := len(resources) - 1; index >= 0; index-- {
		resource := resources[index]
		if resource.close == nil {
			continue
		}
		if err := resource.close(); err != nil {
			closeErrors = append(closeErrors, fmt.Errorf("close %s dependency: %w", resource.name, err))
		}
	}
	return errors.Join(closeErrors...)
}

func clientTransportConfig(env transportauth.EnvConfig, serverName string) transportauth.Config {
	transport := env.ServerConfig()
	transport.ServerName = serverName
	return transport
}

func mustURLHostname(rawURL string) string {
	parsed, err := url.Parse(rawURL)
	if err != nil {
		return ""
	}
	return parsed.Hostname()
}

func newOperationHMAC(cfg config.CryptoConfig) (*operation.HMACKeyRing, error) {
	current := cfg.OperationCurrentKey()
	currentSecret := current.Secret.Bytes()
	defer clear(currentSecret)
	previousConfig := cfg.OperationPreviousKeys()
	previous := make([]operation.HMACKeyConfig, 0, len(previousConfig))
	for _, key := range previousConfig {
		secret := key.Secret.Bytes()
		previous = append(previous, operation.HMACKeyConfig{Version: key.Version, Secret: secret})
		defer clear(secret)
	}
	return operation.NewHMACKeyRing(
		operation.HMACKeyConfig{Version: current.Version, Secret: currentSecret},
		previous...,
	)
}

func newCursorCodec(cfg config.CryptoConfig) (*cursor.Codec, error) {
	current := cfg.CursorCurrentKey()
	currentSecret := current.Secret.Bytes()
	defer clear(currentSecret)
	keys := []cursor.Key{{ID: current.Version, Secret: currentSecret}}
	for _, key := range cfg.CursorDecryptKeys() {
		secret := key.Secret.Bytes()
		keys = append(keys, cursor.Key{ID: key.Version, Secret: secret})
		defer clear(secret)
	}
	return cursor.NewCodec(keys, current.Version, cfg.CursorTTL)
}

func boundedUnaryClientInterceptor(timeout time.Duration) grpc.UnaryClientInterceptor {
	return func(
		ctx context.Context,
		method string,
		request any,
		reply any,
		connection *grpc.ClientConn,
		invoker grpc.UnaryInvoker,
		options ...grpc.CallOption,
	) error {
		if ctx == nil || timeout <= 0 {
			return errors.New("invalid bounded gRPC request context")
		}
		if deadline, exists := ctx.Deadline(); exists && time.Until(deadline) <= timeout {
			return invoker(ctx, method, request, reply, connection, options...)
		}
		callCtx, cancel := context.WithTimeout(ctx, timeout)
		defer cancel()
		return invoker(callCtx, method, request, reply, connection, options...)
	}
}

func internalTokenUnaryClientInterceptor(
	internalToken string,
	callerService string,
) grpc.UnaryClientInterceptor {
	return func(
		ctx context.Context,
		method string,
		request any,
		reply any,
		connection *grpc.ClientConn,
		invoker grpc.UnaryInvoker,
		options ...grpc.CallOption,
	) error {
		if ctx == nil || internalToken == "" || callerService == "" {
			return errors.New("internal gRPC authentication is unavailable")
		}
		callCtx := metadata.AppendToOutgoingContext(
			ctx,
			"x-internal-service-token", internalToken,
			"x-service-name", callerService,
		)
		return invoker(callCtx, method, request, reply, connection, options...)
	}
}
